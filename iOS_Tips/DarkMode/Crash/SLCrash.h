//
//  SLCrash.h
//  DarkMode
//
//  Created by wsl on 2020/4/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#ifndef SLCrash_h
#define SLCrash_h

#import <objc/runtime.h>

/*交换实例方法*/
static inline void SL_ExchangeInstanceMethod(Class _originalClass ,SEL _originalSel, Class _targetClass, SEL _targetSel){
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
static inline void SL_ExchangeClassMethod(Class _class ,SEL _originalSel,SEL _exchangeSel){
    Method methodOriginal = class_getClassMethod(_class, _originalSel);
    Method methodNew = class_getClassMethod(_class, _exchangeSel);
    method_exchangeImplementations(methodOriginal, methodNew);
}


#endif /* SLCrash_h */
