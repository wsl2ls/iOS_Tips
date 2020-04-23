//
//  UIButton+SLTitleImage.m
//
//
//  Created by wsl on 2020/4/22.
//  Copyright © 2020 ZGEBook. All rights reserved.
//

#import "UIButton+SLTitleImage.h"

@implementation UIButton (SLTitleImage)

/// 设置文本和图片的位置
- (void)sl_setTitleImageLayoutStyle:(SLTitleImageStyle)titleImageStyle space:(CGFloat)space {
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    switch (titleImageStyle) {
        case SLTitleImageStyleImageLeft:
            [self imageLeft:space];
            break;
        case SLTitleImageStyleImageRight:
            [self imageRight:space];
            break;
        case SLTitleImageStyleImageTop:
            [self imageTop:space];
            break;
        case SLTitleImageStyleImageBottom:
            [self imageBottom:space];
            break;
        default:
            break;
    }
}

- (void)imageLeft:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeZero];
    //偏移是相对于图片/文本的原位置  靠近各边偏移是-，远离各边偏移是+
    [self setImageEdgeInsets:UIEdgeInsetsMake(0, -space/2.0, 0, space/2.0)];
    [self setTitleEdgeInsets:UIEdgeInsetsMake(0, space/2.0, 0, -space/2.0)];
}

- (void)imageRight:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = self.titleLabel.frame.size;
    //偏移是相对于图片/文本的原位置  靠近各边偏移是-，远离各边偏移是+
    [self setImageEdgeInsets:UIEdgeInsetsMake(0, space/2.0 + titleSize.width, 0, -(space/2.0 + titleSize.width))];
    [self setTitleEdgeInsets:UIEdgeInsetsMake(0, -(space/2.0 + imageSize.width), 0, space/2.0 + imageSize.width)];
}

- (void)imageTop:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeZero];
    //偏移是相对于图片/文本的原位置  靠近各边偏移是-，远离各边偏移是+
    [self setImageEdgeInsets:UIEdgeInsetsMake(-(imageSize.height*0.5 + space*0.5), self.bounds.size.width/2.0- self.imageView.center.x, imageSize.height*0.5 + space*0.5, -(self.bounds.size.width/2.0- self.imageView.center.x))];
    [self setTitleEdgeInsets:UIEdgeInsetsMake(titleSize.height*0.5 + space*0.5, -imageSize.width*0.5, -(titleSize.height*0.5 + space*0.5), imageSize.width*0.5)];
}

- (void)imageBottom:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeZero];
    //偏移是相对于图片/文本的原位置  靠近各边偏移是-，远离各边偏移是+
    [self setImageEdgeInsets:UIEdgeInsetsMake((imageSize.height*0.5 + space*0.5), self.bounds.size.width/2.0 - self.imageView.center.x, -(imageSize.height*0.5 + space*0.5), -(self.bounds.size.width/2.0 - self.imageView.center.x))];
    [self setTitleEdgeInsets:UIEdgeInsetsMake(-(titleSize.height*0.5 + space*0.5), -imageSize.width*0.5, (titleSize.height*0.5 + space*0.5), imageSize.width*0.5)];
}


@end
