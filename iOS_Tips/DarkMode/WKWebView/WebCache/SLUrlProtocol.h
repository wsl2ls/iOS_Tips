//
//  SLUrlProtocol.h
//  DarkMode
//
//  Created by wsl on 2020/5/30.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*
 NSURLProtocol的简介：https://www.jianshu.com/p/ae5e8f9988d8
 */

///缓存方案1： NSURLProtocol 拦截HTTP/https请求 实现缓存
@interface SLUrlProtocol : NSURLProtocol

@end

NS_ASSUME_NONNULL_END
