//
//  SLAPMManager.m
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMManager.h"
#import "SLTimer.h"

#import "SLAPMCpu.h"
#import "SLAPMMemoryDisk.h"
#import "SLAPMFluency.h"
#import "SLCrashProtector.h"
#import "SLAPMThreadCount.h"
#import "SLAPMURLProtocol.h"

@interface SLAPMManager ()<SLAPMFluencyDelegate, SLCrashHandlerDelegate>
///任务名称
@property (nonatomic, copy) NSString *taskName;

@end

@implementation SLAPMManager

#pragma mark - Override
/// 重写allocWithZone方法，保证alloc或者init创建的实例不会产生新实例，因为该类覆盖了allocWithZone方法，所以只能通过其父类分配内存，即[super allocWithZone]
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self manager];
}
/// 重写copyWithZone方法，保证复制返回的是同一份实例
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [SLAPMManager manager];
}

#pragma mark - Public
+ (instancetype)manager {
    static SLAPMManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:NULL] init];
        manager.type = SLAPMTypeAll;
    });
    return manager;
}
///开始监控
- (void)startMonitoring {
    if (_isMonitoring) return;
    _isMonitoring = YES;
    
    if ((self.type & SLAPMTypeCpu) == SLAPMTypeCpu || (self.type & SLAPMTypeMemory) == SLAPMTypeMemory || self.type == SLAPMTypeAll) {
        _taskName = [SLTimer execTask:self selector:@selector(monitoring) start:0.5 interval:1.0/60 repeats:YES async:YES];
    }
    
    if ((self.type & SLAPMTypeCpu) == SLAPMTypeCrash || self.type == SLAPMTypeAll) {
        [SLCrashHandler defaultCrashHandler].delegate = self;
    }
    
    if ((self.type & SLAPMTypeFluency) == SLAPMTypeFluency || self.type == SLAPMTypeAll) {
        [SLAPMFluency sharedInstance].delegate = self;
        [[SLAPMFluency sharedInstance] startMonitorFluency];
    }
    
    if ((self.type & SLAPMTypeThreadCount) == SLAPMTypeThreadCount || self.type == SLAPMTypeAll) {
        [SLAPMThreadCount startMonitorThreadCount];
    }
    
    if ((self.type & SLAPMTypeNetwork) == SLAPMTypeNetwork || self.type == SLAPMTypeAll) {
        [SLAPMURLProtocol startMonitorNetwork];
    }
    
}
///结束监控
- (void)stopMonitoring {
    if (!_isMonitoring) return;
    _isMonitoring = NO;
    
    [SLTimer cancelTask:_taskName];
    [SLAPMFluency sharedInstance].delegate = nil;
    [[SLAPMFluency sharedInstance] stopMonitorFluency];
    [SLAPMThreadCount stopMonitorThreadCount];
    [SLAPMURLProtocol stopMonitorNetwork];
}

#pragma mark - Monitoring
///监控中
- (void)monitoring {
    
    if ((self.type & SLAPMTypeCpu) == SLAPMTypeCpu || self.type == SLAPMTypeAll) {
        float CPU = [SLAPMCpu getCpuUsage];
        NSLog(@" CPU使用率：%.2f%%",CPU);
    }
    
    if ((self.type & SLAPMTypeMemory) == SLAPMTypeMemory || self.type == SLAPMTypeAll) {
        double useMemory = [SLAPMMemoryDisk getAppUsageMemory];
        double freeMemory = [SLAPMMemoryDisk getFreeMemory];
        double totalMemory = [SLAPMMemoryDisk getTotalMemory];
        NSLog(@" Memory占用：%.1fM  空闲：%.1fM 总共：%.1fM",useMemory, freeMemory, totalMemory);
    }
    
}

#pragma mark - Fluency/卡顿监测
///卡顿监控回调 当callStack不为nil时，表示发生卡顿并捕捉到卡顿时的调用栈
- (void)APMFluency:(SLAPMFluency *)fluency didChangedFps:(float)fps callStackOfStuck:(nullable NSString *)callStack {
    NSLog(@" 卡顿监测  fps：%f \n %@", fps, callStack == nil ? @"流畅":[NSString stringWithFormat:@"卡住了 %@",callStack]);
}

#pragma mark - SLCrashHandlerDelegate
///异常捕获回调 提供给外界实现自定义处理 ，日志上报等
- (void)crashHandlerDidOutputCrashError:(SLCrashError *)crashError {
   NSString *errorInfo = [NSString stringWithFormat:@" 错误描述：%@ \n 调用栈：%@" ,crashError.errorDesc, crashError.callStackSymbol];
   NSLog(@"%@",errorInfo);
}

@end
