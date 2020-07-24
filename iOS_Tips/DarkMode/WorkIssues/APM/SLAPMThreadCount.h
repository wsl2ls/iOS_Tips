//
//  SLAPMThreadCount.h
//  DarkMode
//
//  Created by wsl on 2020/7/23.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///监控线程数量      来源：https://juejin.im/post/5e92a113e51d4547134bdadb
@interface SLAPMThreadCount : NSObject

///开始监听
+ (void)startMonitorThreadCount;
///结束监听
+ (void)stopMonitorThreadCount;

@end

NS_ASSUME_NONNULL_END
