//
//  SLAPMManager.h
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// app性能监控策略/类型
typedef NS_ENUM(NSInteger, SLAPMType) {
    /*无*/
    SLAPMTypeNone    = 0,
    /*CPU占用率*/
    SLAPMTypeCpu     = 1 << 0,
    /*内存使用情况*/
    SLAPMTypeMemory  = 1 << 1,
    /*流畅度、卡顿*/
    SLAPMTypeFluency = 1 << 2,
    /*iOS Crash防护模块*/
    SLAPMTypeCrash   = 1 << 3,
    /*线程数量监控，防止线程爆炸*/
    SLAPMTypeThreadCount   = 1 << 4,
    /*网络监控*/
    SLAPMTypeNetwork   = 1 << 5,
    /*VC启动耗时监测*/
    SLAPMTypeVCTime   = 1 << 6,
    /*所有策略*/
    SLAPMTypeAll     = 1 << 7
};


/// APM 管理者
@interface SLAPMManager : NSObject

///是否正在监控
@property (nonatomic, assign) BOOL isMonitoring;
///app性能监控策略/类型  默认SLAPMTypeAll
@property (nonatomic, assign) SLAPMType type;

+ (instancetype)manager;

///开始监控
- (void)startMonitoring;
///结束监控
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
