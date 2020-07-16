//
//  UIViewController+SLMLeakFinder.m
//  DarkMode
//
//  Created by wsl on 2020/5/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "UIViewController+SLMLeakFinder.h"
#import "SLCrashProtector.h"
#import "NSObject+SLMLeakFinder.h"

const void *const kSLHasBeenPoppedKey = &kSLHasBeenPoppedKey;

@implementation UIViewController (SLMLeakFinder)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //        SL_ExchangeInstanceMethod([UIViewController class], @selector(viewDidDisappear:), [UIViewController class], @selector(sl_viewDidDisappear:));
        //        SL_ExchangeInstanceMethod([UIViewController class], @selector(viewWillAppear:), [UIViewController class], @selector(sl_viewWillAppear:));
        SL_ExchangeInstanceMethod([UIViewController class], @selector(dismissViewControllerAnimated:completion:), [UIViewController class], @selector(sl_dismissViewControllerAnimated:completion:));
    });
}

///dismiss时即将释放，调用willDealloc
- (void)sl_dismissViewControllerAnimated: (BOOL)flag completion: (void (^ __nullable)(void))completion {
    [self sl_dismissViewControllerAnimated:flag completion:completion];
    UIViewController *dismissedViewController = self.presentedViewController;
    if (!dismissedViewController && self.presentingViewController) {
        dismissedViewController = self;
    }
    if (!dismissedViewController) return;
    [dismissedViewController willDealloc];
}

- (BOOL)willDealloc {
    if (![super willDealloc]) {
        return NO;
    }
    return YES;
}

@end
