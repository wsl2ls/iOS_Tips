//
//  UIView+SLFrame.h
//  DarkMode
//
//  Created by wsl on 2019/9/18.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SLFrame)
@property (nonatomic, assign ) CGFloat sl_x;
@property (nonatomic, assign ) CGFloat sl_y;
@property (nonatomic, assign ) CGFloat sl_width;
@property (nonatomic, assign ) CGFloat sl_height;
@property (nonatomic, assign ) CGFloat sl_centerX;
@property (nonatomic, assign ) CGFloat sl_centerY;

@property (nonatomic, assign ) CGSize sl_size;
@property (nonatomic, assign ) CGPoint sl_origin;

@property (nonatomic, assign) CGFloat sl_left;
@property (nonatomic, assign) CGFloat sl_right;
@property (nonatomic, assign) CGFloat sl_top;
@property (nonatomic, assign) CGFloat sl_bottom;

@end

NS_ASSUME_NONNULL_END
