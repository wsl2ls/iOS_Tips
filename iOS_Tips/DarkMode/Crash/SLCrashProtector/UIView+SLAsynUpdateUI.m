//
//  UIView+SLAsynUpdateUI.m
//  DarkMode
//
//  Created by wsl on 2020/8/7.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "UIView+SLAsynUpdateUI.h"
#import "SLCrashProtector.h"

@implementation UIView (SLAsynUpdateUI)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SL_ExchangeInstanceMethod([UIView class], @selector(setNeedsLayout), [UIView class], @selector(sl_setNeedsLayout));
        SL_ExchangeInstanceMethod([UIView class], @selector(setNeedsDisplay), [UIView class], @selector(sl_setNeedsDisplay));
        SL_ExchangeInstanceMethod([UIView class], @selector(setNeedsDisplayInRect:), [UIView class], @selector(sl_setNeedsDisplayInRect:));
    });
}

- (void)sl_setNeedsLayout{
    if ([self isAsynUpdateUI]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sl_setNeedsLayout];
        });
    }else {
        [self sl_setNeedsLayout];
    }
}
- (void)sl_setNeedsDisplay{
    if ([self isAsynUpdateUI]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sl_setNeedsDisplay];
        });
    }else {
        [self sl_setNeedsDisplay];
    }
    
}
- (void)sl_setNeedsDisplayInRect:(CGRect)rect{
    if ([self isAsynUpdateUI]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sl_setNeedsDisplayInRect:rect];
        });
    }else {
        [self sl_setNeedsDisplayInRect:rect];
    }
    
}

- (BOOL)isAsynUpdateUI{
    if(![NSThread isMainThread]){
        NSString *reason = [NSString stringWithFormat:@"异常：异步线程刷新UI"];
        SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeAsynUpdateUI errorDesc:reason exception:nil callStack:[NSThread callStackSymbols]];
        [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
        return YES;
    }
    return NO;
}


@end
