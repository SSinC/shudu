//
//  AppDelegate.h
//  shudu
//
//  Created by Stan on 14-6-25.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "WXApi.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,WXApiDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) ViewController *viewController;
@end
