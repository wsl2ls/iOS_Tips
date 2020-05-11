//
//  UIView+SLMLeakFinder.m
//  DarkMode
//
//  Created by wsl on 2020/5/8.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "UIView+SLMLeakFinder.h"
#import "NSObject+SLMLeakFinder.h"

@implementation UIView (SLMLeakFinder)

- (BOOL)willDealloc {
    if (![super willDealloc]) {
        return NO;
    }
    return YES;
}

@end
