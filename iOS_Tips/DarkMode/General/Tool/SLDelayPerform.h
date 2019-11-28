//
//  SLDelayPerform.h
//  DarkMode
//
//  Created by wsl on 2019/11/28.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 延迟执行
@interface SLDelayPerform : NSObject
/// 开始延迟执行  每次调用就重新开始计时   用完记得 执行sl_cancelDelayPerform
/// @param perform  执行内容
/// @param delay 延迟时间
+ (void)sl_startDelayPerform:(void(^)(void))perform afterDelay:(NSTimeInterval)delay;
///取消延迟执行
+ (void)sl_cancelDelayPerform;
@end

NS_ASSUME_NONNULL_END
