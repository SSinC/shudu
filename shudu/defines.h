//
//  defines.h
//  ShuDu
//
//  Created by Stan on 14-6-30.
//  Copyright (c) 2014年 Stan. All rights reserved.
//

#ifndef ShuDu_defines_h
#define ShuDu_defines_h

#define __IPHONE_OS_VERSION_SOFT_MAX_REQUIRED __IPHONE_7_0

//Location Info
#define  WKLastTitle    @"WKLastTitle"
#define  WKLastUrl      @"WKLastUrl"
#define  WKLastImgUrl   @"WKLastImgUrl"

#define ENABLE_LOGGING_DEBUG 1

#if ENABLE_LOGGING_DEBUG
#define PSLog NSLog
#else
#define PSLog(...)
#endif

//#define dispatch_main_sync_safe(block)\
//if ([NSThread isMainThread]) {\
//block();\
//} else {\
//dispatch_sync(dispatch_get_main_queue(), block);\
//}
//
//#define dispatch_main_async_safe(block)\
//if ([NSThread isMainThread]) {\
//block();\
//} else {\
//dispatch_async(dispatch_get_main_queue(), block);\
//}

#endif
