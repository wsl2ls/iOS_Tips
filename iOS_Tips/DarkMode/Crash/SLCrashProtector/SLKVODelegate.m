//
//  SLKVODelegate.m
//  DarkMode
//
//  Created by wsl on 2020/4/16.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLKVODelegate.h"
#import "SLCrashProtector.h"

@interface SLKVODelegate ()
{
    // 关系数据表结构：{keypath : [observer1, observer2 , ...](NSHashTable)}
@private
    NSMutableDictionary<NSString *, NSHashTable<NSObject *> *> *_kvoInfoMap;
}
@end

@implementation SLKVODelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _kvoInfoMap = [NSMutableDictionary dictionary];
    }
    return self;
}

// 添加 KVO 信息操作, 添加成功返回 YES
- (BOOL)addInfoToMapWithObserver:(NSObject *)observer
                      forKeyPath:(NSString *)keyPath
                         options:(NSKeyValueObservingOptions)options
                         context:(void *)context {
    @synchronized (self) {
        if (!observer || !keyPath ||
            ([keyPath isKindOfClass:[NSString class]] && keyPath.length <= 0)) {
            return NO;
        }
        NSHashTable<NSObject *> *info = _kvoInfoMap[keyPath];
        if (info.count == 0) {
            //NSHashTable 弱持有observer
            info = [NSHashTable weakObjectsHashTable];
            [info addObject:observer];
            _kvoInfoMap[keyPath] = info;
            return YES;
        }
        //如果已记录的keyPath的观察者不包含observer，就记录
        if (![info containsObject:observer]) {
            [info addObject:observer];
            return YES;
        }
        return NO;
    }
}

// 移除 KVO 信息操作, 成功返回 YES
- (BOOL)removeInfoInMapWithObserver:(NSObject *)observer
                         forKeyPath:(NSString *)keyPath {
    @synchronized (self) {
        if (!observer || !keyPath ||
            ([keyPath isKindOfClass:[NSString class]] && keyPath.length <= 0)) {
            return NO;
        }
        
        NSHashTable<NSObject *> *info = _kvoInfoMap[keyPath];
        if (info.count == 0) {
            //移除失败
            return NO;
        }
        [info removeObject:observer];
        //如果keyPath 的观察者个数为0，就移除这条记录
        if (info.count == 0) {
            [_kvoInfoMap removeObjectForKey:keyPath];
            return YES;
        }
        return NO;
    }
}

// 移除 KVO 信息操作, 成功返回 YES
- (BOOL)removeInfoInMapWithObserver:(NSObject *)observer
                         forKeyPath:(NSString *)keyPath
                            context:(void *)context {
    @synchronized (self) {
        if (!observer || !keyPath ||
            ([keyPath isKindOfClass:[NSString class]] && keyPath.length <= 0)) {
            return NO;
        }
        NSHashTable<NSObject *> *info = _kvoInfoMap[keyPath];
        if (info.count == 0) {
            return NO;
        }
        [info removeObject:observer];
        if (info.count == 0) {
            [_kvoInfoMap removeObjectForKey:keyPath];
            return YES;
        }
        return NO;
    }
}

// 实际观察者 SLKVODelegate 进行监听，并分发
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    NSHashTable<NSObject *> *info = _kvoInfoMap[keyPath];
    for (NSObject *observer in info) {
        @try {
            [observer observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        } @catch (NSException *exception) {
            NSString *reason = [NSString stringWithFormat:@"异常 KVO: %@",[exception description]];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVO errorDesc:reason exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }
}

// 获取所有被观察的 keyPaths
- (NSArray *)getAllKeyPaths {
    NSArray <NSString *>*keyPaths = _kvoInfoMap.allKeys;
    return keyPaths;
}

@end
