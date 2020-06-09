//
//  SLGridView.m
//
//  Created by wsl on 2019/10/27.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLGridView.h"

/// 网格遮罩层  网格透明层
@interface SLGridMaskLayer : CAShapeLayer
/// 遮罩颜色
@property (nonatomic, assign) CGColorRef maskColor;
/// 遮罩区域的非交集区域
@property (nonatomic, setter=setMaskRect:) CGRect maskRect;
@end
@implementation SLGridMaskLayer
//@synthesize maskColor = _maskColor;
#pragma mark - Override
- (instancetype)init {
    self = [super init];
    if (self) {
        self.contentsScale = [[UIScreen mainScreen] scale];
    }
    return self;
}
- (void)setMaskColor:(CGColorRef)maskColor {
    self.fillColor = maskColor;
    // 填充规则  maskRect和bounds的非交集
    self.fillRule = kCAFillRuleEvenOdd;
}
- (void)setMaskRect:(CGRect)maskRect {
    [self setMaskRect:maskRect animated:NO];
}
- (CGColorRef)maskColor {
    return self.fillColor;
}
- (void)setMaskRect:(CGRect)maskRect animated:(BOOL)animated {
    CGMutablePathRef mPath = CGPathCreateMutable();
    CGPathAddRect(mPath, NULL, self.bounds);
    CGPathAddRect(mPath, NULL, maskRect);
    [self removeAnimationForKey:@"SL_maskLayer_opacityAnimate"];
    if (animated) {
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animate.duration = 0.25f;
        animate.fromValue = @(0.0);
        animate.toValue = @(1.0);
        self.path = mPath;
        [self addAnimation:animate forKey:@"SL_maskLayer_opacityAnimate"];
    } else {
        self.path = mPath;
    }
}
@end

/// 网格层
@interface SLGridLayer : CAShapeLayer
///网格区域 默认CGRectZero
@property (nonatomic, assign) CGRect gridRect;
///网格颜色  默认黑色
@property (nonatomic, strong) UIColor *gridColor;
/// 背景  默认透明
@property (nonatomic, strong) UIColor *bgColor;
@end
@implementation SLGridLayer
- (instancetype)init {
    self = [super init];
    if (self) {
        self.contentsScale = [[UIScreen mainScreen] scale];
        _bgColor = [UIColor clearColor];
        _gridColor = [UIColor blackColor];
        self.shadowColor = [UIColor blackColor].CGColor;
        self.shadowRadius = 3.f;
        self.shadowOffset = CGSizeZero;
        self.shadowOpacity = .5f;
    }
    return self;
}
- (void)setGridRect:(CGRect)gridRect {
    [self setGridRect:gridRect animated:NO];
}
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated {
    if (!CGRectEqualToRect(_gridRect, gridRect)) {
        _gridRect = gridRect;
        CGPathRef path = [self drawGrid];
        if (animated) {
            CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"path"];
            animate.duration = 0.25f;
            animate.fromValue = (__bridge id _Nullable)(self.path);
            animate.toValue = (__bridge id _Nullable)(path);
            //            animate.fillMode=kCAFillModeForwards;
            [self addAnimation:animate forKey:@"lf_gridLayer_contentsRectAnimate"];
        }
        self.path = path;
    }
}
- (CGPathRef)drawGrid {
    self.fillColor = self.bgColor.CGColor;
    self.strokeColor = self.gridColor.CGColor;
    
    CGRect rct = self.gridRect;
    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    CGFloat dW = 0;
    for(int i=0;i<4;++i){ /** 竖线 */
        [path moveToPoint:CGPointMake(rct.origin.x+dW, rct.origin.y)];
        [path addLineToPoint:CGPointMake(rct.origin.x+dW, rct.origin.y+rct.size.height)];
        dW += _gridRect.size.width/3;
    }
    dW = 0;
    for(int i=0;i<4;++i){ /** 横线 */
        [path moveToPoint:CGPointMake(rct.origin.x, rct.origin.y+dW)];
        [path addLineToPoint:CGPointMake(rct.origin.x+rct.size.width, rct.origin.y+dW)];
        dW += rct.size.height/3;
    }
    
    /** 偏移量 */
    CGFloat offset = 1;
    /** 长度 */
    CGFloat cornerlength = 15.f;
    CGRect newRct = CGRectInset(rct, -offset, -offset);
    
    /** 左上角 */
    [path moveToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMinY(newRct)+cornerlength)];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMinY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct)+cornerlength , CGRectGetMinY(newRct))];
    /** 右上角 */
    [path moveToPoint:CGPointMake(CGRectGetMaxX(newRct)-cornerlength , CGRectGetMinY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMinY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMinY(newRct)+cornerlength)];
    /** 右下角 */
    [path moveToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMaxY(newRct)-cornerlength)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMaxY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct)-cornerlength , CGRectGetMaxY(newRct))];
    /** 左下角 */
    [path moveToPoint:CGPointMake(CGRectGetMinX(newRct)+cornerlength , CGRectGetMaxY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMaxY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMaxY(newRct)-cornerlength)];
    return path.CGPath;
}
@end

