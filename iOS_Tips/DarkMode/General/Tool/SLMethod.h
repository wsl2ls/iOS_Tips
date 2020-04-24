//
//  SLMethod.h
//  DarkMode
//
//  Created by wsl on 2020/4/24.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//四个圆角半径
struct SLCornerRadii {
    CGFloat topLeft; //左上
    CGFloat topRight; //右上
    CGFloat bottomLeft; //左下
    CGFloat bottomRight; //右下
};
typedef struct CG_BOXABLE SLCornerRadii SLCornerRadii;
//SLCornerRadii初始化函数
CG_INLINE SLCornerRadii SLCornerRadiiMake(CGFloat topLeft,CGFloat topRight,CGFloat bottomLeft,CGFloat bottomRight){
    return (SLCornerRadii){
        topLeft,
        topRight,
        bottomLeft,
        bottomRight,
    };
}

/// 辅助公共方法集合
@interface SLMethod : NSObject

/// 切四个不同半径圆角的函数
/// @param bounds 区域
/// @param cornerRadii 四个圆角的半径
+ (CGPathRef)cornerPathCreateWithRoundedRect:(CGRect)bounds  cornerRadii:(SLCornerRadii)cornerRadii;

@end

NS_ASSUME_NONNULL_END
