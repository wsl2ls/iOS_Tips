//
//  UIColor+SLCommon.h
//  DarkMode
//
//  Created by wsl on 2020/6/10.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (SLCommon)

/// 根据16进制颜色值返回UIColor
/// @param hexValue 16进制值
/// @param alpha 透明度
+ (UIColor *)sl_colorWithHex:(int)hexValue alpha:(CGFloat)alpha;

/// 根据UIColor实例获得RGBA的值
/// @param color UIColor实例
+ (NSArray *)sl_rgbaValueWithColor:(UIColor *)color;

/// 根据UIColor实例返回16进制颜色值
/// @param color UIColor实例
+ (int)sl_hexValueWithColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