@class SLResizeControl;
@protocol SLResizeControlDelegate <NSObject>
/// 开始
- (void)resizeConrolDidBeginResizing:(SLResizeControl *)resizeConrol;
- (void)resizeConrolDidResizing:(SLResizeControl *)resizeConrol;
- (void)resizeConrolDidEndResizing:(SLResizeControl *)resizeConrol;
@end
/// 网格四边和四角控制大小的透明视图
@interface SLResizeControl : UIView
@property (weak, nonatomic) id<SLResizeControlDelegate> delegate;
@property (nonatomic, readwrite) CGPoint translation;
@property (nonatomic) CGPoint startPoint; 
@property (nonatomic, getter=isEnabled) BOOL enabled; //手势是否可用
@property (nonatomic, strong) UIPanGestureRecognizer *gestureRecognizer;
@end
@implementation SLResizeControl
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:gestureRecognizer];
        _gestureRecognizer = gestureRecognizer;
    }
    return self;
}
- (BOOL)isEnabled {
    return _gestureRecognizer.isEnabled;
}
- (void)setEnabled:(BOOL)enabled {
    _gestureRecognizer.enabled = enabled;
}
- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint translationInView = [gestureRecognizer translationInView:self.superview];
        self.startPoint = CGPointMake(roundf(translationInView.x), translationInView.y);
        if ([self.delegate respondsToSelector:@selector(resizeConrolDidBeginResizing:)]) {
            [self.delegate resizeConrolDidBeginResizing:self];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gestureRecognizer translationInView:self.superview];
        self.translation = CGPointMake(roundf(self.startPoint.x + translation.x),
                                       roundf(self.startPoint.y + translation.y));
        
        if ([self.delegate respondsToSelector:@selector(resizeConrolDidResizing:)]) {
            [self.delegate resizeConrolDidResizing:self];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        if ([self.delegate respondsToSelector:@selector(resizeConrolDidEndResizing:)]) {
            [self.delegate resizeConrolDidEndResizing:self];
        }
    }
}
@end

// 网格四角和边的 可控范围
const CGFloat kSLControlWidth = 30.f;
//网格视图
@interface SLGridView ()<SLResizeControlDelegate>
@property (nonatomic, strong) SLGridLayer *gridLayer; //网格层
@property (nonatomic, strong) SLGridMaskLayer *gridMaskLayer; // 半透明遮罩层
@property (nonatomic, assign) CGRect initialRect; //高亮网格框的初始区域
//四个角
@property (nonatomic, strong) SLResizeControl *topLeftCornerView;
@property (nonatomic, strong) SLResizeControl *topRightCornerView;
@property (nonatomic, strong) SLResizeControl *bottomLeftCornerView;
@property (nonatomic, strong) SLResizeControl *bottomRightCornerView;
//四条边
@property (nonatomic, strong) SLResizeControl *topEdgeView;
@property (nonatomic, strong) SLResizeControl *leftEdgeView;
@property (nonatomic, strong) SLResizeControl *bottomEdgeView;
@property (nonatomic, strong) SLResizeControl *rightEdgeView;
@end

