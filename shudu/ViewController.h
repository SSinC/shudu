//
//  ViewController.h
//  shudu
//
//  Created by Stan on 14-6-25.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "networkManager.h"

@interface ViewController : UIViewController<networkDelegate,UIWebViewDelegate>

- (void)getNetworkInfo;
@end
