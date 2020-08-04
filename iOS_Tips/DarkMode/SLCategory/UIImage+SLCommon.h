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

/// 图片缩放，针对大图片处理
+ (UIImage *)sl_scaledImageWithData:(NSData *)data withSize:(CGSize)size scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;

@end

NS_ASSUME_NONNULL_END