@implementation SLGridView
#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.gridLayer.frame = self.bounds;
    self.gridMaskLayer.frame = self.bounds;
    [self updateResizeControlFrame];
}
// 事件传给下层的缩放视图SLZoomView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (self == view) {
        return nil;
    }
    [self enableCornerViewUserInteraction:view];
    return view;
}
// 设置控制网格大小视图的用户交互 防止手指同时控制多个按钮
- (void)enableCornerViewUserInteraction:(UIView *)view {
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[SLResizeControl class]]) {
            if (view) {
                if (control == view) {
                    control.userInteractionEnabled = YES;
                } else {
                    control.userInteractionEnabled = NO;
                }
            } else {
                control.userInteractionEnabled = YES;
            }
        }
    }
}
#pragma mark - UI
- (void)setupUI {
    self.minGridSize = CGSizeMake(60, 60);
    self.maxGridRect = CGRectInset(self.bounds, 20, 20);
    self.originalGridSize = self.gridRect.size;
    self.showMaskLayer = YES;
    
    [self.layer addSublayer:self.gridMaskLayer];
    [self.layer addSublayer:self.gridLayer];
    
    self.topLeftCornerView = [self createResizeControl];
    self.topRightCornerView = [self createResizeControl];
    self.bottomLeftCornerView = [self createResizeControl];
    self.bottomRightCornerView = [self createResizeControl];
    
    self.topEdgeView = [self createResizeControl];
    self.leftEdgeView = [self createResizeControl];
    self.bottomEdgeView = [self createResizeControl];
    self.rightEdgeView = [self createResizeControl];
}
- (SLResizeControl *)createResizeControl {
    SLResizeControl *control = [[SLResizeControl alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake(kSLControlWidth, kSLControlWidth)}];
    control.delegate = self;
    //    control.backgroundColor = [UIColor redColor];
    [self addSubview:control];
    control.userInteractionEnabled = YES;
    return control;
}

#pragma mark - Getter
- (SLGridMaskLayer *)gridMaskLayer {
    if (!_gridMaskLayer) {
        _gridMaskLayer = [[SLGridMaskLayer alloc] init];
        _gridMaskLayer.frame = self.bounds;
        _gridMaskLayer.maskColor = [UIColor colorWithWhite:.0f alpha:0.6f].CGColor;
    }
    return _gridMaskLayer;
}
- (SLGridLayer *)gridLayer {
    if (!_gridLayer) {
        _gridLayer = [[SLGridLayer alloc] init];
        _gridLayer.frame = self.bounds;
        _gridLayer.lineWidth = 2.f;
        _gridLayer.gridColor = [UIColor whiteColor];
        _gridLayer.gridRect = CGRectInset(self.bounds, 20, 20);
    }
    return _gridLayer;
}
#pragma mark - Setter
- (void)setGridRect:(CGRect)gridRect {
    [self setGridRect:gridRect maskLayer:YES];
}
- (void)setShowMaskLayer:(BOOL)showMaskLayer {
    if (_showMaskLayer != showMaskLayer) {
        _showMaskLayer = showMaskLayer;
        if (showMaskLayer) {
            /** 还原遮罩 */
            [self.gridMaskLayer setMaskRect:self.gridRect animated:YES];
        } else {
            /** 扩大遮罩范围 */
            [self.gridMaskLayer setMaskRect:self.gridMaskLayer.bounds animated:YES];
        }
    }
    /** 简单粗暴的禁用拖动事件 */
    self.userInteractionEnabled = showMaskLayer;
}

