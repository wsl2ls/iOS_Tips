//
//  SLEditMenuView.h
//  DarkMode
//
//  Created by wsl on 2019/10/9.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
///视频和图片的编辑类型
typedef NS_ENUM(NSUInteger, SLEditMenuType) {
    /// 涂鸦
    SLEditMenuTypeGraffiti = 0,
    /// 文字
    SLEditMenuTypeText,
    /// 贴画
    SLEditMenuTypeSticking,
    /// 裁剪
    SLEditMenuTypeCutting
};

/// 底部音视频编辑主菜单栏
@interface SLEditMenuView : UIView

/// 选择编辑的子菜单回调
@property (nonatomic, copy) void(^selectEditMenu)(SLEditMenuType editMenuType,  NSDictionary * _Nullable setting);

@end

NS_ASSUME_NONNULL_END
