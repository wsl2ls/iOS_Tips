//
//  SLTimer.h
//
//  Created by wsl on 2020/6/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//


#import <Foundation/Foundation.h>

///计时器  比NSTimer和CADisplayLink计时准确
@interface SLTimer : NSObject

/// 执行任务  返回任务名称
/// @param task  任务Block
/// @param start 开始时间
/// @param interval 时间间隔
/// @param repeats 是否重复
/// @param async 是否异步
+ (NSString *)execTask:(void(^)(void))task
                 start:(NSTimeInterval)start
              interval:(NSTimeInterval)interval
               repeats:(BOOL)repeats
                 async:(BOOL)async;

/// 执行任务  返回任务名称
/// @param target 选择器执行者
/// @param selector 选择器
/// @param start 开始时间
/// @param interval 时间间隔
/// @param repeats 是否重复
/// @param async 是否异步
+ (NSString *)execTask:(id)target
              selector:(SEL)selector
                 start:(NSTimeInterval)start
              interval:(NSTimeInterval)interval
               repeats:(BOOL)repeats
                 async:(BOOL)async;

/// 取消任务
/// @param taskName 任务名称
+ (void)cancelTask:(NSString *)taskName;

@end
