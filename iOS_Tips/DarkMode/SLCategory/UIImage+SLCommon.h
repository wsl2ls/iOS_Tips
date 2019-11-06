//
//  UIImage+SLCommon.h
//  DarkMode
//
//  Created by wsl on 2019/10/25.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 通用方法分类
@interface UIImage (SLCommon)

/// 将图片旋转弧度radians 
- (UIImage *)sl_imageRotatedByRadians:(CGFloat)radians;
/// 提取图片上某位置像素的颜色
- (UIColor *)sl_colorAtPixel:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
