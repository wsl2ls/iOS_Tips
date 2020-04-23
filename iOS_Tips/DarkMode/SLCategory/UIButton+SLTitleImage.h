//
//  UIButton+SLTitleImage.h
//  ZGEBook
//
//  Created by wsl on 2020/4/22.
//  Copyright © 2020 ZGEBook. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SLTitleImageStyle) {
    SLTitleImageStyleImageLeft = 0,// 左图右文
    SLTitleImageStyleImageRight, //右图左文
    SLTitleImageStyleImageTop, //上图下文
    SLTitleImageStyleImageBottom //下图上文
};

/// 设置文本和图片的位置
@interface UIButton (SLTitleImage)
///设置文本图片布局方式
- (void)sl_setTitleImageLayoutStyle:(SLTitleImageStyle)titleImageStyle space:(CGFloat)space;

@end

NS_ASSUME_NONNULL_END
