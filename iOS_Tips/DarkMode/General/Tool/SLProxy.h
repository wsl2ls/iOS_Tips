//
//  SLProxy.h
//  DarkMode
//
//  Created by wsl on 2020/7/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///消息转发中介 主要解决NSTimer、CADisplayLink等循环引用问题
@interface SLProxy : NSProxy
///初始化方法
+ (instancetype)proxyWithTarget:(id)target;
@end

NS_ASSUME_NONNULL_END
