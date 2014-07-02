//
//  ViewController.m
//  shudu
//
//  Created by Stan on 14-6-25.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#import "ViewController.h"
#import "uiElements.h"
#import "FRDLivelyButton.h"
#import "UIImageView+WebCache.h"
#import "defines.h"

typedef enum {
    dragUp = 0,
    dragdown
} dragDirection;

typedef enum {
    viewPresentedTypeMiddle = 0,
    viewPresentedTypeup,
    viewPresentedTypeDown
} viewPresentedType;

@implementation UIView (rn_Screenshot)

- (UIImage *)rn_screenshot {
    UIGraphicsBeginImageContext(self.bounds.size);
    if([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]){
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    }
    else{
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *imageData = UIImageJPEGRepresentation(image, 0.75);
    image = [UIImage imageWithData:imageData];
    return image;
}

@end

#import <Accelerate/Accelerate.h>

@implementation UIImage (rn_Blur)

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        PSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        PSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        PSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end

@interface ViewController ()

@end

@implementation ViewController
{
    UIView *_frontView;
    UIView *_backgroundView;
    UIView *_headerView;
    UIView *_upView;
    UIView *_itemsView;
    
    UIView *_contentView;
    UIImageView *_imageView;
    
    float _progress;
    float _initalSelfCenterY;
    float _initalBackgroundCenterY;
    float _initalFrontCenterY;
    
    int _dragDirection;
    int _viewPresentedType;
    
    BOOL _dragInProgress;
    BOOL _isSingleSelect;
    
    NSMutableArray     *_items;
    NSMutableIndexSet  *_selectedIndices;
    NSArray            *_borderColors;
    NSArray            *_images;
    
    FRDLivelyButton *_button;
    UILabel *_text;
    UILabel *_title;
    UILabel *_text1;
    UILabel *_header;
    float _lastTextAlpha;
    float _lastTitleAlpha;
    float _lastText1Alpha;
    float _lastHeaderAlpha;
    BOOL _itemsShowed;
    
    NSString *_url;
    
    networkManager *_networkInstance;
    NSUserDefaults *_userDefaults;
    
    UIActivityIndicatorView *_webViewActivityIndicatorView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    _contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    _contentView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:_contentView];
    
    CGRect frontViewRect = CGRectMake(0, 500, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)*2);
    _frontView = [[UIView alloc] initWithFrame:frontViewRect];
    _frontView.backgroundColor = [UIColor yellowColor];
    _frontView.alpha = 0.2;
//    _frontView.layer.shadowOpacity = 0.5;
//    _frontView.layer.shadowRadius = 10;
//    _frontView.layer.shadowColor = [UIColor blackColor].CGColor;
//    _frontView.layer.shadowOffset = CGSizeMake(-3, 3);
    _text = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 230, 160)];
    _text.numberOfLines = 7;
    [_text setText:@"Sthew rhsytre wtgregsdfggf dgfsdhgr\nwesd fgsdfgsd fgsdfggsf dgergfsgfdgr\negssfgsdf gsdgfsdfgfd\nyhtdshrt ejhdfthdrtyjk erdtyjdf\nfhdfthfg hddrthd fthfthgfh\nfdhjdfgh rthdtf hdfg\ndfgjt hsthhdfgh\ndf ghdfghdfghs ertfrqwaf"];
    [_text setTextColor:[UIColor blackColor]];
    _text.font = [UIFont boldSystemFontOfSize:13];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    _text.textAlignment = NSTextAlignmentLeft;
    [_frontView addSubview:_text];
    
    CGRect backgroundViewRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    _backgroundView = [[UIView alloc] initWithFrame:backgroundViewRect];
    _backgroundView.backgroundColor = [UIColor grayColor];
