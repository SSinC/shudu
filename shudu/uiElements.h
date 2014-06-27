//
//  uiElements.h
//  shudu
//
//  Created by Stan on 14-6-27.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface calloutItemView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) NSInteger itemIndex;
@property (nonatomic, strong) UIColor *originalBackgroundColor;

@end