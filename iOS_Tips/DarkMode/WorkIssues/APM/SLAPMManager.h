//
//  SLAPMManager.h
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// APM 管理者
@interface SLAPMManager : NSObject
///是否正在监控
@property (nonatomic, assign) BOOL isMonitoring;

+ (instancetype)sharedInstance;

///开始监控
- (void)startMonitoring;
///结束监控
- (void)stopMonitoring;


@end

NS_ASSUME_NONNULL_END