//    _backgroundView.layer.shadowOpacity = 0.5;
//    _backgroundView.layer.shadowRadius = 10;
//    _backgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
//    _backgroundView.layer.shadowOffset = CGSizeMake(-3, 3);
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 185, 100, 100)];
    
    _title = [[UILabel alloc] initWithFrame:CGRectMake(35, 150, 240, 120)];
    [_title setText:@"25%"];
    [_title setTextColor:[UIColor blackColor]];
    _title.font = [UIFont boldSystemFontOfSize:110];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    _title.textAlignment = NSTextAlignmentLeft;
    [_backgroundView addSubview:_title];
    
    _text1 = [[UILabel alloc] initWithFrame:CGRectMake(35, 235, 230, 80)];
    _text1.numberOfLines = 3;
    [_text1 setText:@"Sthewrh sf465thwrh yrthje6 ujfdgf sdhgr\nwegsfd yuytdh esrh54 5gfgergfs gfdgr\negsfd"];
    [_text1 setTextColor:[UIColor blackColor]];
    _text1.font = [UIFont boldSystemFontOfSize:13];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    [_backgroundView addSubview:_text1];
    [_backgroundView addSubview:_imageView];
    
    [_contentView addSubview:_backgroundView];
    [_contentView addSubview:_frontView];

    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 60)];
    _header = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 90, 30)];
    [_header setText:@"2014.6.26"];
    [_header setTextColor:[UIColor blackColor]];
    _header.font = [UIFont boldSystemFontOfSize:15];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    _header.textAlignment = NSTextAlignmentLeft;
    [_headerView addSubview:_header];
    [_contentView addSubview:_headerView];

    _upView = [[UIView alloc]initWithFrame:CGRectMake(0, -CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds),CGRectGetHeight(self.view.bounds))];
    UILabel *upTitle = [[UILabel alloc] initWithFrame:CGRectMake(30, 350, 90, 30)];
    [upTitle setText:@"upView"];
    [upTitle setTextColor:[UIColor blackColor]];
    upTitle.font = [UIFont boldSystemFontOfSize:20];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    upTitle.textAlignment = NSTextAlignmentLeft;
    [_upView addSubview:upTitle];
    [_contentView addSubview:_upView];
    
    _selectedIndices = [NSMutableIndexSet indexSet];
    _items = [[NSMutableArray alloc] init];
    _borderColors = @[  [UIColor colorWithWhite:0.7 alpha:1],
                        [UIColor colorWithWhite:0.7 alpha:1],
                        [UIColor colorWithWhite:0.7 alpha:1],
                        [UIColor colorWithWhite:0.7 alpha:1]
                        ];
    _images = @[[UIImage imageNamed:@"icon_plist_webexball"],
                [UIImage imageNamed:@"icon_plist_webexball"],
                [UIImage imageNamed:@"icon_plist_webexball"],
                [UIImage imageNamed:@"icon_plist_webexball"]];
    _itemsView = [[UIView alloc] initWithFrame:CGRectMake(0, 400, 300, 45)];
//    _itemsView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    [_backgroundView addSubview:_itemsView];
    _button = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(20,10, 25, 25)];
    [_button setOptions:@{ kFRDLivelyButtonLineWidth: @(2.0f),
                           kFRDLivelyButtonHighlightedColor: [UIColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:1.0],
                           kFRDLivelyButtonColor: [UIColor blackColor]
                           }];
    [_button setStyle:kFRDLivelyButtonStyleCirclePlus animated:NO];
    [_button addTarget:self action:@selector(showItems:) forControlEvents:UIControlEventTouchUpInside];
    _button.tag = 0;
    [_itemsView addSubview:_button];
    
    [_images enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
        calloutItemView *view = [[calloutItemView alloc] init];
        view.itemIndex = idx;
        view.clipsToBounds = YES;
        view.imageView.image = image;
        
        CGRect frame = CGRectMake(70 + idx * 50, 0 , 45, 45);
        view.frame = frame;
        view.layer.cornerRadius = frame.size.width/2.f;
        view.originalBackgroundColor = [UIColor clearColor];
        view.alpha = 0.0f;
        
        [_itemsView addSubview:view];
        
        [_items addObject:view];
        
        if (_borderColors && _selectedIndices && [_selectedIndices containsIndex:idx]) {
            UIColor *color = _borderColors[idx];
            view.layer.borderColor = color.CGColor;
        }
        else {
            view.layer.borderColor = [UIColor clearColor].CGColor;
        }
    }];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                    initWithTarget:self
                                                    action:@selector(handlePan:)];
    [_contentView addGestureRecognizer:panGestureRecognizer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self
                                                    action:@selector(handleTap:)];
    [_contentView addGestureRecognizer:tapGestureRecognizer];
    
     _userDefaults = [NSUserDefaults standardUserDefaults];
    double delayInSeconds = 1.0;
    __weak id wself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ViewController *strongSelf = wself;
        [strongSelf onApplicationFinishedLaunching];
    });
}

