//
//  SLButton.h
//
//  Created by wsl on 2020/4/23.
//  Copyright © 2020 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SLButtonStyle) {
    SLButtonStyleImageLeft = 0,// 左图右文
    SLButtonStyleImageRight, //右图左文
    SLButtonStyleImageTop, //上图下文
    SLButtonStyleImageBottom //下图上文
};

/// 自定义Button  自定义文本和图片布局样式
@interface SLButton : UIControl
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
///设置文本图片布局方式
- (void)setTitleImageLayoutStyle:(SLButtonStyle)titleImageStyle space:(CGFloat)space;
@end

NS_ASSUME_NONNULL_END
