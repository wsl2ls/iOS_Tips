//
//  SLZombieCatcher.m
//  DarkMode
//
//  Created by wsl on 2020/4/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLZombieCatcher.h"
#include <objc/runtime.h>
#import "SLCrashProtector.h"

@implementation SLZombieCatcher

- (BOOL)respondsToSelector: (SEL)aSelector
{
    return [self.originClass instancesRespondToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)sel
{
    return [self.originClass instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation: (NSInvocation *)invocation
{
    [self _throwMessageSentExceptionWithSelector: invocation.selector];
}


#define SLZombieThrowMesssageSentException() [self _throwMessageSentExceptionWithSelector: _cmd]
- (Class)class
{
    SLZombieThrowMesssageSentException();
    return nil;
}

- (BOOL)isEqual:(id)object
{
    SLZombieThrowMesssageSentException();
    return NO;
}

- (NSUInteger)hash
{
    SLZombieThrowMesssageSentException();
    return 0;
}

- (id)self
{
    SLZombieThrowMesssageSentException();
    return nil;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    SLZombieThrowMesssageSentException();
    return NO;
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    SLZombieThrowMesssageSentException();
    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    SLZombieThrowMesssageSentException();
    return NO;
}

- (BOOL)isProxy
{
    SLZombieThrowMesssageSentException();
    
    return NO;
}

- (id)retain
{
    SLZombieThrowMesssageSentException();
    return nil;
}

- (oneway void)release
{
    SLZombieThrowMesssageSentException();
}

- (id)autorelease
{
    SLZombieThrowMesssageSentException();
    return nil;
}

- (void)dealloc
{
    SLZombieThrowMesssageSentException();
    [super dealloc];
}

- (NSUInteger)retainCount
{
    SLZombieThrowMesssageSentException();
    return 0;
}

- (NSZone *)zone
{
    SLZombieThrowMesssageSentException();
    return nil;
}

- (NSString *)description
{
    SLZombieThrowMesssageSentException();
    return nil;
}


#pragma mark - Private
- (void)_throwMessageSentExceptionWithSelector: (SEL)selector
{
    NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"( 野指针必现定位：-[%@ %@]) was sent to a zombie object at address: %p", NSStringFromClass(self.originClass), NSStringFromSelector(selector), self] userInfo:nil];
   SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeZombie errorDesc:exception.reason exception:exception callStack:[NSThread callStackSymbols]];
      [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
    //是否需要强制抛出异常
//    @throw exception;
}

@end
