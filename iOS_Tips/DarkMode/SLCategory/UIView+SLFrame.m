//
//  UIView+SLFrame.m
//  DarkMode
//
//  Created by wsl on 2019/9/18.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "UIView+SLFrame.h"

@implementation UIView (SLFrame)

- (void)setSl_x:(CGFloat)sl_x
{
    CGRect frame = self.frame;
    frame.origin.x = sl_x;
    self.frame = frame;
}

- (CGFloat)sl_x
{
    return self.frame.origin.x;
}

- (void)setSl_y:(CGFloat)sl_y
{
    CGRect frame = self.frame;
    frame.origin.y = sl_y;
    self.frame = frame;
}

- (CGFloat)sl_y
{
    return self.frame.origin.y;
}

- (void)setSl_w:(CGFloat)sl_w
{
    CGRect frame = self.frame;
    frame.size.width = sl_w;
    self.frame = frame;
}

- (CGFloat)sl_w
{
    return self.frame.size.width;
}

- (void)setSl_h:(CGFloat)sl_h
{
    CGRect frame = self.frame;
    frame.size.height = sl_h;
    self.frame = frame;
}

- (CGFloat)sl_h
{
    return self.frame.size.height;
}

- (void)setSl_size:(CGSize)sl_size
{
    CGRect frame = self.frame;
    frame.size = sl_size;
    self.frame = frame;
}

- (CGSize)sl_size
{
    return self.frame.size;
}

- (void)setSl_origin:(CGPoint)sl_origin
{
    CGRect frame = self.frame;
    frame.origin = sl_origin;
    self.frame = frame;
}

- (CGPoint)sl_origin
{
    return self.frame.origin;
}

@end
