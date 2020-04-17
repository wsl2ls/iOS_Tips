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
    /// Unrecognized Selector  未识别方法防护
    [NSObject unrecognizedSelectorCrashProtector];
    /// KVO  防护
    [NSObject KVOCrashProtector];
}

#pragma mark - Unrecognized Selector
/// Unrecognized Selector  未识别方法防护
+ (void)unrecognizedSelectorCrashProtector {
    //实例方法防护
    SL_ExchangeInstanceMethod([NSObject class], @selector(forwardingTargetForSelector:), [NSObject class], @selector(sl_forwardingTargetForSelector:));
    //类方法防护
    SL_ExchangeClassMethod([[NSObject class] class], @selector(forwardingTargetForSelector:), @selector(sl_forwardingTargetForSelector:));
}

/// 将未识别的实例方法重定向转发给SLCrashHandler执行
- (id)sl_forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"异常:未识别方法 [%@ -%@]", NSStringFromClass([self class]) ,NSStringFromSelector(aSelector));
    //判断当前类是否重写了消息转发的相关方法，如果重写了，就走正常的消息转发流程
    if (![self isOverideForwardingMethods:[self class]]) {
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
    NSLog(@"异常:未识别方法 [%@ +%@]", NSStringFromClass([[self class] class]),NSStringFromSelector(aSelector));
    //判断当前类是否重写了消息转发的相关方法，如果重写了，就走正常的消息转发流程
    if (![self isOverideForwardingMethods:[[self class] class]]) {
        //如果SLCrashHandler也没有实现aSelector，就动态添加上aSelector
        if (!class_getInstanceMethod([[SLCrashHandler class] class], aSelector)) {
            class_addMethod([[SLCrashHandler class] class], aSelector, (IMP)SL_DynamicAddMethodIMP, "v@:");
        }
        // 把aSelector转发给SLCrashHandler实例执行
        return [[SLCrashHandler alloc] init];
    }
    return [[self class] sl_forwardingTargetForSelector:aSelector];
}

/*动态添加方法的imp*/
static inline int SL_DynamicAddMethodIMP(id self,SEL _cmd,...){
    return 0;
}
//class类是否重写了消息转发的相关方法
- (BOOL)isOverideForwardingMethods:(Class)class{
    BOOL overide = NO;
    overide = (class_getMethodImplementation([NSObject class], @selector(forwardInvocation:)) != class_getMethodImplementation(class, @selector(forwardInvocation:))) ||
    (class_getMethodImplementation([NSObject class], @selector(forwardingTargetForSelector:)) != class_getMethodImplementation(class, @selector(forwardingTargetForSelector:)));
    return overide;
}

#pragma mark - KVO
/// KVO  防护
+ (void)KVOCrashProtector {
    SL_ExchangeInstanceMethod([NSObject class], @selector(addObserver:forKeyPath:options:context:), [NSObject class], @selector(sl_addObserver:forKeyPath:options:context:));
    SL_ExchangeInstanceMethod([NSObject class], @selector(removeObserver:forKeyPath:), [NSObject class], @selector(sl_removeObserver:forKeyPath:));
    SL_ExchangeInstanceMethod([NSObject class], @selector(removeObserver:forKeyPath:context:), [NSObject class], @selector(sl_removeObserver:forKeyPath:context:));
    SL_ExchangeInstanceMethod([NSObject class], NSSelectorFromString(@"dealloc"), [NSObject class], @selector(sl_KVODealloc));
}

static void *YSCKVOProxyKey = &YSCKVOProxyKey;
static NSString *const KVODefenderValue = @"SL_KVOCrashProtector";
static void *KVODefenderKey = &KVODefenderKey;

