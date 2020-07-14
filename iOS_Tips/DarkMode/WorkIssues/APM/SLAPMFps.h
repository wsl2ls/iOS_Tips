//
//  SLAPMFps.h
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

@interface SLAPMFps : NSObject

@property (nonatomic, weak) id<SLAPMFpsDelegate> delegate;

+ (instancetype)sharedInstance;
///开始
- (void)play;
///暂停
- (void)paused;
///销毁
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