#pragma mark - Lazy Loading
- (void)onApplicationFinishedLaunching
{
    NSLog(@"onApplicationFinishedLaunching");
    /*************************************
     Netwokr weather instance
     *************************************/
    [self getNetworkInfo];
}

#pragma mark - getNetworkInfo
- (void)getNetworkInfo
{
    if(!_networkInstance){
        _networkInstance = [networkManager sharedInstance];
        _networkInstance.delegate = self;
    }
    [_networkInstance getNetworkInfo:@"http://news-at.zhihu.com/api/3/news/latest"];
    ////http://news-at.zhihu.com/api/3/news/hot;
}

- (BOOL)handleInfoFromNetwork:(NSDictionary *)info
{
    if(info[@"imageUrl"]){
        NSLog(@"info[@imageUrl]:%@",info[@"imageUrl"]);
    __block UIActivityIndicatorView *activityIndicator;
    __weak UIImageView *weakImageView = _imageView;
    [_imageView sd_setImageWithURL:[NSURL URLWithString:info[@"imageUrl"]] 
                      placeholderImage:nil
                               options:SDWebImageProgressiveDownload
                              progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                  if (!activityIndicator) {
                                      [weakImageView addSubview:activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
                                      activityIndicator.center = weakImageView.center;
                                      [activityIndicator startAnimating];
                                  }
                              }
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 [activityIndicator removeFromSuperview];
                                 activityIndicator = nil;
                             }];
//        [_imageView sd_setImageWithURL:[NSURL URLWithString:info[@"imageUrl"]]];
    }
    
     dispatch_async(dispatch_get_main_queue(), ^{
         NSString *title = info[@"title"];
         _url            = info[@"url"];
         NSLog(@"WKLastTitle:%@, title:%@",[_userDefaults objectForKey:WKLastTitle],title);
//         NSLog(@"title && ![title isEqualToString:WKLastTitle]:%@",[title isEqualToString:WKLastTitle]?@"YES":@"NO");
//            NSLog(@"url && ![url isEqualToString:WKLastUrl]:%@",[url isEqualToString:WKLastUrl]?@"YES":@"NO");
         
         if(title ){
            _title.frame = CGRectMake(110, 150, 200, 120);
            [_title setText:title];
            _title.font = [UIFont boldSystemFontOfSize:20];
            _title.numberOfLines = 3;
         }
         if(_url ){
            _text1.frame = CGRectMake(115, 215, 180, 100);
            _text1.numberOfLines = 2;
            [_text1 setText:_url];
         }
    });
    
    return YES;
}

#pragma mark - Show and dismiss items
- (void)showItems:(id)sender
{
    if(_itemsShowed){
        [self dismissItems];
    }else{
        _itemsShowed = YES;
        [_button setStyle:kFRDLivelyButtonStyleCircleClose animated:YES];
        [_items enumerateObjectsUsingBlock:^(calloutItemView *view, NSUInteger idx, BOOL *stop) {
    //        view.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
            view.alpha = 0;
            CGFloat y = view.center.y;
    //        view.center =CGPointMake(view.center.x, view.center.y - 30);
            view.originalBackgroundColor = [UIColor clearColor];
            view.layer.borderWidth = 1.5f;
            
            [self showWithView:view idx:idx initDelay:0.1 centerY:y];
        }];
        
        _lastText1Alpha = _text1.alpha;
        _lastTextAlpha = _text.alpha;
        _lastHeaderAlpha = _header.alpha;
        _lastTitleAlpha = _title.alpha;
        [UIView animateWithDuration:0.5 animations:^{
            _text1.alpha  *= 0.2;
            _text.alpha   *= 0.2;
            _title.alpha  *= 0.2;
            _header.alpha *= 0.2;
        }];
    }
}

