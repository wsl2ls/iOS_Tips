//
//  SLEditVideoClipping.h
//  DarkMode
//
//  Created by wsl on 2019/10/21.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 视频裁剪底部子菜单 选择裁剪范围
@interface SLEditVideoClipping : UIView
/// 视频资源文件
@property (nonatomic, strong) AVAsset *asset;
/// 选择视频截取起点
@property (nonatomic, copy) void(^selectedClippingBegin)(CMTime beginTime, CMTime endTime, UIGestureRecognizerState state);
/// 选择视频截取终点
@property (nonatomic, copy) void(^selectedClippingEnd)(CMTime beginTime, CMTime endTime, UIGestureRecognizerState state);
/// 退出截取菜单
@property (nonatomic, copy) void(^exitClipping)(void);

@end

NS_ASSUME_NONNULL_END
