//
//  networkManager.m
//  shudu
//
//  Created by Stan on 14-6-30.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#import "networkManager.h"
#import "CheckNetwork.h"
#import "defines.h"

@implementation networkManager
{
    NSUserDefaults *_userDefaults;
    BOOL           _sendWeatherInfoCompleted;
    __weak id      _wself ;
}

+ (instancetype)sharedInstance
{
    static networkManager *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] _init];
    });
    
    return sharedInstance;
}

- (instancetype)_init
{
    if (self = [super init]) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _wself        = self;
    }
    
    return self;
}

- (instancetype)init
{
    [NSException raise:NSStringFromClass([self class]) format:@"Use sharedInstance instead of New And Init."];
    return nil;
}

+ (instancetype)new
{
    [NSException raise:NSStringFromClass([self class]) format:@"Use sharedInstance instead of New And Init."];
    return nil;
}

+ (void)withGroup:(dispatch_group_t)group sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    if (group == NULL) {
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:handler];
    } else {
        dispatch_group_enter(group);
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                   handler(response, data, error);
                                   dispatch_group_leave(group);
                               }];
    }
}

- (BOOL)getNetworkInfo:(NSString *)URLString
{
    if(![CheckNetwork isExistenceNetwork]) return NO;
    
    networkManager *strongSelf = _wself;
    
    //    NSURL *url1 =  [NSURL URLWithString:@"http://www.weather.com.cn/data/cityinfo/101210101.html"];
    NSURL *url1 = [NSURL URLWithString:URLString];
    NSURLRequest *request1 = [[NSURLRequest alloc]initWithURL:url1 cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    //    NSData *received1 = [NSURLConnection sendSynchronousRequest:request1 returningResponse:nil error:nil];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    __block NSDictionary *json;
    
    [NSURLConnection sendAsynchronousRequest:request1 queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError){
        
        if(data){
            json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&connectionError];
        }else{
            json = nil;
        }
        
        if(nil == json){
            NSLog(@"json is nil");
            return ;
        }
        
        // print all the info obtained
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
        NSLog(@"jsonData %@",[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        
        NSArray *array = [json objectForKey:[[json allKeys] objectAtIndex:1]];
        NSDictionary *json1 = [array objectAtIndex:0];
        NSString *title = [json1 objectForKey:@"title"];
//        [title encodeForURLWithEncoding:NSUTF8StringEncoding];
        NSString *url = [json1 objectForKey:@"share_url"];
//        url = [url substringFromIndex:29];
        url = [url stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        
        NSLog(@"url:%@",url);
        NSLog(@"1title:%@",title);
        
        NSDictionary *sendDick;
        NSArray      *sendArray;
        
//        [strongSelf handleData:json1 toDick:sendDick array:sendArray];
        sendDick = @{@"title":title,@"url":url};
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(infoFromNetwork:)]) {
            _sendWeatherInfoCompleted = [strongSelf.delegate infoFromNetwork:sendDick];
        }
        
    }];
    
    if(json){
        return YES;
    }else {
        return NO;
    }
    
}

/*********
 Analysis Data and send data to UI
 *********/
- (void)handleData:(NSDictionary *)data toDick:(NSDictionary *)sendDick array:(NSArray *)sendArray
{
//    NSString *currentTemp = [data objectForKey:@"temp"];
//    [_userDefaults setObject:currentTemp forKey:PSLastCurrentTemp];
    sendArray = @[];
    sendDick  = @{};
    
//    if(currentTemp){
//        NSString *humidity    = [data objectForKey:@"SD"];
//        NSString *cityID      = [data objectForKey:@"cityid"];
//        NSString *windPower   = [data objectForKey:@"WS"];
//        [_userDefaults setObject:humidity forKey:PSLastHumidity];
//        [_userDefaults setObject:windPower forKey:PSLastWindPower];
//        
//        sendArray = @[currentTemp,humidity,windPower,cityID];
//        sendDick  = @{@"currentTemp":currentTemp,@"humidity":humidity,@"windPower":windPower,@"cityID":cityID};
//    }else{
//        NSString *maxTemp     = [data objectForKey:@"temp1"];
//        NSString *minTemp     = [data objectForKey:@"temp2"];
//        NSString *updatedTime = [data objectForKey:@"ptime"];
//        NSString *weather     = [data objectForKey:@"weather"];
//        [_userDefaults setObject:weather forKey:PSLastMainWeather];
//        [_userDefaults setObject:maxTemp forKey:PSLastMaxTemp];
//        [_userDefaults setObject:minTemp forKey:PSLastMinTemp];
//        [_userDefaults setObject:updatedTime forKey:PSLastUpdatedTime];
    
        //        NSNumber *weahterType;
        //        if([weather rangeOfString:@"雪"].length>0){
        //            weahterType = [NSNumber numberWithInteger:Snowy];
        //            [_userDefaults setObject:weahterType forKey:PSLastMainWeatherType];
        //        }else if([weather rangeOfString:@"雨"].length>0){
        //            weahterType = [NSNumber numberWithInteger:Rainy];
        //            [_userDefaults setObject:weahterType forKey:PSLastMainWeatherType];
        //        }else if([weather rangeOfString:@"阴"].length>0 || [weather rangeOfString:@"云"].length>0){
        //            weahterType = [NSNumber numberWithInteger:Cloudy];
        //            [_userDefaults setObject:weahterType forKey:PSLastMainWeatherType];
        //        }else if([weather rangeOfString:@"晴"].length>0){
        //            weahterType = [NSNumber numberWithInteger:Sunny];
        //            [_userDefaults setObject:weahterType forKey:PSLastMainWeatherType];
        //        }
        //        else{
        //            weahterType = [NSNumber numberWithInteger:Foggy];
        //            [_userDefaults setObject:weahterType forKey:PSLastMainWeatherType];
        //        }
        
        
//        sendArray = @[weather,maxTemp,minTemp,updatedTime];
//        sendDick  = @{@"mainWeather":weather,@"maxTemp":maxTemp,@"minTemp":minTemp,@"updatedTime":updatedTime};
//    }
}


@end