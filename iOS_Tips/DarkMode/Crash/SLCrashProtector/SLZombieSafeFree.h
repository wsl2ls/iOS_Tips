//
//  SLZombieSafeFree.h
//  DarkMode
//
//  Created by wsl on 2020/4/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 此类依赖于三方 fishhook
 -fno-objc-arc 记得设置此类编译方式支持MRC
 */
/// 捕获C函数的free内存释放方法   该类已弃用，有Hook冲突问题
@interface SLZombieSafeFree : NSObject
//系统内存警告的时候调用这个函数释放一些内存
void free_some_mem(size_t freeNum);
@end

NS_ASSUME_NONNULL_END
