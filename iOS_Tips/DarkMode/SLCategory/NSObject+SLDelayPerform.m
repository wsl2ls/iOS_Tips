//
//  NSObject+SLDelayPerform.m
//  DarkMode
//
//  Created by wsl on 2019/10/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "NSObject+SLDelayPerform.h"

//延迟执行的回调
static dispatch_block_t sl_delayBlock;

@implementation NSObject (SLDelayPerform)
/// 开始延迟执行  每次重新开始计时
/// @param perform  执行内容
/// @param delay 延迟时间
- (void)startDelayPerform:(void(^)(void))perform afterDelay:(NSTimeInterval)delay {
    if (sl_delayBlock != nil) {
        dispatch_block_cancel(sl_delayBlock);
        sl_delayBlock = nil;
    }
    if (sl_delayBlock == nil) {
        sl_delayBlock = dispatch_block_create(DISPATCH_BLOCK_BARRIER, ^{
            perform();
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(),sl_delayBlock);
}
///取消延迟执行
- (void)cancelDelayPerform {
    if (sl_delayBlock != nil) {
        dispatch_block_cancel(sl_delayBlock);
        sl_delayBlock = nil;
    }
}
@end