// 添加监听者
- (void)sl_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context{
    
    if (!IsSystemClass(self.class)) {
        
        
    }else {
        [self sl_addObserver:observer forKeyPath:keyPath options:options context:context];
    }
    
}
// 移除监听者
- (void)sl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    if (!IsSystemClass(self.class)) {
        if ([self.yscKVOProxy removeInfoInMapWithObserver:observer forKeyPath:keyPath]) {
            // 如果移除 KVO 信息操作成功，则调用系统移除方法
            [self sl_removeObserver:self.yscKVOProxy forKeyPath:keyPath];
        } else {
            // 移除 KVO 信息操作失败：移除了未注册的观察者
            NSString *className = NSStringFromClass(self.class) == nil ? @"" : NSStringFromClass(self.class);
            NSString *reason = [NSString stringWithFormat:@"异常 KVO: Cannot remove an observer %@ for the key path '%@' from %@ , because it is not registered as an observer", observer, keyPath, className];
            NSLog(@"%@",reason);
        }
    } else {
        [self sl_removeObserver:observer forKeyPath:keyPath];
    }
}
// 移除监听者
- (void)sl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context{
    if (!IsSystemClass(self.class)) {
        if ([self.yscKVOProxy removeInfoInMapWithObserver:observer forKeyPath:keyPath  context:context]) {
            // 如果移除 KVO 信息操作成功，则调用系统移除方法
            [self ysc_removeObserver:self.yscKVOProxy forKeyPath:keyPath context:context];
        } else {
            // 移除 KVO 信息操作失败：移除了未注册的观察者
            NSString *className = NSStringFromClass(self.class) == nil ? @"" : NSStringFromClass(self.class);
            NSString *reason = [NSString stringWithFormat:@"异常 KVO: Cannot remove an observer %@ for the key path '%@' from %@ , because it is not registered as an observer", observer, keyPath, className];
            NSLog(@"%@",reason);
        }
    } else {
        [self ysc_removeObserver:observer forKeyPath:keyPath context:context];
    }
}
// 释放
- (void)sl_KVODealloc{
    [self sl_KVODealloc];
}
/*是否是系统类*/
static inline BOOL IsSystemClass(Class cls){
    __block BOOL isSystem = NO;
    NSString *className = NSStringFromClass(cls);
    if ([className hasPrefix:@"NS"]) {
        isSystem = YES;
        return isSystem;
    }
    NSBundle *mainBundle = [NSBundle bundleForClass:cls];
    if (mainBundle == [NSBundle mainBundle]) {
        isSystem = NO;
    }else{
        isSystem = YES;
    }
    return isSystem;
}

// YSCKVOProxy setter 方法
- (void)setYscKVOProxy:(SLKVODelegate *)yscKVOProxy {
    objc_setAssociatedObject(self, YSCKVOProxyKey, yscKVOProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// YSCKVOProxy getter 方法
- (SLKVODelegate *)yscKVOProxy {
    id yscKVOProxy = objc_getAssociatedObject(self, YSCKVOProxyKey);
    if (yscKVOProxy == nil) {
        yscKVOProxy = [[SLKVODelegate alloc] init];
        self.yscKVOProxy = yscKVOProxy;
    }
    return yscKVOProxy;
}

// 自定义 addObserver:forKeyPath:options:context: 实现方法
- (void)ysc_addObserver:(NSObject *)observer
             forKeyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                context:(void *)context {
    
    if (!IsSystemClass(self.class)) {
        objc_setAssociatedObject(self, KVODefenderKey, KVODefenderValue, OBJC_ASSOCIATION_RETAIN);
        if ([self.yscKVOProxy addInfoToMapWithObserver:observer forKeyPath:keyPath options:options context:context]) {
            // 如果添加 KVO 信息操作成功，则调用系统添加方法
            [self ysc_addObserver:self.yscKVOProxy forKeyPath:keyPath options:options context:context];
        } else {
            // 添加 KVO 信息操作失败：重复添加
            NSString *className = (NSStringFromClass(self.class) == nil) ? @"" : NSStringFromClass(self.class);
            NSString *reason = [NSString stringWithFormat:@"KVO Warning : Repeated additions to the observer:%@ for the key path:'%@' from %@",
                                observer, keyPath, className];
            NSLog(@"%@",reason);
        }
    } else {
        [self ysc_addObserver:observer forKeyPath:keyPath options:options context:context];
    }
}

// 移除监听者
- (void)ysc_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    
}
// 自定义 removeObserver:forKeyPath:context: 实现方法
- (void)ysc_removeObserver:(NSObject *)observer
                forKeyPath:(NSString *)keyPath
                   context:(void *)context {
    
}

// 自定义 dealloc 实现方法
- (void)ysc_KVODealloc {
    @autoreleasepool {
        if (!IsSystemClass(self.class)) {
            NSString *value = (NSString *)objc_getAssociatedObject(self, KVODefenderKey);
            if ([value isEqualToString:KVODefenderValue]) {
                NSArray *keyPaths =  [self.yscKVOProxy getAllKeyPaths];
                // 被观察者在 dealloc 时仍然注册着 KVO
                if (keyPaths.count > 0) {
                    NSString *reason = [NSString stringWithFormat:@"KVO Warning : An instance %@ was deallocated while key value observers were still registered with it. The Keypaths is:'%@'", self, [keyPaths componentsJoinedByString:@","]];
                    NSLog(@"%@",reason);
                }
                
                // 移除多余的观察者
                for (NSString *keyPath in keyPaths) {
                    [self ysc_removeObserver:self.yscKVOProxy forKeyPath:keyPath];
                }
            }
        }
    }
    [self ysc_KVODealloc];
}


@end