- (void)dismissItems
{
    _itemsShowed = NO;
    [_button setStyle:kFRDLivelyButtonStyleCirclePlus animated:YES];
    [_items enumerateObjectsUsingBlock:^(calloutItemView *view, NSUInteger idx, BOOL *stop) {
        //        view.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
        CGFloat y = view.center.y;
        //        view.center =CGPointMake(view.center.x, view.center.y - 30);
        view.originalBackgroundColor = [UIColor clearColor];
        view.layer.borderWidth = 1.5f;
        
        [self dismissWithView:view idx:idx initDelay:0.5 centerY:y];
    }];
    
    [UIView animateWithDuration:0.6 animations:^{
        _text1.alpha = _lastText1Alpha;
        _text.alpha  = _lastTextAlpha;
        _title.alpha = _lastTitleAlpha;
        _header.alpha = _lastHeaderAlpha;
    }];

}

#pragma mark - Set how items show and dismiss
- (void)showWithView:(calloutItemView *)view idx:(NSUInteger)idx initDelay:(CGFloat)initDelay centerY:(CGFloat)y{
    [UIView animateWithDuration:0.7
                          delay:(initDelay + idx*0.08f)
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         //                        view.layer.transform = CATransform3DIdentity;
//                         view.center = CGPointMake(view.center.x,y);
//                         view.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1);
                         view.backgroundColor = [UIColor clearColor];
                         view.alpha = 1.0;
                     }
                     completion:nil];
}

- (void)dismissWithView:(calloutItemView *)view idx:(NSUInteger)idx initDelay:(CGFloat)initDelay centerY:(CGFloat)y{
    [UIView animateWithDuration:0.7
                          delay:(initDelay - idx*0.08f)
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         //                        view.layer.transform = CATransform3DIdentity;
                         //                         view.center = CGPointMake(view.center.x,y);
                         //                         view.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1);
                         view.backgroundColor = [UIColor clearColor];
                         view.alpha = 0.0;
                     }
                     completion:nil];
}

