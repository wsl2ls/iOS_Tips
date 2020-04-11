//
//  NSArray+Crash.m
//  DarkMode
//
//  Created by wsl on 2020/4/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSArray+Crash.h"
#import <objc/runtime.h>

@implementation NSArray (Crash)

+ (void)load {
    [super load];
    
    //替换不可变数组方法
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(objectAtIndex:), NSClassFromString(@"__NSArrayI"), @selector(sl_objectAtIndex:));
//    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSSingleObjectArrayI"), @selector(objectAtIndex:), NSClassFromString(@"__NSSingleObjectArrayI"), @selector(BMP__NSSingleObjectArrayIObjectAtIndex:));
//    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArray0"), @selector(objectAtIndex:), NSClassFromString(@"__NSArray0"), @selector(BMP__NSArray0ObjectAtIndex:));
    
    //
    //替换可变数组方法
    //        Method oldMutableObjectAtIndex = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(objectAtIndex:));
    //    Method newMutableObjectAtIndex =  class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(mutableObjectAtSafeIndex:));
    //    method_exchangeImplementations(oldMutableObjectAtIndex, newMutableObjectAtIndex);
}

/*交换实例方法*/
void SL_ExchangeInstanceMethod(Class _originalClass ,SEL _originalSel, Class _targetClass, SEL _targetSel){
    Method methodOriginal = class_getInstanceMethod(_originalClass, _originalSel);
    Method methodNew = class_getInstanceMethod(_targetClass, _targetSel);
    BOOL didAddMethod = class_addMethod(_originalClass, _originalSel, method_getImplementation(methodNew), method_getTypeEncoding(methodNew));
    if (didAddMethod) {
        class_replaceMethod(_originalClass, _targetSel, method_getImplementation(methodOriginal), method_getTypeEncoding(methodOriginal));
    }else{
        method_exchangeImplementations(methodOriginal, methodNew);
    }
}
/*交换类方法*/
void SL_ExchangeClassMethod(Class _class ,SEL _originalSel,SEL _exchangeSel){
    Method methodOriginal = class_getClassMethod(_class, _originalSel);
    Method methodNew = class_getClassMethod(_class, _exchangeSel);
    method_exchangeImplementations(methodOriginal, methodNew);
}

- (id)sl_objectAtIndex:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //可能抛出异常的代码
        @try {
            return [self sl_objectAtIndex:index];
        }
        @catch (NSException *exception) {
            NSLog(@"数组异常: %@", exception.reason);
            return nil;
        }
    }else {
        return [self sl_objectAtIndex:index];
    }
}

- (id)BMP__NSSingleObjectArrayIObjectAtIndex:(NSInteger)index  {
    
    if (index >= self.count || !self.count) {
        //可能抛出异常的代码
        @try {
            return [self BMP__NSSingleObjectArrayIObjectAtIndex:index];
        }
        @catch (NSException *exception) {
            NSLog(@"数组异常: %@", exception.reason);
            return nil;
        }
    }
    
}

- (id)BMP__NSArray0ObjectAtIndex:(NSInteger)index {
     if (index >= self.count || !self.count) {
           //可能抛出异常的代码
           @try {
               return [self BMP__NSArray0ObjectAtIndex:index];
           }
           @catch (NSException *exception) {
               NSLog(@"数组异常: %@", exception.reason);
               return nil;
           }
       }
}

@end
