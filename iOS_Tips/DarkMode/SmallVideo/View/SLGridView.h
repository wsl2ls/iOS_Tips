//
//  SLGridView.h
//
//  Created by wsl on 2019/10/27.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class SLGridView;
/// 网格调整大小代理
@protocol SLGridViewDelegate <NSObject>
@optional
/// 开始调整大小
- (void)gridViewDidBeginResizing:(SLGridView *)gridView;
/// 正在调整大小
- (void)gridViewDidResizing:(SLGridView *)gridView;
/// 结束调整大小
- (void)gridViewDidEndResizing:(SLGridView *)gridView;
@end

/// 网格视图
@interface SLGridView : UIView
/// 网格区域   默认CGRectInset(self.bounds, 20, 20)
@property (nonatomic, assign) CGRect gridRect;
/// 网格 最小尺寸   默认 CGSizeMake(60, 60);
@property (nonatomic, assign) CGSize minGridSize;
/// 网格最大区域   默认 CGRectInset(self.bounds, 20, 20)
@property (nonatomic, assign) CGRect maxGridRect;
/// 原来尺寸 默认CGRectInset(self.bounds, 20, 20).size
@property (nonatomic, assign) CGSize originalGridSize;
/// 网格代理
@property (nonatomic, weak) id<SLGridViewDelegate> delegate;
/// 显示遮罩层  半透明黑色  默认 YES
@property (nonatomic, assign) BOOL showMaskLayer;
/// 是否正在拖动 
@property(nonatomic,assign,readonly) BOOL dragging;

@end

NS_ASSUME_NONNULL_END
