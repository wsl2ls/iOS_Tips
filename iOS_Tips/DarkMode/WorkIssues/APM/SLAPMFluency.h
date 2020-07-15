//
//  SLAPMFluency.h
//  DarkMode
//
//  Created by wsl on 2020/7/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SLAPMFps;
@protocol SLAPMFpsDelegate <NSObject>
///FPS值改变回调
- (void)APMFps:(SLAPMFps *)APMFps didChangedFps:(float)fps;
@end

///流畅度监听 是否卡顿
@interface SLAPMFluency : NSObject

@property (nonatomic, weak) id<SLAPMFpsDelegate> delegate;

+ (instancetype)sharedInstance;
///开始监听
- (void)startMonitoring;
///结束监听
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
