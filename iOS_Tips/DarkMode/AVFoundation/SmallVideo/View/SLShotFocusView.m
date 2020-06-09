//
//  SLShotFocusView.m
//  DarkMode
//
//  Created by wsl on 2019/9/23.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLShotFocusView.h"

@interface SLShotFocusView ()
/** 遮罩 */
//@property (nonatomic, strong) CAShapeLayer *maskLayer;
/** 路径 */
@property (nonatomic, strong) UIBezierPath *borderPath;
@end

@implementation SLShotFocusView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 初始化遮罩
//        self.maskLayer = [CAShapeLayer layer];
        // 设置遮罩
//        [self.layer setMask:self.maskLayer];
        // 初始化路径
        self.borderPath = [UIBezierPath bezierPath];
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (instancetype)init{
    if (self = [super init]) {
        // 初始化遮罩
//        self.maskLayer = [CAShapeLayer layer];
        // 设置遮罩
//        [self.layer setMask:self.maskLayer];
        // 初始化路径
        self.borderPath = [UIBezierPath bezierPath];
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)drawRect:(CGRect)rect {
    // 遮罩层frame
//    self.maskLayer.frame = self.bounds;
    self.borderPath = [UIBezierPath bezierPathWithRect:self.bounds];
    self.borderPath.lineCapStyle = kCGLineCapButt;//线条拐角
    self.borderPath.lineWidth = 2.0;
    UIColor *color = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1];
    [color set];// 设置边框线条颜色
    
    //起点
    [self.borderPath moveToPoint:CGPointMake(rect.size.width/2.0, 0)];
    //连线 上
    [self.borderPath addLineToPoint:CGPointMake(rect.size.width/2.0, 0+8)];
    [self.borderPath moveToPoint:CGPointMake(0, rect.size.width/2.0)];
    //连线 左
    [self.borderPath addLineToPoint:CGPointMake(0+8, rect.size.width/2.0)];
    [self.borderPath moveToPoint:CGPointMake(rect.size.width/2.0, rect.size.height)];
    //连线 下
    [self.borderPath addLineToPoint:CGPointMake(rect.size.width/2.0, rect.size.height - 8)];
    [self.borderPath moveToPoint:CGPointMake(rect.size.width, rect.size.height/2.0)];
    //连线 右
    [self.borderPath addLineToPoint:CGPointMake(rect.size.width - 8, rect.size.height/2.0)];
    
    [self.borderPath stroke];
    // 将这个path赋值给maskLayer的path
//    self.maskLayer.path = self.borderPath.CGPath;
}
@end
