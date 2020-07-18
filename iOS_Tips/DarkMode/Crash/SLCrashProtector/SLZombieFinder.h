//
//  SLZombieFinder.h
//  DarkMode
//
//  Created by wsl on 2020/5/8.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
  -fno-objc-arc 记得设置此类编译方式支持MRC
*/
///zombie/野指针对象嗅探器     目前还不完善，不推荐使用 ，仅做交流学习    来源：https://github.com/sindrilin/LXDZombieSniffer.git
@interface SLZombieFinder : NSObject

///启动zombie嗅探
+ (void)startSniffer;

///关闭zombie嗅探
+ (void)closeSniffer;

 ///添加嗅探白名单类 不嗅探名单之内的类
+ (void)appendIgnoreClass: (Class)cls;

@end

NS_ASSUME_NONNULL_END
