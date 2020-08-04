//
//  SLAPMURLProtocol.h
//  DarkMode
//
//  Created by wsl on 2020/8/3.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///网络监控   TCP 建立连接时间 、DNS 时间、 SSL时间、首包时间、响应时间 、流量
@interface SLAPMURLProtocol : NSURLProtocol

///开始监听网络
+ (void)startMonitorNetwork;
///结束监听网络
+ (void)stopMonitorNetwork;

@end

NS_ASSUME_NONNULL_END
