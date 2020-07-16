//
//  NSMutableDictionary+SLCrash.m
//  DarkMode
//
//  Created by wsl on 2020/4/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSMutableDictionary+SLCrashProtector.h"
#import "SLCrashProtector.h"

@implementation NSMutableDictionary (SLCrashProtector)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class __NSDictionaryMM = NSClassFromString(@"__NSDictionaryM");
        SL_ExchangeInstanceMethod(__NSDictionaryMM, @selector(setObject:forKey:), __NSDictionaryMM, @selector(sl_setObject:forKey:));
        SL_ExchangeInstanceMethod(__NSDictionaryMM, @selector(removeObjectForKey:), __NSDictionaryMM, @selector(sl_removeObjectForKey:));
        SL_ExchangeInstanceMethod(__NSDictionaryMM, @selector(setObject:forKeyedSubscript:), __NSDictionaryMM, @selector(sl_setObject:forKeyedSubscript:));
    });
}

#pragma mark - MutableDictionary Safe Methods

- (void)sl_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (anObject == nil || aKey == nil) {
        @try {
            [self sl_setObject:anObject forKey:aKey];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMDictionary errorDesc:[@"异常:字典nil值 " stringByAppendingString:exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }else{
        [self sl_setObject:anObject forKey:aKey];
    }
}

- (void)sl_removeObjectForKey:(id<NSCopying>)aKey {
    if (aKey == nil) {
        @try {
            [self sl_removeObjectForKey:aKey];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMDictionary errorDesc:[@"异常:字典nil值 " stringByAppendingString:exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }else{
        [self sl_removeObjectForKey:aKey];
    }
}

- (void)sl_setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key {
    if (anObject == nil || key == nil) {
        @try {
            [self sl_setObject:anObject forKeyedSubscript:key];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMDictionary errorDesc:[@"异常:字典nil值 " stringByAppendingString:exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }else{
        [self sl_setObject:anObject forKeyedSubscript:key];
    }
}

//nil 值
- (id)sl_initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt{
    NSUInteger index = 0;
    id _Nonnull objectsNew[cnt];
    id <NSCopying> _Nonnull keysNew[cnt];
    //'*** -[NSDictionary initWithObjects:forKeys:]: count of objects (1) differs from count of keys (0)'
    for (int i = 0; i<cnt; i++) {
        if (objects[i] && keys[i]) {//可能存在nil的情况
            objectsNew[index] = objects[i];
            keysNew[index] = keys[i];
            index ++;
        }else{
            NSString *errorInfo = [NSString stringWithFormat:@"异常:字典nil值 *** -[__NSPlaceholderDictionary initWithObjects:forKeys:count:]: attempt to insert nil object from objects[%d]",i];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMDictionary errorDesc:errorInfo exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }
    return [self sl_initWithObjects:objectsNew forKeys:keysNew count:index];
}

@end
