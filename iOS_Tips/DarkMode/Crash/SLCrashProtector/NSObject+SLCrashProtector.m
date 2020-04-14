//
//  NSObject+SLCrashProtector.m
//  DarkMode
//
//  Created by wsl on 2020/4/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSObject+SLCrashProtector.h"
#import "SLCrashProtector.h"

@implementation NSObject (SLCrashProtector)


+ (void)load {
   
    /// Unrecognized Selector  未识别方法防护
    SL_ExchangeInstanceMethod([NSObject class], @selector(forwardingTargetForSelector:), [NSObject class], @selector(sl_forwardingTargetForSelector:));
    
    SL_ExchangeInstanceMethod([NSObject class], @selector(doesNotRecognizeSelector:), [NSObject class], @selector(sl_doesNotRecognizeSelector:));
    
//    SL_ExchangeClassMethod(<#__unsafe_unretained Class _class#>, <#SEL _originalSel#>, <#SEL _exchangeSel#>)
    
}


#pragma mark - Unrecognized Selector

//
- (id)sl_forwardingTargetForSelector:(SEL)aSelector {
//    NSLog(@"异常:未识别方法 %@", NSStringFromSelector(aSelector));
    return [self sl_forwardingTargetForSelector:aSelector];;
}

// 如果没有实现消息转发 forwardInvocation  则调用此方法
- (void)sl_doesNotRecognizeSelector:(SEL)aSelector {
    NSLog(@"找不到方法：%@", NSStringFromSelector(aSelector));
}


/*
 
 // 第一步 动态方法解析
 // 消息接收者没有找到对应的方法时候，会先调用此方法，可在此方法实现中动态添加新的方法，返回YES表示相应selector的实现已经被找到，或者添加新方法到了类中，结束查找；否则返回NO，继续执行第二步
 + (BOOL)resolveInstanceMethod:(SEL)sel {
     if (sel == @selector(add)) {
         // 动态添加方法
         class_addMethod(self, sel, (IMP)add,"v@:");
         return YES;
     }
     return [super resolveInstanceMethod:sel];
 }

 
 
//  第二步 重定向
//  如果第一步的返回NO或者直接返回了YES而没有添加方法，该方法被调用 ,在这个方法中，我们可以指定返回一个可以响应该方法的对象， 注意如果返回self就会死循环；如果返回nil，即表示不转发给其他对象，此时会进入第三步
- (id)forwardingTargetForSelector:(SEL)aSelector {
    //    if (aSelector == @selector(add)) {
    //        //消息转发给ForwardingTarget对象
    //        if ([[ForwardingTarget new] respondsToSelector:@selector(add)]) {
    //           return [ForwardingTarget new];
    //        }
    //    }
    return [super forwardingTargetForSelector:aSelector];
}

//  第三步 消息转发
//  如果forwardingTargetForSelector:返回了nil，则该方法会被调用，系统会询问我们要一个合法的『类型编码(Type Encoding)』, 若返回 nil，则不会进入下一步，而是无法处理消息
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    //    if (aSelector == @selector(add)) {
    //           方法签名
    //        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    //    }
    return  [super methodSignatureForSelector:aSelector];
}
// 在这里进行消息转发
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    //    SEL sel = [anInvocation selector];
    //    ForwardingTarget* forward = [ForwardingTarget new];
    //    if ([forward respondsToSelector:sel]) {
    //         //指定消息的接收者
    //         [anInvocation invokeWithTarget:forward];
    //    }else{
    [super forwardInvocation:anInvocation];
    //    }
    
}

// 如果没有实现消息转发 forwardInvocation  则调用此方法
- (void)doesNotRecognizeSelector:(SEL)aSelector {
    NSLog(@"找不到方法：%@", NSStringFromSelector(aSelector));
}

*/

@end
