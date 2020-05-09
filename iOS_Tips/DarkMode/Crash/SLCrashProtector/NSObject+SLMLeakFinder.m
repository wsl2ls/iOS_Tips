//
//  NSObject+SLMLeakFinder.m
//  DarkMode
//
//  Created by wsl on 2020/5/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSObject+SLMLeakFinder.h"


static const void *const kViewStackKey = &kViewStackKey;
static const void *const kParentPtrsKey = &kParentPtrsKey;
const void *const kLatestSenderKey = &kLatestSenderKey;

@implementation NSObject (SLMLeakFinder)

//对象即将释放时调用此方法，定义一个2秒后执行的block，如果正常释放了，weakSelf为nil，不执行notDealloc，否则如果调用了notDealloc，就表示没有释放，出现了内存泄漏。
//如果不需要监测内存泄漏或者对象本身就不要释放，就返回NO
- (BOOL)willDealloc {
    //在白名单的类
    NSString *className = NSStringFromClass([self class]);
    if ([[NSObject classNamesWhitelist] containsObject:className])
        return NO;
    
    NSNumber *senderPtr = objc_getAssociatedObject([UIApplication sharedApplication], kLatestSenderKey);
    if ([senderPtr isEqualToNumber:@((uintptr_t)self)])
        return NO;
    
    //用弱指针，不影响引用计数和对象的释放
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf notDealloc];
    });
    return YES;
}
//如果没释放，就执行此方法
- (void)notDealloc {
    NSString *className = NSStringFromClass([self class]);
    //    NSLog(@"有内存没释放：\n 如果%@不应该被释放, 请重写[%@ -willDealloc] 并 returning NO .\nView-ViewController stack: %@", className, className, [self viewStack]);
    NSLog(@"有内存没释放：如果%@不应该被释放, 请重写[%@ -willDealloc] 并 returning NO .\n", className, className);
}

/*
 - (void)willReleaseObject:(id)object relationship:(NSString *)relationship {
 if ([relationship hasPrefix:@"self"]) {
 relationship = [relationship stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@""];
 }
 NSString *className = NSStringFromClass([object class]);
 className = [NSString stringWithFormat:@"%@(%@), ", relationship, className];
 
 [object setViewStack:[[self viewStack] arrayByAddingObject:className]];
 [object setParentPtrs:[[self parentPtrs] setByAddingObject:@((uintptr_t)object)]];
 [object willDealloc];
 }
 ///即将释放子对象
 - (void)willReleaseChild:(id)child {
 if (!child) {
 return;
 }
 [self willReleaseChildren:@[ child ]];
 }
 ///即将释放子对象集合
 - (void)willReleaseChildren:(NSArray *)children {
 NSArray *viewStack = [self viewStack];
 NSSet *parentPtrs = [self parentPtrs];
 for (id child in children) {
 NSString *className = NSStringFromClass([child class]);
 [child setViewStack:[viewStack arrayByAddingObject:className]];
 [child setParentPtrs:[parentPtrs setByAddingObject:@((uintptr_t)child)]];
 [child willDealloc];
 }
 }
 //返回视图堆栈信息
 - (NSArray *)viewStack {
 NSArray *viewStack = objc_getAssociatedObject(self, kViewStackKey);
 if (viewStack) {
 return viewStack;
 }
 
 NSString *className = NSStringFromClass([self class]);
 return @[ className ];
 }
 
 - (void)setViewStack:(NSArray *)viewStack {
 objc_setAssociatedObject(self, kViewStackKey, viewStack, OBJC_ASSOCIATION_RETAIN);
 }
 
 - (NSSet *)parentPtrs {
 NSSet *parentPtrs = objc_getAssociatedObject(self, kParentPtrsKey);
 if (!parentPtrs) {
 parentPtrs = [[NSSet alloc] initWithObjects:@((uintptr_t)self), nil];
 }
 return parentPtrs;
 }
 
 - (void)setParentPtrs:(NSSet *)parentPtrs {
 objc_setAssociatedObject(self, kParentPtrsKey, parentPtrs, OBJC_ASSOCIATION_RETAIN);
 }
 */

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
