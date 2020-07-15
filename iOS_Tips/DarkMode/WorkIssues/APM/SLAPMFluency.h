//
//  SLAPMFluency.h
//  DarkMode
//
//  Created by wsl on 2020/7/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SLAPMFluency;
@protocol SLAPMFluencyDelegate <NSObject>
///卡顿监控回调 当callStack不为nil时，表示卡顿并捕捉到卡顿时的调用栈
- (void)APMFluency:(SLAPMFluency *)fluency didChangedFps:(float)fps callback:(void(^)(NSString *callStack))callback;
@end

///流畅度监听 是否卡顿
@interface SLAPMFluency : NSObject

@property (nonatomic, weak) id<SLAPMFluencyDelegate> delegate;

+ (instancetype)sharedInstance;
///开始监听
- (void)startMonitoring;
///结束监听
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
