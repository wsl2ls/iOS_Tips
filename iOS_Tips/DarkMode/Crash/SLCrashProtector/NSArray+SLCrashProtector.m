//
//  NSArray+SLCrashProtector.m
//  DarkMode
//
//  Created by wsl on 2020/4/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSArray+SLCrashProtector.h"
#import "SLCrashProtector.h"


@implementation NSArray (SLCrashProtector)

+ (void)load {
    // 不可变数组
    // 越界保护
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(objectAtIndex:), NSClassFromString(@"__NSArrayI"), @selector(sl_objectAtIndex:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(objectAtIndexedSubscript:), NSClassFromString(@"__NSArrayI"), @selector(sl_objectAtIndexedSubscript:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSSingleObjectArrayI"), @selector(objectAtIndex:), NSClassFromString(@"__NSSingleObjectArrayI"), @selector(sl_singleObjectAtIndex:));
        // nil值保护
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSPlaceholderArray"), @selector(initWithObjects:count:), NSClassFromString(@"__NSPlaceholderArray"), @selector(sl_initWithObjects:count:));
    });
}

#pragma mark - Array Safe Methods
//[array objectAtIndex:0] 越界
- (id)sl_objectAtIndex:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //可能抛出异常的代码
        @try {
            return [self sl_objectAtIndex:index];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            return self.lastObject;
        }
    }else {
        return [self sl_objectAtIndex:index];
    }
}
// 越界
- (id)sl_singleObjectAtIndex:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //可能抛出异常的代码
        @try {
            return [self sl_singleObjectAtIndex:index];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            return self.lastObject;
        }
    }else {
        return [self sl_singleObjectAtIndex:index];
    }
}
//array[0] 越界
- (id)sl_objectAtIndexedSubscript:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //记录错误
        //NSString *errorInfo = [NSString stringWithFormat:@"*** -[__NSArrayI objectAtIndexedSubscript:]: index %ld beyond bounds [0 .. %ld]'",(unsigned long)index,(unsigned long)self.count];
        @try {
            return [self sl_objectAtIndexedSubscript:index];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            return self.lastObject;
        }
    }
    return [self sl_objectAtIndexedSubscript:index];
}
// nil值
- (id)sl_initWithObjects:(id  _Nonnull const [])objects count:(NSUInteger)cnt{
    NSUInteger index = 0;
    id _Nonnull objectsNew[cnt];
    for (int i = 0; i<cnt; i++) {
        if (objects[i]) {
            objectsNew[index] = objects[i];
            index++;
        }else{
            //记录错误
            NSString *errorInfo = [NSString stringWithFormat:@"异常:数组nil值 *** -[__NSPlaceholderArray initWithObjects:count:]: attempt to insert nil object from objects[%d]",i];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeArray errorDesc:errorInfo exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }
    return [self sl_initWithObjects:objectsNew count:index];
}

@end
