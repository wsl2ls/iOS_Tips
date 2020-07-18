//
//  NSObject+SLCrashProtector.m
//  DarkMode
//
//  Created by wsl on 2020/4/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSObject+SLCrashProtector.h"
#import "SLCrashProtector.h"
#import "SLCrashHandler.h"
#import "SLKVODelegate.h"

@implementation NSObject (SLCrashProtector)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /// Unrecognized Selector  未识别方法防护
        [NSObject unrecognizedSelectorCrashProtector];
        /// KVO  防护
        [NSObject KVOCrashProtector];
        /// KVC  防护
        [NSObject KVCCrashProtector];
    });
}

#pragma mark - Unrecognized Selector
/// Unrecognized Selector  未识别方法防护   不包括系统类
+ (void)unrecognizedSelectorCrashProtector {
    //实例方法防护
    SL_ExchangeInstanceMethod([NSObject class], @selector(forwardingTargetForSelector:), [NSObject class], @selector(sl_forwardingTargetForSelector:));
    //类方法防护
    SL_ExchangeClassMethod([[NSObject class] class], @selector(forwardingTargetForSelector:), @selector(sl_forwardingTargetForSelector:));
}
/// 将未识别的实例方法重定向转发给SLCrashHandler执行
- (id)sl_forwardingTargetForSelector:(SEL)aSelector {
    //判断当前类是否重写了消息转发的相关方法，如果重写了，就走正常的消息转发流程
    if (![self isOverideForwardingMethods:[self class]] && !IsSystemClass(self.class)) {
        SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeUnrecognizedSelector errorDesc:[NSString stringWithFormat:@"异常:未识别方法 [%@ +%@]",NSStringFromClass([self class]),NSStringFromSelector(aSelector)] exception:nil callStack:[NSThread callStackSymbols]];
        [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        //如果SLCrashHandler也没有实现aSelector，就动态添加上aSelector
        if (!class_getInstanceMethod([SLCrashHandler class], aSelector)) {
            class_addMethod([SLCrashHandler class], aSelector, (IMP)SL_DynamicAddMethodIMP, "v@:");
        }
        // 把aSelector转发给SLCrashHandler实例执行
        return [[SLCrashHandler alloc] init];
    }
    return [self sl_forwardingTargetForSelector:aSelector];
}
/// 将未识别的类方法重定向转发给SLCrashHandler执行
+ (id)sl_forwardingTargetForSelector:(SEL)aSelector {
    //判断当前类是否重写了消息转发的相关方法，如果重写了，就走正常的消息转发流程
    if (![self isOverideForwardingMethods:[[self class] class]] && !IsSystemClass(self.class)) {
        SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeUnrecognizedSelector errorDesc:[NSString stringWithFormat:@"异常:未识别方法 [%@ +%@]",NSStringFromClass([self class]),NSStringFromSelector(aSelector)] exception:nil callStack:[NSThread callStackSymbols]];
        [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        //如果SLCrashHandler也没有实现aSelector，就动态添加上aSelector
        if (!class_getInstanceMethod([[SLCrashHandler class] class], aSelector)) {
            class_addMethod([[SLCrashHandler class] class], aSelector, (IMP)SL_DynamicAddMethodIMP, "v@:");
        }
        // 把aSelector转发给SLCrashHandler实例执行
        return [[SLCrashHandler alloc] init];
    }
    return [[self class] sl_forwardingTargetForSelector:aSelector];
}
//class类是否重写了消息转发的相关方法
- (BOOL)isOverideForwardingMethods:(Class)class{
    BOOL overide = NO;
    overide = (class_getMethodImplementation([NSObject class], @selector(forwardInvocation:)) != class_getMethodImplementation(class, @selector(forwardInvocation:))) ||
    (class_getMethodImplementation([NSObject class], @selector(forwardingTargetForSelector:)) != class_getMethodImplementation(class, @selector(forwardingTargetForSelector:)));
    return overide;
}
/*动态添加方法的imp*/
static inline int SL_DynamicAddMethodIMP(id self,SEL _cmd,...){
    return 0;
}

#pragma mark - KVO
/// KVO  防护  
+ (void)KVOCrashProtector {
    SL_ExchangeInstanceMethod([NSObject class], @selector(addObserver:forKeyPath:options:context:), [NSObject class], @selector(sl_addObserver:forKeyPath:options:context:));
    SL_ExchangeInstanceMethod([NSObject class], @selector(removeObserver:forKeyPath:), [NSObject class], @selector(sl_removeObserver:forKeyPath:));
    SL_ExchangeInstanceMethod([NSObject class], @selector(removeObserver:forKeyPath:context:), [NSObject class], @selector(sl_removeObserver:forKeyPath:context:));
    SL_ExchangeInstanceMethod([NSObject class], NSSelectorFromString(@"dealloc"), [NSObject class], @selector(sl_KVODealloc));
}

static void *KVODelegateKey = &KVODelegateKey;
static NSString *const KVODefenderValue = @"SL_KVOCrashProtector";
static void *KVODefenderKey = &KVODefenderKey;

