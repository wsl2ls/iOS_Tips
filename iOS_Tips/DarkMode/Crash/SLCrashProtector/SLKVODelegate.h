//
//  SLKVODelegate.h
//  DarkMode
//
//  Created by wsl on 2020/4/16.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 观察者代理  存储管理KVO的信息
@interface SLKVODelegate : NSObject
/**
 将添加kvo时的相关信息加入到关系maps中，对应原有的添加观察者

 @param observer observer观察者
 @param keyPath keyPath
 @param options options
 @param context context
 */
- (BOOL)addInfoToMapWithObserver:(NSObject *)observer
                     forKeyPath:(NSString *)keyPath
                        options:(NSKeyValueObservingOptions)options
                        context:(void *)context ;

/**
从关系maps中移除观察者 对应原有的移除观察者操作

@param observer 实际观察者
@param keyPath keypath
@param context context
@return 是否移除成功
如果重复移除，会返回NO
 */
- (BOOL)removeInfoInMapWithObserver:(NSObject *)observer
                          forKeyPath:(NSString *)keyPath
                             context:(void *)context;

/**
 从关系maps中移除观察者 对应原有的移除观察者操作

 @param observer 实际观察者
 @param keyPath keypath
 @return 是否移除成功
 如果重复移除，会返回NO
 */
- (BOOL)removeInfoInMapWithObserver:(NSObject *)observer
                             forKeyPath:(NSString *)keyPath;

/*
 获取所有被观察的 keyPaths
 */
- (NSArray *)getAllKeyPaths;

@end

NS_ASSUME_NONNULL_END
