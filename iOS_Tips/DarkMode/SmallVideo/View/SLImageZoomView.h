//
//  SLScrollView.h
//
//  Created by wsl on 2019/10/27.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLImageZoomViewDelegate;
/// 缩放视图 用于图片编辑
@interface SLImageZoomView : UIScrollView
@property (nonatomic, strong) UIImage *image;
//
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, weak) id<SLImageZoomViewDelegate> zoomViewDelegate;
@end

/// 缩放视图代理
@protocol SLImageZoomViewDelegate <NSObject>
@optional
/// 开始移动图像位置
- (void)zoomViewDidBeginMoveImage:(SLImageZoomView *)zoomView;
/// 结束移动图像
- (void)zoomViewDidEndMoveImage:(SLImageZoomView *)zoomView;
@end

NS_ASSUME_NONNULL_END