// KVODelegate setter 方法
- (void)setKVODelegate:(SLKVODelegate *)KVODelegate {
    objc_setAssociatedObject(self, KVODelegateKey, KVODelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
// KVODelegate getter 方法
- (SLKVODelegate *)KVODelegate {
    id KVODelegate = objc_getAssociatedObject(self, KVODelegateKey);
    if (KVODelegate == nil) {
        KVODelegate = [[SLKVODelegate alloc] init];
        self.KVODelegate = KVODelegate;
    }
    return KVODelegate;
}

// 添加监听者
- (void)sl_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context{
    if (!IsSystemClass(self.class)) {
        objc_setAssociatedObject(self, KVODefenderKey, KVODefenderValue, OBJC_ASSOCIATION_RETAIN);
        if ([self.KVODelegate addInfoToMapWithObserver:observer forKeyPath:keyPath options:options context:context]) {
            // 如果添加 KVO 信息操作成功，则调用系统添加方法
            [self sl_addObserver:self.KVODelegate forKeyPath:keyPath options:options context:context];
        } else {
            // 添加 KVO 信息操作失败：重复添加
            NSString *className = (NSStringFromClass(self.class) == nil) ? @"" : NSStringFromClass(self.class);
            NSString *errorReason = [NSString stringWithFormat:@"异常 KVO: Repeated additions to the observer:%@ for the key path:'%@' from %@",
                                     observer, keyPath, className];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVO errorDesc:errorReason exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            
        }
    } else {
        [self sl_addObserver:observer forKeyPath:keyPath options:options context:context];
    }
}
// 移除监听者
- (void)sl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    if (!IsSystemClass(self.class)) {
        if ([self.KVODelegate removeInfoInMapWithObserver:observer forKeyPath:keyPath]) {
            // 如果移除 KVO 信息操作成功，则调用系统移除方法
            [self sl_removeObserver:self.KVODelegate forKeyPath:keyPath];
        } else {
            // 移除 KVO 信息操作失败：移除了未注册的观察者
            NSString *className = NSStringFromClass(self.class) == nil ? @"" : NSStringFromClass(self.class);
            NSString *errorReason = [NSString stringWithFormat:@"异常 KVO: Cannot remove an observer %@ for the key path '%@' from %@ , because it is not registered as an observer", observer, keyPath, className];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVO errorDesc:errorReason exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    } else {
        [self sl_removeObserver:observer forKeyPath:keyPath];
    }
}
// 移除监听者
- (void)sl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context{
    if (!IsSystemClass(self.class)) {
        if ([self.KVODelegate removeInfoInMapWithObserver:observer forKeyPath:keyPath  context:context]) {
            // 如果移除 KVO 信息操作成功，则调用系统移除方法
            [self sl_removeObserver:self.KVODelegate forKeyPath:keyPath context:context];
        } else {
            // 移除 KVO 信息操作失败：移除了未注册的观察者
            NSString *className = NSStringFromClass(self.class) == nil ? @"" : NSStringFromClass(self.class);
            NSString *errorReason = [NSString stringWithFormat:@"异常 KVO: Cannot remove an observer %@ for the key path '%@' from %@ , because it is not registered as an observer", observer, keyPath, className];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVO errorDesc:errorReason exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    } else {
        [self sl_removeObserver:observer forKeyPath:keyPath context:context];
    }
}
// 释放
- (void)sl_KVODealloc{
    @autoreleasepool {
        //        if (!IsSystemClass(self.class)) {
        NSString *value = (NSString *)objc_getAssociatedObject(self, KVODefenderKey);
        if ([value isEqualToString:KVODefenderValue]) {
            NSArray *keyPaths =  [self.KVODelegate getAllKeyPaths];
            // 被观察者在 dealloc 时仍然注册着 KVO
            if (keyPaths.count > 0) {
                NSString *errorReason = [NSString stringWithFormat:@"异常 KVO: An instance %@ was deallocated while key value observers were still registered with it. The Keypaths is:'%@'", self, [keyPaths componentsJoinedByString:@","]];
                SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVO errorDesc:errorReason exception:nil callStack:[NSThread callStackSymbols]];
                [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            }
            // 移除多余的观察者
            for (NSString *keyPath in keyPaths) {
                [self sl_removeObserver:self.KVODelegate forKeyPath:keyPath];
            }
        }
    }
    //        }
    [self sl_KVODealloc];
}

#pragma mark - KVC
/// KVC  防护
+ (void)KVCCrashProtector {
    SL_ExchangeInstanceMethod([NSObject class], @selector(setValue:forKey:), [NSObject class], @selector(sl_setValue:forKey:));
}
- (void)sl_setValue:(id)value forKey:(NSString *)key {
    if (key == nil) {
        @try {
            [self sl_setValue:value forKey:key];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVC errorDesc:[@"异常 KVC: " stringByAppendingString:exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            
        }
        return;
    }
    [self sl_setValue:value forKey:key];
}
- (void)setNilValueForKey:(NSString *)key {
    NSString *crashMessages = [NSString stringWithFormat:@"异常 KVC: [<%@ %p> setNilValueForKey]: could not set nil as the value for the key %@.",NSStringFromClass([self class]),self,key];
    SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVC errorDesc:crashMessages exception:nil callStack:[NSThread callStackSymbols]];
    [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSString *crashMessages = [NSString stringWithFormat:@"异常 KVC: [<%@ %p> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key: %@,value:%@'",NSStringFromClass([self class]),self,key,value];
    SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVC errorDesc:crashMessages exception:nil callStack:[NSThread callStackSymbols]];
    [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
}
- (nullable id)valueForUndefinedKey:(NSString *)key {
    NSString *crashMessages = [NSString stringWithFormat:@"异常 KVC: [<%@ %p> valueForUndefinedKey:]: this class is not key value coding-compliant for the key: %@",NSStringFromClass([self class]),self,key];
    SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeKVC errorDesc:crashMessages exception:nil callStack:[NSThread callStackSymbols]];
    [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
    return self;
}

@end