#pragma mark Gesture Control - Pan
- (void)handlePan:(UIPanGestureRecognizer *) recognizer
{
    if(_itemsShowed) return;
    if(_initalSelfCenterY == 0.0){
        _initalSelfCenterY = recognizer.view.center.y;
        _initalBackgroundCenterY = _backgroundView.center.y;
        _initalFrontCenterY = _frontView.center.y;
    }
    
    CGPoint translation = [recognizer translationInView:self.view];
    //we cannot pull the view down at the beginning;
    if((!_dragInProgress)){
        if( _progress == 0 && translation.y >0) {
            NSLog(@"drag down");
            _dragDirection = dragdown;
            _dragInProgress = YES;
        }else{
            NSLog(@"drag up");
            _dragDirection = dragUp;
            _dragInProgress = YES;
        }
    }
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:{
            break;
        }
        case UIGestureRecognizerStateChanged:{
            //CGPoint translation = [recognizer translationInView:self.view];
            //    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
            //                                         recognizer.view.center.y + translation.y);
            if(_dragDirection == dragUp){
                if(_viewPresentedType == viewPresentedTypeMiddle){
                _progress +=  -translation.y / 300;
                
                //when pull the view down after pulling up，the progress cannot be < 0
                _progress = _progress >= 0 ? _progress : 0;
                
                _frontView.center = CGPointMake(_frontView.center.x , _initalFrontCenterY - 400 * _progress);
                _frontView.alpha = 0.2 + _progress ;
                
                _backgroundView.center = CGPointMake(_backgroundView.center.x ,_initalBackgroundCenterY - 120 * _progress);
                _backgroundView.alpha = 1.2 - _progress ;
                _headerView.alpha = 1.0 - _progress;
                }
//                NSLog(@"drag up,_progress:%f",_progress);
            }else{
                if(_viewPresentedType == viewPresentedTypeDown){
                    
                    _progress +=  translation.y / 300;
                    _progress = _progress >= 0 ? _progress : 0;
                    
                    _frontView.center = CGPointMake(_frontView.center.x ,_initalFrontCenterY + 240 * _progress);
                    _frontView.alpha = 1.0 - _progress/2;
                    
                    _backgroundView.center = CGPointMake(_backgroundView.center.x ,_initalBackgroundCenterY + 120 * _progress);
                    _backgroundView.alpha = _backgroundView.alpha + _progress/100 ;

                    _headerView.alpha = 0.0 + _progress/1.5;
//                    NSLog(@"drag down,_frontView.alpha:%f",_frontView.alpha);
                }else{
                _progress +=  translation.y / 300;
                _progress = _progress >= 0 ? _progress : 0;
                
                _frontView.center = CGPointMake(_frontView.center.x ,_initalFrontCenterY + 120 * _progress);
                
                _backgroundView.center = CGPointMake(_backgroundView.center.x , _initalBackgroundCenterY + 120 * _progress);
                _backgroundView.alpha = 1.2 - _progress ;
                _headerView.alpha = 1.0 - _progress;
            }
                
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:{
            recognizer.view.center = CGPointMake(recognizer.view.center.x ,_initalSelfCenterY);
            break;
        }
        case UIGestureRecognizerStateFailed:{
            recognizer.view.center = CGPointMake(recognizer.view.center.x ,_initalSelfCenterY);
            break;
        }
        case UIGestureRecognizerStatePossible:{
            break;
        }
        case UIGestureRecognizerStateEnded:{
            if(_dragDirection == dragUp){
            if (_progress >0.6) {
                 _viewPresentedType = viewPresentedTypeDown;
                [UIView animateWithDuration:0.5
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     _backgroundView.frame = CGRectMake(0, -130, CGRectGetWidth(_backgroundView.frame), CGRectGetHeight(_backgroundView.frame));
                                      _frontView.frame = CGRectMake(0, 150, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
                                     _backgroundView.alpha = 0.2;
                                     _headerView.alpha = 0.0;
                                 } completion:^(BOOL finished) {
                                     _initalFrontCenterY = _frontView.center.y;
                                     _initalBackgroundCenterY = _backgroundView.center.y;
                                     NSLog(@"_backgroundView originY:%f",_backgroundView.frame.origin.y);
                                 }];
                
            }else{
                [UIView animateWithDuration:1.2
                                      delay:0.0
                     usingSpringWithDamping:0.5
                      initialSpringVelocity:1.0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     _backgroundView.center = CGPointMake(_backgroundView.center.x, _initalBackgroundCenterY);
                                     _backgroundView.alpha = 1.0;
                                      _frontView.center = CGPointMake(_frontView.center.x, _initalFrontCenterY);
                                     _frontView.alpha = 0.2;
                                     _headerView.alpha = 1.0;
                                 } completion:^(BOOL finished) {
                                     
                                 }];
                }
            }else{
                if (_progress >0.6) {
                    _viewPresentedType = viewPresentedTypeMiddle;
                    [UIView animateWithDuration:0.5
                                          delay:0.0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         _backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
                                         _frontView.frame = CGRectMake(0, 500, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)*2);
                                         _backgroundView.alpha = 1.0;
                                         _headerView.alpha = 1.0;
                                         _frontView.alpha = 0.2;
                                     } completion:^(BOOL finished) {
                                         _initalFrontCenterY = _frontView.center.y;
                                         _initalBackgroundCenterY = _backgroundView.center.y;
                                         NSLog(@"_backgroundView originY:%f",_backgroundView.frame.origin.y);
                                     }];
                    
                }else{
                    [UIView animateWithDuration:1.2
                                          delay:0.0
                         usingSpringWithDamping:0.5
                          initialSpringVelocity:1.0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         _backgroundView.center = CGPointMake(_backgroundView.center.x, _initalBackgroundCenterY);
                                         _backgroundView.alpha = 0.2;
                                         _frontView.center = CGPointMake(_frontView.center.x, _initalFrontCenterY);
                                         _frontView.alpha = 1.0;
                                         _headerView.alpha = 0.0;
                                     } completion:^(BOOL finished) {
                                     }];
                }
            }

            _progress = 0.0;
            _dragInProgress = NO;
            break;
        }
        default:{
            break;
        }
    }
    
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark Gesture Control - Tap
- (void)handleTap:(UIGestureRecognizer *)recognizer
{
    if(!_itemsShowed)
    {
        CGPoint touchPoint = [recognizer locationInView:_contentView];
        
         if (CGRectContainsPoint(_text1.frame, touchPoint)) {
             UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
             webView.delegate = self;
             NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:_url]];
             [self.view addSubview: webView];
             [webView loadRequest:request];
         }
    }else{
        NSInteger tapIndex = [self indexOfTap:[recognizer locationInView:_itemsView]];
        
        if (tapIndex != NSNotFound) {
            [self didTapItemAtIndex:tapIndex];
        }else{
            [self dismissItems];
        }
    }
}

