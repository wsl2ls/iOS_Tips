//
//  SLAPMManager.m
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMManager.h"
#import "SLTimer.h"

#import "SLAPMGpu.h"

@interface SLAPMManager ()<NSCopying>
@property (nonatomic, copy) NSString *taskName;
@end

@implementation SLAPMManager

#pragma mark - Override
/// 重写allocWithZone方法，保证alloc或者init创建的实例不会产生新实例，因为该类覆盖了allocWithZone方法，所以只能通过其父类分配内存，即[super allocWithZone]
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [SLAPMManager sharedInstance];
}

#pragma mark - Public
+ (instancetype)sharedInstance {
    static SLAPMManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:NULL] init];
    });
    return manager;
}
///开始监控
- (void)startMonitoring {
    if (_isMonitoring) return;
    _isMonitoring = YES;
    _taskName = [SLTimer execTask:self selector:@selector(monitoring) start:0 interval:1.0/60.0 repeats:YES async:YES];
    
}
///结束监控
- (void)stopMonitoring {
    if (!_isMonitoring) return;
    _isMonitoring = NO;
    [SLTimer cancelTask:_taskName];
}

#pragma mark - Monitoring
///监控中
- (void)monitoring {
    
    [SLAPMGpu getCpuUsage];
    
}

@end
