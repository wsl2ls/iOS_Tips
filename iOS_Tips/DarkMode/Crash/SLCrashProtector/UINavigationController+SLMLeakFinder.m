//
//  UINavigationController+SLMLeakFinder.m
//  DarkMode
//
//  Created by wsl on 2020/5/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "UINavigationController+SLMLeakFinder.h"
#import "SLCrashProtector.h"
#import "NSObject+SLMLeakFinder.h"

static const void *const kSLPoppedDetailVCKey = &kSLPoppedDetailVCKey;

@implementation UINavigationController (SLMLeakFinder)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SL_ExchangeInstanceMethod([UINavigationController class], @selector(pushViewController:animated:), [UINavigationController class], @selector(sl_pushViewController:animated:));
        SL_ExchangeInstanceMethod([UINavigationController class], @selector(popViewControllerAnimated:), [UINavigationController class], @selector(sl_popViewControllerAnimated:));
        SL_ExchangeInstanceMethod([UINavigationController class], @selector(popToViewController:animated:), [UINavigationController class], @selector(sl_popToViewController:animated:));
        SL_ExchangeInstanceMethod([UINavigationController class], @selector(popToRootViewControllerAnimated:), [UINavigationController class], @selector(sl_popToRootViewControllerAnimated:));
    });
}

- (void)sl_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.splitViewController) {
        id detailViewController = objc_getAssociatedObject(self, kSLPoppedDetailVCKey);
        if ([detailViewController isKindOfClass:[UIViewController class]]) {
            [detailViewController willDealloc];
            objc_setAssociatedObject(self, kSLPoppedDetailVCKey, nil, OBJC_ASSOCIATION_RETAIN);
        }
    }
    [self sl_pushViewController:viewController animated:animated];
}

- (UIViewController *)sl_popViewControllerAnimated:(BOOL)animated {
    UIViewController *poppedViewController = [self sl_popViewControllerAnimated:animated];
    [poppedViewController willDealloc];
    
    if (!poppedViewController) {
        return nil;
    }
    
    // Detail VC in UISplitViewController is not dealloced until another detail VC is shown
    if (self.splitViewController &&
        self.splitViewController.viewControllers.firstObject == self &&
        self.splitViewController == poppedViewController.splitViewController) {
        objc_setAssociatedObject(self, kSLPoppedDetailVCKey, poppedViewController, OBJC_ASSOCIATION_RETAIN);
        return poppedViewController;
    }
    
    // VC is not dealloced until disappear when popped using a left-edge swipe gesture
    extern const void *const kSLHasBeenPoppedKey;
    objc_setAssociatedObject(poppedViewController, kSLHasBeenPoppedKey, @(YES), OBJC_ASSOCIATION_RETAIN);
    
    return poppedViewController;
}
- (NSArray<UIViewController *> *)sl_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<UIViewController *> *poppedViewControllers = [self sl_popToViewController:viewController animated:animated];
    for (UIViewController *viewController in poppedViewControllers) {
        [viewController willDealloc];
    }
    return poppedViewControllers;
}
- (NSArray<UIViewController *> *)sl_popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<UIViewController *> *poppedViewControllers = [self sl_popToRootViewControllerAnimated:animated];
    for (UIViewController *viewController in poppedViewControllers) {
        [viewController willDealloc];
    }
    return poppedViewControllers;
}

- (BOOL)willDealloc {
    //如果该对象不需要释放，就return NO
    if (![super willDealloc]) {
        return NO;
    }
    return YES;
}

@end
