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
///卡顿监控回调 当callStack不为nil时，表示发生卡顿并捕捉到卡顿时的调用栈；type == SLAPMFluencyTypeRunloop时，fps为0
- (void)APMFluency:(SLAPMFluency *)fluency didChangedFps:(float)fps callStackOfStuck:(nullable NSString *)callStack;
@end

/// 卡顿监测策略/类型
typedef NS_ENUM(NSInteger, SLAPMFluencyType) {
    /* 建议 Runloop，不消耗额外的CPU资源，可以获取卡顿时的调用堆栈 */
    SLAPMFluencyTypeRunloop  = 0,
    /*FPS 无法获取卡顿时的调用堆栈，消耗CPU资源，不利于CPU使用率的监控，但可以作为衡量卡顿程度的指数*/
    SLAPMFluencyTypeFps      = 1,
    /*所有策略*/
    SLAPMFluencyTypeAll      = 2
};

///流畅度监听 是否卡顿
@interface SLAPMFluency : NSObject

@property (nonatomic, weak) id<SLAPMFluencyDelegate> delegate;
///卡顿监测策略/类型  默认建议 SLAPMFluencyTypeRunloop
@property (nonatomic, assign) SLAPMFluencyType type;

+ (instancetype)sharedInstance;
///开始监听
- (void)startMonitorFluency;
///结束监听
- (void)stopMonitorFluency;

@end

NS_ASSUME_NONNULL_END
