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

@implementation NSObject (SLCrashProtector)

+ (void)load {
    
    /// Unrecognized Selector  未识别方法防护
    //实例方法防护
    SL_ExchangeInstanceMethod([NSObject class], @selector(forwardingTargetForSelector:), [NSObject class], @selector(sl_forwardingTargetForSelector:));
    //类方法防护
    SL_ExchangeClassMethod([[NSObject class] class], @selector(forwardingTargetForSelector:), @selector(sl_forwardingTargetForSelector:));
    
}


#pragma mark - Unrecognized Selector

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


@end
