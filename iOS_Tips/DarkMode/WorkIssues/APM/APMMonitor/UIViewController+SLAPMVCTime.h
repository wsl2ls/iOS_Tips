//
//  UIViewController+SLAPMVCTime.h
//  DarkMode
//
//  Created by wsl on 2020/8/4.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///ViewController启动耗时监测
@interface UIViewController (SLAPMVCTime)

///开始监听网络
+ (void)startMonitorVC;
///结束监听网络
+ (void)stopMonitorVC;

@end

NS_ASSUME_NONNULL_END
