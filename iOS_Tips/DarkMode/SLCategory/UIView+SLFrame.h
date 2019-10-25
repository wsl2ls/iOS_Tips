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
@property (assign, nonatomic) CGFloat sl_x;
@property (assign, nonatomic) CGFloat sl_y;
@property (assign, nonatomic) CGFloat sl_w;
@property (assign, nonatomic) CGFloat sl_h;
@property (assign, nonatomic) CGSize sl_size;
@property (nonatomic, assign) CGFloat sl_centerX;
@property (nonatomic, assign) CGFloat sl_centerY;
@property (assign, nonatomic) CGPoint sl_origin;

@end

NS_ASSUME_NONNULL_END
