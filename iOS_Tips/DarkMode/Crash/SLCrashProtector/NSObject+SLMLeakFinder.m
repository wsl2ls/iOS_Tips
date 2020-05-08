//
//  NSObject+SLMLeakFinder.m
//  DarkMode
//
//  Created by wsl on 2020/5/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSObject+SLMLeakFinder.h"

@implementation NSObject (SLMLeakFinder)

//对象即将释放时调用此方法，定义一个3秒后执行的block，如果正常释放了，weakSelf为nil，不执行notDealloc，否则如果调用了notDealloc，就表示没有释放，出现了内存泄漏。
- (BOOL)willDealloc {
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf notDealloc];
    });
    return YES;
}
- (void)notDealloc {
    NSLog(@"内存泄露了: %@ 没释放",NSStringFromClass(self.class));
}

@end
