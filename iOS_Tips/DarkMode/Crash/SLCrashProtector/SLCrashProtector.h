//
//  SLCrashProtector.h
//  DarkMode
//
//  Created by wsl on 2020/4/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#ifndef SLCrashProtector_h
#define SLCrashProtector_h

#import <objc/runtime.h>

#import "SLCrashHandler.h"
#import "SLZombieCatcher.h"
#import "SLZombieFinder.h"

/*交换实例方法*/
static inline void SL_ExchangeInstanceMethod(Class _originalClass ,SEL _originalSel, Class _targetClass, SEL _targetSel){
    //此处获得的方法可能是父类对象的
    Method methodOriginal = class_getInstanceMethod(_originalClass, _originalSel);
    Method methodNew = class_getInstanceMethod(_targetClass, _targetSel);
    // class_addMethod 返回成功表示被替换的方法没实现，然后会通过 class_addMethod 方法先实现；返回失败则表示被替换方法已存在，可以直接进行 IMP 指针交换
    BOOL didAddMethod = class_addMethod(_originalClass, _originalSel, method_getImplementation(methodNew), method_getTypeEncoding(methodNew));
    if (didAddMethod) {
        // 进行方法的替换
        class_replaceMethod(_targetClass, _targetSel, method_getImplementation(methodOriginal), method_getTypeEncoding(methodOriginal));
    }else{
        // 交换 IMP 指针
        method_exchangeImplementations(methodOriginal, methodNew);
    }
}
/*交换类方法*/
static inline void SL_ExchangeClassMethod(Class _class ,SEL _originalSel,SEL _exchangeSel){
    Method methodOriginal = class_getClassMethod(_class, _originalSel);
    Method methodNew = class_getClassMethod(_class, _exchangeSel);
    method_exchangeImplementations(methodOriginal, methodNew);
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


#endif /* SLCrashProtector_h */
