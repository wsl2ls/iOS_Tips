//
//  UIView+SLImage.h
//  DarkMode
//
//  Created by wsl on 2019/10/17.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 视图转换为Image
@interface UIView (SLImage)
/// 截取视图转Image
/// @param range 截图区域
- (UIImage *)sl_imageByViewInRect:(CGRect)range;
@end

NS_ASSUME_NONNULL_END
