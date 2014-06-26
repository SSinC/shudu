//
//  ViewController.m
//  shudu
//
//  Created by Stan on 14-6-25.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#import "ViewController.h"

typedef enum {
    dragUp = 0,
    dragdown
} dragDirection;

typedef enum {
    viewPresentedTypeMiddle = 0,
    viewPresentedTypeup,
    viewPresentedTypeDown
} viewPresentedType;

@interface ViewController ()

@end

@implementation ViewController
{
    UIView *_frontView;
    UIView *_backgroundView;
    UIView *_headerView;
    UIView *_upView;
    
    UIView *_contentView;
    
    float _progress;
    float _initalSelfCenterY;
    float _initalBackgroundCenterY;
    float _initalFrontCenterY;
    
    int _dragDirection;
    int _viewPresentedType;
    
    BOOL _inProgress;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    _contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    _contentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_contentView];
    
    CGRect frontViewRect = CGRectMake(0, 500, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)*2);
    _frontView = [[UIView alloc] initWithFrame:frontViewRect];
    _frontView.backgroundColor = [UIColor whiteColor];
    _frontView.alpha = 0.2;
    _frontView.layer.shadowOpacity = 0.5;
    _frontView.layer.shadowRadius = 10;
    _frontView.layer.shadowColor = [UIColor blackColor].CGColor;
    _frontView.layer.shadowOffset = CGSizeMake(-3, 3);
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 230, 160)];
    text.numberOfLines = 7;
    [text setText:@"sthewrhsytrewtgregsdfggfdgfsdhgr\nwesdfgsdfgsdfgsdfggsfdgergfsgfdgr\negssfgsdfgsdgfsdfgfd\nyhtdshrtejhdfthdrtyjkerdtyjdf\nfhdfthfghddrthdfthfthgfh\nfdhjdfghrthdtfhdfg\ndfgjthsthhdfgh\ndfghdfghdfghsertfrqwaf"];
    [text setTextColor:[UIColor blackColor]];
    text.font = [UIFont boldSystemFontOfSize:13];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    text.textAlignment = NSTextAlignmentLeft;
    [_frontView addSubview:text];
    
    CGRect backgroundViewRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    _backgroundView = [[UIView alloc] initWithFrame:backgroundViewRect];
    _backgroundView.backgroundColor = [UIColor whiteColor];
    _backgroundView.layer.shadowOpacity = 0.5;
    _backgroundView.layer.shadowRadius = 10;
    _backgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    _backgroundView.layer.shadowOffset = CGSizeMake(-3, 3);
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(30, 150, 250, 80)];
    [title setText:@"25%"];
    [title setTextColor:[UIColor blackColor]];
    title.font = [UIFont boldSystemFontOfSize:110];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    title.textAlignment = NSTextAlignmentLeft;
    [_backgroundView addSubview:title];
    
    UILabel *text1 = [[UILabel alloc] initWithFrame:CGRectMake(30, 230, 230, 80)];
    text1.numberOfLines = 3;
    [text1 setText:@"sthewrhsf465thwrhyrthje6ujfdgfsdhgr\nwegsfdyuytdhesrh545gfgergfsgfdgr\negsfd"];
    [text1 setTextColor:[UIColor blackColor]];
    text1.font = [UIFont boldSystemFontOfSize:13];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    text1.textAlignment = NSTextAlignmentLeft;
    [_backgroundView addSubview:text1];
    
    [_contentView addSubview:_backgroundView];
    [_contentView addSubview:_frontView];

    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 60)];
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 90, 30)];
    [header setText:@"2014.6.26"];
    [header setTextColor:[UIColor blackColor]];
    header.font = [UIFont boldSystemFontOfSize:15];
    //    [labelCity setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25]];
    header.textAlignment = NSTextAlignmentLeft;
    [_headerView addSubview:header];
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
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                    initWithTarget:self
                                                    action:@selector(handlePan:)];
    [_contentView addGestureRecognizer:panGestureRecognizer];
    

}


#pragma mark Gesture Control
- (void)handlePan:(UIPanGestureRecognizer *) recognizer
{
    if(_initalSelfCenterY == 0.0){
        _initalSelfCenterY = recognizer.view.center.y;
        _initalBackgroundCenterY = _backgroundView.center.y;
        _initalFrontCenterY = _frontView.center.y;
    }
    
    CGPoint translation = [recognizer translationInView:self.view];
    //we cannot pull the view down at the beginning;
    if((!_inProgress)){
        if( _progress == 0 && translation.y >0) {
            NSLog(@"drag down");
            _dragDirection = dragdown;
            _inProgress = YES;
        }else{
            NSLog(@"drag up");
            _dragDirection = dragUp;
            _inProgress = YES;
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
                
                _frontView.center = CGPointMake(_frontView.center.x ,
                                                _initalFrontCenterY - 400 * _progress);
                _frontView.alpha = 0.2 + _progress ;
                

                _backgroundView.center = CGPointMake(_backgroundView.center.x ,
                                                     _initalBackgroundCenterY - 120 * _progress);
                _backgroundView.alpha = 1.2 - _progress ;
                _headerView.alpha = 1.0 - _progress;
                }
//                NSLog(@"drag up,_progress:%f",_progress);
            }else{
                if(_viewPresentedType == viewPresentedTypeDown){
                    
                    _progress +=  translation.y / 300;
                    
                    _progress = _progress >= 0 ? _progress : 0;
                    
                    _frontView.center = CGPointMake(_frontView.center.x ,
                                                    _initalFrontCenterY + 120 * _progress);
                    
                    _backgroundView.center = CGPointMake(_backgroundView.center.x ,
                                                         _initalBackgroundCenterY + 120 * _progress);
                    
                    _backgroundView.alpha = _backgroundView.alpha + _progress/100 ;
                    _frontView.alpha = 1.0 - _progress/2;

                    _headerView.alpha = 0.0 + _progress/100;
//                    NSLog(@"drag down,_frontView.alpha:%f",_frontView.alpha);
                }else{
                _progress +=  translation.y / 300;
                
                _progress = _progress >= 0 ? _progress : 0;
                
                _frontView.center = CGPointMake(_frontView.center.x ,
                                                _initalFrontCenterY + 120 * _progress);
                
                _backgroundView.center = CGPointMake(_backgroundView.center.x ,
                                                     _initalBackgroundCenterY + 120 * _progress);
                _backgroundView.alpha = 1.2 - _progress ;
                _headerView.alpha = 1.0 - _progress;
            }
                
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:{
            recognizer.view.center = CGPointMake(recognizer.view.center.x ,
                                                 _initalSelfCenterY);
            break;
        }
        case UIGestureRecognizerStateFailed:{
            recognizer.view.center = CGPointMake(recognizer.view.center.x ,
                                                 _initalSelfCenterY);
            break;
        }
        case UIGestureRecognizerStatePossible:{
            
            break;
        }
        case UIGestureRecognizerStateEnded:{
            
            if(_dragDirection == dragUp){
            if (_progress >0.7) {
                 _viewPresentedType = viewPresentedTypeDown;
                [UIView animateWithDuration:0.5
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     _backgroundView.frame = CGRectMake(0, -130, CGRectGetWidth(_backgroundView.frame), CGRectGetHeight(_backgroundView.frame));
                                      _frontView.frame = CGRectMake(0, 110, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
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
                if (_progress >0.9) {
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
            _inProgress = NO;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
