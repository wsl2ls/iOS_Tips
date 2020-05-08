//
//  SLZombieCatcher.h
//  DarkMode
//
//  Created by wsl on 2020/4/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*
   -fno-objc-arc 记得设置此类编译方式支持MRC
 */
///僵尸对象，处理发向野指针的消息 定位到方法
@interface SLZombieCatcher : NSProxy
///原类
@property (nonatomic, assign) Class originClass;
@end

NS_ASSUME_NONNULL_END