- (NSInteger)indexOfTap:(CGPoint)location
{
    __block NSUInteger index = NSNotFound;
    
    [_items enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if (CGRectContainsPoint(view.frame, location)) {
            index = idx;
            *stop = YES;
        }
    }];
    
    return index;
}

- (void)didTapItemAtIndex:(NSUInteger)index
{
    BOOL didEnable = ! [_selectedIndices containsIndex:index];
    
    if (_borderColors) {
        UIColor *stroke = _borderColors[index];
        UIView *view = _items[index];
        
        if (didEnable) {
            if (_isSingleSelect){
                [_selectedIndices removeAllIndexes];
                [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    UIView *aView = (UIView *)obj;
                    [[aView layer] setBorderColor:[[UIColor clearColor] CGColor]];
                }];
            }
            view.layer.borderColor = stroke.CGColor;
            
            CABasicAnimation *borderAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
            borderAnimation.fromValue = (id)[UIColor clearColor].CGColor;
            borderAnimation.toValue = (id)stroke.CGColor;
            borderAnimation.duration = 0.5f;
            [view.layer addAnimation:borderAnimation forKey:nil];
            
            [_selectedIndices addIndex:index];
        }
        else {
            if (!_isSingleSelect){
                view.layer.borderColor = [UIColor clearColor].CGColor;
                [_selectedIndices removeIndex:index];
            }
        }
        
        CGRect pathFrame = CGRectMake(-CGRectGetMidX(view.bounds), -CGRectGetMidY(view.bounds), view.bounds.size.width, view.bounds.size.height);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:view.layer.cornerRadius];
        
        // accounts for left/right offset and contentOffset of scroll view
        CGPoint shapePosition = [_contentView convertPoint:view.center fromView:_itemsView];
        
        CAShapeLayer *circleShape = [CAShapeLayer layer];
        circleShape.path = path.CGPath;
        circleShape.position = shapePosition;
        circleShape.fillColor = [UIColor clearColor].CGColor;
        circleShape.opacity = 0;
        circleShape.strokeColor = stroke.CGColor;
        circleShape.lineWidth = 1.5;
        
        [self.view.layer addSublayer:circleShape];
        
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.5, 2.5, 1)];
        
        CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        alphaAnimation.fromValue = @1;
        alphaAnimation.toValue = @0;
        
        CAAnimationGroup *animation = [CAAnimationGroup animation];
        animation.animations = @[scaleAnimation, alphaAnimation];
        animation.duration = 0.5f;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [circleShape addAnimation:animation forKey:nil];
    }
    
//    if ([self.delegate respondsToSelector:@selector(sidebar:didTapItemAtIndex:)]) {
//        [self.delegate sidebar:self didTapItemAtIndex:index];
//    }
//    if ([self.delegate respondsToSelector:@selector(sidebar:didEnable:itemAtIndex:)]) {
//        [self.delegate sidebar:self didEnable:didEnable itemAtIndex:index];
//    }
}

#pragma mark  webView delegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    [view setTag:108];
    [view setBackgroundColor:[UIColor clearColor]];
    UIImage *blurImage = [_contentView rn_screenshot];
    blurImage = [blurImage applyBlurWithRadius:5 tintColor:nil saturationDeltaFactor:1.8 maskImage:nil];
    UIImageView *blurView = [[UIImageView alloc] initWithImage:blurImage];
    [view addSubview:blurView];
    view.alpha = 0.0;
    [self.view addSubview:view];
    [UIView animateWithDuration:0.3 animations:^{
        view.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
    
    _webViewActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
    [_webViewActivityIndicatorView setCenter:view.center];
    [_webViewActivityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [view addSubview:_webViewActivityIndicatorView];
    
    [_webViewActivityIndicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_webViewActivityIndicatorView stopAnimating];
    UIView *view = (UIView *)[self.view viewWithTag:108];
    [UIView animateWithDuration:0.7 animations:^{
        view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
    NSLog(@"webViewDidFinishLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_webViewActivityIndicatorView stopAnimating];
    UIView *view = (UIView *)[self.view viewWithTag:108];
    [view removeFromSuperview];
    NSLog(@"webViewdidFailLoadWithError");
}

#pragma mark didReceiveMemoryWarning
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
