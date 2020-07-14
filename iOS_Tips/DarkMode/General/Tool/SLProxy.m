//
//  SLProxy.m
//  DarkMode
//
//  Created by wsl on 2020/7/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLProxy.h"

@interface SLProxy ()
///转发对象目标
@property (nullable, nonatomic, weak, readonly) id target;
@end
@implementation SLProxy
+ (instancetype)proxyWithTarget:(id)target {
    return [[SLProxy alloc] initWithTarget:target];
}
- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}
//将消息接收对象改为 _target
- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}
//self 对 target 是弱引用，一旦 target 被释放将调用下面两个方法，如果不实现的话会 crash
- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}
- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}
- (NSUInteger)hash {
    return [_target hash];
}
- (Class)superclass {
    return [_target superclass];
}
- (Class)class {
    return [_target class];
}
- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}
- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}
- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}
- (BOOL)isProxy {
    return YES;
}
- (NSString *)description {
    return [_target description];
}
- (NSString *)debugDescription {
    return [_target debugDescription];
}
@end
