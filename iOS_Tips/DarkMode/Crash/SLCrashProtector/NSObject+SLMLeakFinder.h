//
//  NSObject+SLMLeakFinder.h
//  DarkMode
//
//  Created by wsl on 2020/5/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 思路来源： https://github.com/Tencent/MLeaksFinder
@interface NSObject (SLMLeakFinder)
///即将释放时调用此方法
- (BOOL)willDealloc;
//
/////即将释放子对象
//- (void)willReleaseChild:(id)child;
/////即将释放子对象集合
//- (void)willReleaseChildren:(NSArray *)children;
//
/////返回视图堆栈信息
//- (NSArray *)viewStack;
///添加需要监测内存泄漏的白名单类
+ (void)addClassNamesToWhitelist:(NSArray *)classNames;

@end

NS_ASSUME_NONNULL_END
