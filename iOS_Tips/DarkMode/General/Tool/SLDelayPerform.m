//
//  SLDelayPerform.m
//  DarkMode
//
//  Created by wsl on 2019/11/28.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLDelayPerform.h"

//延迟执行的回调 静态全局变量
static dispatch_block_t sl_delayBlock;

@implementation SLDelayPerform
/// 开始延迟执行  每次调用就重新开始计时   用完记得 执行sl_cancelDelayPerform
/// @param perform  执行内容
/// @param delay 延迟时间
+ (void)sl_startDelayPerform:(void(^)(void))perform afterDelay:(NSTimeInterval)delay {
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
+ (void)sl_cancelDelayPerform {
    if (sl_delayBlock != nil) {
        dispatch_block_cancel(sl_delayBlock);
        sl_delayBlock = nil;
    }
}
@end
