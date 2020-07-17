//
//  NSDictionary+SLCrash.m
//  DarkMode
//
//  Created by wsl on 2020/4/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSDictionary+SLCrashProtector.h"
#import "SLCrashProtector.h"

@implementation NSDictionary (SLCrashProtector)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class dictionaryClass = NSClassFromString(@"NSDictionary");
        SL_ExchangeInstanceMethod(dictionaryClass, @selector(initWithObjects:forKeys:), dictionaryClass, @selector(sl_initWithObjects:forKeys:));
        
        Class __NSPlaceholderDictionaryClass = NSClassFromString(@"__NSPlaceholderDictionary");
        SL_ExchangeInstanceMethod(__NSPlaceholderDictionaryClass, @selector(initWithObjects:forKeys:count:), __NSPlaceholderDictionaryClass, @selector(sl_initWithObjects:forKeys:count:));
    });
}

#pragma mark - Dictionary Safe Methods
//nil值
- (id)sl_initWithObjects:(NSArray *)objects forKeys:(NSArray<id<NSCopying>> *)keys {
    if (objects.count != keys.count) {
        NSString *errorInfo = [NSString stringWithFormat:@"异常:字典key/value个数不匹配 *** -[NSDictionary initWithObjects:forKeys:]: count of objects (%ld) differs from count of keys (%ld)",(unsigned long)objects.count,(unsigned long)keys.count];
        SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeDictionary errorDesc:errorInfo exception:nil callStack:[NSThread callStackSymbols]];
        [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        
        return nil;//huicha
    }
    NSUInteger index = 0;
    id _Nonnull objectsNew[objects.count];
    id <NSCopying> _Nonnull keysNew[keys.count];
    for (int i = 0; i<keys.count; i++) {
        if (objects[i] && keys[i]) {
            objectsNew[index] = objects[i];
            keysNew[index] = keys[i];
            index ++;
        }else{
            NSString *errorInfo = [NSString stringWithFormat:@"异常:字典nil值 *** -[NSDictionary initWithObjects:forKeys]: attempt to insert nil object from objects[%d]",i];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeDictionary errorDesc:errorInfo exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }
    return [self sl_initWithObjects:[NSArray arrayWithObjects:objectsNew count:index] forKeys: [NSArray arrayWithObjects:keysNew count:index]];
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
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeDictionary errorDesc:errorInfo exception:nil callStack:[NSThread callStackSymbols]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        }
    }
    return [self sl_initWithObjects:objectsNew forKeys:keysNew count:index];
}

@end
