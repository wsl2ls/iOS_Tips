//
//  UIView+SLFrame.m
//  DarkMode
//
//  Created by wsl on 2019/9/18.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "UIView+SLFrame.h"

@implementation UIView (SLFrame)

- (void)setSl_x:(CGFloat)sl_x {
    CGRect frame = self.frame;
    frame.origin.x = sl_x;
    self.frame = frame;
}
- (CGFloat)sl_x {
    return self.frame.origin.x;
}

- (void)setSl_y:(CGFloat)sl_y {
    CGRect frame = self.frame;
    frame.origin.y = sl_y;
    self.frame = frame;
}
- (CGFloat)sl_y {
    return self.frame.origin.y;
}

- (void)setSl_width:(CGFloat)sl_w {
    CGRect frame = self.frame;
    frame.size.width = sl_w;
    self.frame = frame;
}
- (CGFloat)sl_width {
    return self.frame.size.width;
}

- (void)setSl_height:(CGFloat)sl_h {
    CGRect frame = self.frame;
    frame.size.height = sl_h;
    self.frame = frame;
}
- (CGFloat)sl_height {
    return self.frame.size.height;
}

- (void)setSl_size:(CGSize)sl_size {
    CGRect frame = self.frame;
    frame.size = sl_size;
    self.frame = frame;
}
- (CGSize)sl_size {
    return self.frame.size;
}

- (void)setSl_centerX:(CGFloat)sl_centerX {
    CGPoint center = self.center;
    center.x = sl_centerX;
    self.center = center;
}
- (CGFloat)sl_centerX {
    return self.center.x;
}

- (void)setSl_centerY:(CGFloat)sl_centerY {
    CGPoint center = self.center;
    center.y = sl_centerY;
    self.center = center;
}
- (CGFloat)sl_centerY {
    return self.center.y;
}

- (void)setSl_origin:(CGPoint)sl_origin {
    CGRect frame = self.frame;
    frame.origin = sl_origin;
    self.frame = frame;
}
- (CGPoint)sl_origin {
    return self.frame.origin;
}

- (CGFloat)sl_left{
    return self.frame.origin.x;
}
- (void)setSl_left:(CGFloat)left{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

- (CGFloat)sl_right{
    return CGRectGetMaxX(self.frame);
}

-(void)setSl_right:(CGFloat)right{
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)sl_top{
    return self.frame.origin.y;
}

- (void)setSl_top:(CGFloat)top{
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

- (CGFloat)sl_bottom{
    return CGRectGetMaxY(self.frame);
}
- (void)setSl_bottom:(CGFloat)bottom{
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}


@end
