//
//  NSObject+SLMLeakFinder.m
//  DarkMode
//
//  Created by wsl on 2020/5/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSObject+SLMLeakFinder.h"
#import "SLCrashProtector.h"

@implementation NSObject (SLMLeakFinder)

//对象即将释放时调用此方法，定义一个2秒后执行的block，如果正常释放了，weakSelf为nil，不执行notDealloc，否则如果调用了notDealloc，就表示没有释放，出现了内存泄漏。
//如果不需要监测内存泄漏或者对象本身就不要释放，就返回NO
- (BOOL)willDealloc {
    //在白名单的类
    NSString *className = NSStringFromClass([self class]);
    if ([[NSObject classNamesWhitelist] containsObject:className])
        return NO;
    
    //    NSNumber *senderPtr = objc_getAssociatedObject([UIApplication sharedApplication], kLatestSenderKey);
    //    if ([senderPtr isEqualToNumber:@((uintptr_t)self)])
    //        return NO;
    
    //用弱指针，不影响引用计数和对象的释放
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf notDealloc];
    });
    return YES;
}
//如果没释放，就执行此方法
- (void)notDealloc {
    NSString *className = NSStringFromClass([self class]);
    //    NSLog(@"有内存没释放：\n 如果%@不应该被释放, 请重写[%@ -willDealloc] 并 returning NO .\nView-ViewController stack: %@", className, className, [self viewStack]);
    NSString *desc = [NSString stringWithFormat:@"内存泄漏/循环引用：如果%@不应该被释放, 请重写[%@ -willDealloc] 并 returning NO .\n", className, className];
    NSLog(@"%@",desc);
    NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:desc userInfo:nil];
    SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeLeak errorDesc:desc exception:exception callStack:[NSThread callStackSymbols]];
    [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
}

//不需要监测内存泄漏的白名单类
+ (NSMutableSet *)classNamesWhitelist {
    static NSMutableSet *whitelist = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whitelist = [NSMutableSet setWithObjects:
                     @"UIFieldEditor", // UIAlertControllerTextField
                     @"UINavigationBar",
                     @"_UIAlertControllerActionView",
                     @"_UIVisualEffectBackdropView",
                     nil];
        
        // System's bug since iOS 10 and not fixed yet up to this ci.
        NSString *systemVersion = [UIDevice currentDevice].systemVersion;
        if ([systemVersion compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending) {
            [whitelist addObject:@"UISwitch"];
        }
    });
    return whitelist;
}

//添加白名单类
+ (void)addClassNamesToWhitelist:(NSArray *)classNames {
    [[self classNamesWhitelist] addObjectsFromArray:classNames];
}

@end