#pragma mark - HelpMethods
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer {
    [self setGridRect:gridRect maskLayer:isMaskLayer animated:NO];
}
//- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated {
//    [self setGridRect:gridRect maskLayer:NO animated:animated];
//}
// 更新网格区域和遮罩状态
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer  animated:(BOOL)animated {
    if (!CGRectEqualToRect(_gridRect, gridRect)) {
        _gridRect = gridRect;
        [self setNeedsLayout];
        [self.gridLayer setGridRect:gridRect animated:animated];
        if (isMaskLayer) {
            [self.gridMaskLayer setMaskRect:gridRect animated:YES];
        }
    }
}
// 更新控制调整网格大小的四个角和边的frame
- (void)updateResizeControlFrame {
    CGRect rect = self.gridRect;
    self.topLeftCornerView.frame = (CGRect){CGRectGetMinX(rect) - CGRectGetWidth(self.topLeftCornerView.bounds) / 2, CGRectGetMinY(rect) - CGRectGetHeight(self.topLeftCornerView.bounds) / 2, self.topLeftCornerView.bounds.size};
    self.topRightCornerView.frame = (CGRect){CGRectGetMaxX(rect) - CGRectGetWidth(self.topRightCornerView.bounds) / 2, CGRectGetMinY(rect) - CGRectGetHeight(self.topRightCornerView.bounds) / 2, self.topRightCornerView.bounds.size};
    self.bottomLeftCornerView.frame = (CGRect){CGRectGetMinX(rect) - CGRectGetWidth(self.bottomLeftCornerView.bounds) / 2, CGRectGetMaxY(rect) - CGRectGetHeight(self.bottomLeftCornerView.bounds) / 2, self.bottomLeftCornerView.bounds.size};
    self.bottomRightCornerView.frame = (CGRect){CGRectGetMaxX(rect) - CGRectGetWidth(self.bottomRightCornerView.bounds) / 2, CGRectGetMaxY(rect) - CGRectGetHeight(self.bottomRightCornerView.bounds) / 2, self.bottomRightCornerView.bounds.size};
    
    self.topEdgeView.frame = (CGRect){CGRectGetMaxX(self.topLeftCornerView.frame), CGRectGetMinY(rect) - CGRectGetHeight(self.topEdgeView.frame) / 2, CGRectGetMinX(self.topRightCornerView.frame) - CGRectGetMaxX(self.topLeftCornerView.frame), CGRectGetHeight(self.topEdgeView.bounds)};
    self.leftEdgeView.frame = (CGRect){CGRectGetMinX(rect) - CGRectGetWidth(self.leftEdgeView.frame) / 2, CGRectGetMaxY(self.topLeftCornerView.frame), CGRectGetWidth(self.leftEdgeView.bounds), CGRectGetMinY(self.bottomLeftCornerView.frame) - CGRectGetMaxY(self.topLeftCornerView.frame)};
    self.bottomEdgeView.frame = (CGRect){CGRectGetMaxX(self.bottomLeftCornerView.frame), CGRectGetMinY(self.bottomLeftCornerView.frame), CGRectGetMinX(self.bottomRightCornerView.frame) - CGRectGetMaxX(self.bottomLeftCornerView.frame), CGRectGetHeight(self.bottomEdgeView.bounds)};
    self.rightEdgeView.frame = (CGRect){CGRectGetMaxX(rect) - CGRectGetWidth(self.rightEdgeView.bounds) / 2, CGRectGetMaxY(self.topRightCornerView.frame), CGRectGetWidth(self.rightEdgeView.bounds), CGRectGetMinY(self.bottomRightCornerView.frame) - CGRectGetMaxY(self.topRightCornerView.frame)};
}

