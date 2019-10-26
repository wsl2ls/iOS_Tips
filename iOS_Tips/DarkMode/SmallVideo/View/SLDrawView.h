//
//  SLDrawView.h
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 涂鸦视图 画板   默认白底
@interface SLDrawView : UIView

/// 线粗 默认5.0
@property (nonatomic, assign) CGFloat lineWidth;
/// 线颜色  默认 黑色
@property (nonatomic, strong) UIColor *lineColor;
/// 正在绘画 
@property (nonatomic, readonly) BOOL isDrawing;
/// 能否返回
@property (nonatomic, readonly) BOOL canBack;
/// 能否前进
@property (nonatomic, readonly) BOOL canForward;
/// 开始绘画
@property (nonatomic, copy) void(^drawBegan)(void);
/// 结束绘画
@property (nonatomic, copy) void(^drawEnded)(void);

/// 数据  笔画数据
@property (nonatomic, strong) NSDictionary *data;

/// 前进一步
- (void)goForward;
/// 返回一步
- (void)goBack;
/// 清空画板 不可恢复
- (void)clear;

@end

NS_ASSUME_NONNULL_END
