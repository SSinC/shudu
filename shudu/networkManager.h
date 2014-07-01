//
//  networkManager.h
//  shudu
//
//  Created by Stan on 14-6-30.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol networkDelegate <NSObject>
@required
- (BOOL)handleInfoFromNetwork:(NSDictionary *)info;
@end


@interface networkManager : NSObject

@property (nonatomic, weak) id <networkDelegate> delegate;

+ (instancetype)sharedInstance;

/****************************
 Location based ,obtain weather info automaticlly.
 ****************************/
- (void)obtainWeaterInfoLocationBased;

- (BOOL)getNetworkInfo:(NSString *)URLString;
@end


