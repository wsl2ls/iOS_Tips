//
//  NSObject+SLDelayPerform.h
//  DarkMode
//
//  Created by wsl on 2019/10/19.
//  Copyright © 2019 wsl. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 延迟执行
@interface NSObject (SLDelayPerform)
/// 开始延迟执行  每次重新开始计时
/// @param perform  执行内容
/// @param delay 延迟时间
- (void)startDelayPerform:(void(^)(void))perform afterDelay:(NSTimeInterval)delay;
///取消延迟执行
- (void)cancelDelayPerform;
@end

NS_ASSUME_NONNULL_END