//返回正在调整网格大小时的网格区域
- (CGRect)cropRectMakeWithResizeControlView:(SLResizeControl *)resizeControlView {
    CGRect rect = self.gridRect;
    if (resizeControlView == self.topEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                          CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                          CGRectGetWidth(self.initialRect),
                          CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);
    } else if (resizeControlView == self.leftEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetMinY(self.initialRect) ,
                          CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect));
    } else if (resizeControlView == self.bottomEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) ,
                          CGRectGetMinY(self.initialRect),
                          CGRectGetWidth(self.initialRect) ,
                          CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);
    } else if (resizeControlView == self.rightEdgeView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                          CGRectGetMinY(self.initialRect),
                          CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect));
    } else if (resizeControlView == self.topLeftCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                          CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);
        
    } else if (resizeControlView == self.topRightCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                          CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                          CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);
        
    } else if (resizeControlView == self.bottomLeftCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetMinY(self.initialRect),
                          CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);
        
    } else if (resizeControlView == self.bottomRightCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                          CGRectGetMinY(self.initialRect),
                          CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);
        
    }
    
    /** 限制x/y 超出左上角 最大限度 */
    if (ceil(rect.origin.x) < ceil(CGRectGetMinX(_maxGridRect))) {
        rect.origin.x = _maxGridRect.origin.x;
        rect.size.width = CGRectGetMaxX(self.initialRect)-rect.origin.x;
    }
    if (ceil(rect.origin.y) < ceil(CGRectGetMinY(_maxGridRect))) {
        rect.origin.y = _maxGridRect.origin.y;
        rect.size.height = CGRectGetMaxY(self.initialRect)-rect.origin.y;
    }
    /** 限制宽度／高度 超出 最大限度 */
    if (ceil(rect.origin.x+rect.size.width) > ceil(CGRectGetMaxX(_maxGridRect))) {
        rect.size.width = CGRectGetMaxX(_maxGridRect) - CGRectGetMinX(rect);
    }
    if (ceil(rect.origin.y+rect.size.height) > ceil(CGRectGetMaxY(_maxGridRect))) {
        rect.size.height = CGRectGetMaxY(_maxGridRect) - CGRectGetMinY(rect);
    }
    /** 限制宽度／高度 小于 最小限度 */
    if (ceil(rect.size.width) <= ceil(_minGridSize.width)) {
        /** 左上、左、左下 处理x最小值 */
        if (resizeControlView == self.topLeftCornerView || resizeControlView == self.leftEdgeView || resizeControlView == self.bottomLeftCornerView) {
            rect.origin.x = CGRectGetMaxX(self.initialRect) - _minGridSize.width;
        }
        rect.size.width = _minGridSize.width;
    }
    if (ceil(rect.size.height) <= ceil(_minGridSize.height)) {
        /** 左上、上、右上 处理y最小值底部 */
        if (resizeControlView == self.topLeftCornerView || resizeControlView == self.topEdgeView || resizeControlView == self.topRightCornerView) {
            rect.origin.y = CGRectGetMaxY(self.initialRect) - _minGridSize.height;
        }
        rect.size.height = _minGridSize.height;
    }
    return rect;
}

#pragma mark - SLResizeControlDelegate
- (void)resizeConrolDidBeginResizing:(SLResizeControl *)resizeConrol {
    self.initialRect = self.gridRect;
    _dragging = YES;
    self.showMaskLayer = NO;
    if ([self.delegate respondsToSelector:@selector(gridViewDidBeginResizing:)]) {
        [self.delegate gridViewDidBeginResizing:self];
    }
}
- (void)resizeConrolDidResizing:(SLResizeControl *)resizeConrol {
    CGRect gridRect = [self cropRectMakeWithResizeControlView:resizeConrol];
    [self setGridRect:gridRect maskLayer:NO];
    if ([self.delegate respondsToSelector:@selector(gridViewDidResizing:)]) {
        [self.delegate gridViewDidResizing:self];
    }
}
- (void)resizeConrolDidEndResizing:(SLResizeControl *)resizeConrol {
    [self enableCornerViewUserInteraction:nil];
    _dragging = NO;
    self.showMaskLayer = YES;
    if ([self.delegate respondsToSelector:@selector(gridViewDidEndResizing:)]) {
        [self.delegate gridViewDidEndResizing:self];
    }
}

@end
