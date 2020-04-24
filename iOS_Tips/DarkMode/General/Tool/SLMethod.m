//
//  SLMethod.m
//  DarkMode
//
//  Created by wsl on 2020/4/24.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLMethod.h"

@implementation SLMethod

/// 切四个不同半径圆角的函数
/// @param bounds 区域
/// @param cornerRadii 四个圆角的半径
+ (CGPathRef)cornerPathCreateWithRoundedRect:(CGRect)bounds  cornerRadii:(SLCornerRadii)cornerRadii {
    const CGFloat minX = CGRectGetMinX(bounds);
    const CGFloat minY = CGRectGetMinY(bounds);
    const CGFloat maxX = CGRectGetMaxX(bounds);
    const CGFloat maxY = CGRectGetMaxY(bounds);
    
    const CGFloat topLeftCenterX = minX +  cornerRadii.topLeft;
    const CGFloat topLeftCenterY = minY + cornerRadii.topLeft;
    
    const CGFloat topRightCenterX = maxX - cornerRadii.topRight;
    const CGFloat topRightCenterY = minY + cornerRadii.topRight;
    
    const CGFloat bottomLeftCenterX = minX +  cornerRadii.bottomLeft;
    const CGFloat bottomLeftCenterY = maxY - cornerRadii.bottomLeft;
    
    const CGFloat bottomRightCenterX = maxX -  cornerRadii.bottomRight;
    const CGFloat bottomRightCenterY = maxY - cornerRadii.bottomRight;
    //虽然顺时针参数是YES，在iOS中的UIView中，这里实际是逆时针
    
    CGMutablePathRef path = CGPathCreateMutable();
    //顶 左
    CGPathAddArc(path, NULL, topLeftCenterX, topLeftCenterY,cornerRadii.topLeft, M_PI, 3 * M_PI_2, NO);
    //顶 右
    CGPathAddArc(path, NULL, topRightCenterX , topRightCenterY, cornerRadii.topRight, 3 * M_PI_2, 0, NO);
    //底 右
    CGPathAddArc(path, NULL, bottomRightCenterX, bottomRightCenterY, cornerRadii.bottomRight,0, M_PI_2, NO);
    //底 左
    CGPathAddArc(path, NULL, bottomLeftCenterX, bottomLeftCenterY, cornerRadii.bottomLeft, M_PI_2,M_PI, NO);
    CGPathCloseSubpath(path);
    return path;
}

@end
