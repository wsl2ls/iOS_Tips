//
//  NSMutableArray+Crash.m
//  DarkMode
//
//  Created by wsl on 2020/4/12.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSMutableArray+SLCrashProtector.h"
#import "SLCrashProtector.h"

@implementation NSMutableArray (SLCrashProtector)

+ (void)load {
    // 可变数组
    // nil值、越界保护
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(objectAtIndex:), NSClassFromString(@"__NSArrayM"), @selector(sl_mObjectAtIndex:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(objectAtIndexedSubscript:), NSClassFromString(@"__NSArrayM"), @selector(sl_mObjectAtIndexedSubscript:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(insertObject:atIndex:), NSClassFromString(@"__NSArrayM"), @selector(sl_insertObject:atIndex:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(insertObjects:atIndexes:), NSClassFromString(@"__NSArrayM"), @selector(sl_insertObjects:atIndexes:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(replaceObjectAtIndex:withObject:), NSClassFromString(@"__NSArrayM"), @selector(sl_replaceObjectAtIndex:withObject:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(replaceObjectsInRange:withObjectsFromArray:), NSClassFromString(@"__NSArrayM"), @selector(sl_replaceObjectsInRange:withObjectsFromArray:));
        SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectsInRange:), NSClassFromString(@"__NSArrayM"), @selector(sl_removeObjectsInRange:));
    });
}

#pragma mark - MutableArray Safe Methods
//越界
- (id)sl_mObjectAtIndex:(NSInteger)index {
    if (index >= self.count || !self.count) {
        @try {
            return [self sl_mObjectAtIndex:index];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            return self.lastObject;
        }
    }else {
        return [self sl_mObjectAtIndex:index];
    }
}
//越界
- (id)sl_mObjectAtIndexedSubscript:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //记录错误
        //NSString *errorInfo = [NSString stringWithFormat:@"*** -[__NSArrayI objectAtIndexedSubscript:]: index %ld beyond bounds [0 .. %ld]'",(unsigned long)index,(unsigned long)self.count];
        @try {
            return [self sl_mObjectAtIndexedSubscript:index];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            return self.lastObject;
        }
    }
    return [self sl_mObjectAtIndexedSubscript:index];
}
//越界
- (void)sl_removeObjectsInRange:(NSRange)range {
    if (range.location+range.length>self.count) {
        NSString *errorInfo = [NSString stringWithFormat:@"异常:数组越界 *** -[__NSArrayM removeObjectsInRange:]: range {%ld, %ld} extends beyond bounds [0 .. %ld]",(unsigned long)range.location,(unsigned long)range.length,(unsigned long)self.count];
        SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:errorInfo exception:nil callStack:[NSThread callStackSymbols]];
        [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        return;
    }
    [self sl_removeObjectsInRange:range];
}
//越界 nil值
- (void)sl_replaceObjectAtIndex:(NSInteger)index withObject:(id)object {
    if (object == nil) {
        SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:@"异常:数组nil值 ***  -[__NSArrayM replaceObjectAtIndex:withObject:]: object cannot be nil" exception:nil callStack:[NSThread callStackSymbols]];
        [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        return;
    }
    if (index >= self.count) {
        @try {
            return [self sl_replaceObjectAtIndex:index withObject:object];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }else {
        [self sl_replaceObjectAtIndex:index withObject:object];
    }
}
//越界
- (void)sl_replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray {
    if (range.location+range.length > self.count) {
        @try {
            return [self sl_replaceObjectsInRange:range withObjectsFromArray:otherArray];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }else{
        [self sl_replaceObjectsInRange:range withObjectsFromArray:otherArray];
    }
}

//越界 nil值
- (void)sl_insertObject:(id)object atIndex:(NSInteger)index {
    if (object == nil) {
        
        SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:@"异常:数组nil值 ***  -[__NSArrayM insertObject:atIndex:]: object cannot be nil" exception:nil callStack:[NSThread callStackSymbols]];
        [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        
        return;
    }
    if (index > self.count) {
        @try {
            return [self sl_insertObject:object atIndex:index];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }else {
        [self sl_insertObject:object atIndex:index];;
    }
}
//越界
- (void)sl_insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes {
    if (indexes.firstIndex > self.count || objects.count != (indexes.count)) {
        @try {
            return [self sl_insertObjects:objects atIndexes:indexes];
        }
        @catch (NSException *exception) {
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:[NSString stringWithFormat:@"异常:数组越界 %@",exception.reason] exception:exception callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
        return;
    }
    [self sl_insertObjects:objects atIndexes:indexes];
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
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeMArray errorDesc:errorInfo exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }
    return [self sl_initWithObjects:objectsNew count:index];
}

@end

