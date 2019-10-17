//
//  UIView+SLImage.m
//  DarkMode
//
//  Created by wsl on 2019/10/17.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "UIView+SLImage.h"

@implementation UIView (SLImage)

// 涂鸦图片
- (UIImage *)viewToImage:(CGRect)range{
    range = CGRectMake(range.origin.x*[UIScreen mainScreen].scale, range.origin.y*[UIScreen mainScreen].scale, range.size.width*[UIScreen mainScreen].scale, range.size.height*[UIScreen mainScreen].scale);
    UIView *graffitiView = self;
    if (graffitiView) {
        CGRect rect = graffitiView.frame;
        /** 参数取整，否则可能会出现1像素偏差 */
        /** 有小数部分才调整差值 */
#define lfme_export_fixDecimal(d) ((fmod(d, (int)d)) > 0.59f ? ((int)(d+0.5)*1.f) : (((fmod(d, (int)d)) < 0.59f && (fmod(d, (int)d)) > 0.1f) ? ((int)(d)*1.f+0.5f) : (int)(d)*1.f))
        rect.origin.x = lfme_export_fixDecimal(rect.origin.x);
        rect.origin.y = lfme_export_fixDecimal(rect.origin.y);
        rect.size.width = lfme_export_fixDecimal(rect.size.width);
        rect.size.height = lfme_export_fixDecimal(rect.size.height);
#undef lfme_export_fixDecimal
        CGSize size = rect.size;
        //1.开启上下文
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        //2.绘制图层
        [graffitiView.layer renderInContext: context];
        //3.从上下文中获取新图片
        UIImage *watermarkImage = UIGraphicsGetImageFromCurrentImageContext();
        //4.关闭图形上下文
        UIGraphicsEndImageContext();
        /** 缩放至视频大小 */
        UIGraphicsBeginImageContextWithOptions(range.size, NO, 1);
        [watermarkImage drawInRect:range];
        UIImage *generatedWatermarkImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return generatedWatermarkImage;
    }
    return nil;
}

@end
