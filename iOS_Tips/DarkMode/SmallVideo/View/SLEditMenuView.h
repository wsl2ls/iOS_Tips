//
//  SLEditMenuView.h
//  DarkMode
//
//  Created by wsl on 2019/10/9.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
///编辑对象类型 视频 Or  图片
typedef NS_ENUM(NSUInteger, SLEditObject) {
    ///没有编辑对象
    SLEditObjectUnknow = 0,
    /// 图片编辑
    SLEditObjectPicture = 1,
    /// 视频编辑
    SLEditObjectVideo
};
///视频和图片的编辑类型
typedef NS_ENUM(NSUInteger, SLEditMenuType) {
    /// 无类型
    SLEditMenuTypeUnknown = 0,
    /// 涂鸦
    SLEditMenuTypeGraffiti = 1,
    /// 文字
    SLEditMenuTypeText,
    /// 贴画
    SLEditMenuTypeSticking,
    /// 视频裁剪
    SLEditMenuTypeVideoClipping,
    /// 图片马赛克
    SLEditMenuTypePictureMosaic,
    /// 图片裁剪
    SLEditMenuTypePictureClipping
};
/// 底部音视频、图片编辑主菜单栏
@interface SLEditMenuView : UIView
/// 编辑对象
@property (nonatomic, assign) SLEditObject editObject;
/// 选择编辑的子菜单回调
@property (nonatomic, copy) void(^selectEditMenu)(SLEditMenuType editMenuType,  NSDictionary * _Nullable setting);

@end

NS_ASSUME_NONNULL_END
