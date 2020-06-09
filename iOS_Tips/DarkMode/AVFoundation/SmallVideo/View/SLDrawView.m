//
//  SLDrawView.m
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLDrawView.h"

@interface SLDrawBezierPath : UIBezierPath
@property (nonatomic, strong) UIColor *color; //曲线颜色
@end
@implementation SLDrawBezierPath
@end

@interface SLDrawView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}
/// 笔画
@property (nonatomic, strong) NSMutableArray <SLDrawBezierPath *>*lineArray;
/// 图层
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*layerArray;
/// 删除的笔画
@property (nonatomic, strong) NSMutableArray <SLDrawBezierPath *>*deleteLineArray;
/// 删除的图层
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*deleteLayerArray;
@end

@implementation SLDrawView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _lineWidth = 5.f;
        _lineColor = [UIColor blackColor];
        _layerArray = [NSMutableArray array];
        _lineArray = [NSMutableArray array];
        _deleteLineArray = [NSMutableArray array];
        _deleteLayerArray = [NSMutableArray array];
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        self.exclusiveTouch = YES;
    }
    return self;
}
//开始绘画
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([event allTouches].count == 1) {
        _isWork = NO;
        _isBegan = YES;
        //1、每次触摸的时候都应该去创建一条贝塞尔曲线
        SLDrawBezierPath *path = [SLDrawBezierPath new];
        //2、移动画笔
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        //设置线宽
        path.lineWidth = self.lineWidth;
        path.lineCapStyle = kCGLineCapRound; //线条拐角
        path.lineJoinStyle = kCGLineJoinRound; //终点处理
        [path moveToPoint:point];
        //设置颜色
        path.color = self.lineColor;//保存线条当前颜色
        [self.lineArray addObject:path];
        
        CAShapeLayer *slayer = [self createShapeLayer:path];
        [self.layer addSublayer:slayer];
        [self.layerArray addObject:slayer];
    }
    [super touchesBegan:touches withEvent:event];
}
//绘画中
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (_isBegan || _isWork) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        SLDrawBezierPath *path = self.lineArray.lastObject;
        if (!CGPointEqualToPoint(path.currentPoint, point)) {
            if (_isBegan && self.drawBegan) self.drawBegan();
            _isBegan = NO;
            _isWork = YES;
            [path addLineToPoint:point];
            CAShapeLayer *slayer = self.layerArray.lastObject;
            slayer.path = path.CGPath;
        }
    }
    [super touchesMoved:touches withEvent:event];
}
//结束绘画
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if (_isWork) {
        if (self.drawEnded) self.drawEnded();
    } else {
        if ((_isBegan)) {
            [self goBack];
        }
    }
    _isBegan = NO;
    _isWork = NO;
    [super touchesEnded:touches withEvent:event];
}
//取消绘画
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isWork) {
        if (self.drawEnded) self.drawEnded();
    } else {
        if ((_isBegan)) {
            [self goBack];
        }
    }
    _isBegan = NO;
    _isWork = NO;
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark - Help Methods
//创建线条图层
- (CAShapeLayer *)createShapeLayer:(SLDrawBezierPath *)path {
    /** 1、渲染快速。CAShapeLayer使用了硬件加速，绘制同一图形会比用Core Graphics快很多。Core Graphics实现示例： https://github.com/wsl2ls/Draw.git
     2、高效使用内存。一个CAShapeLayer不需要像普通CALayer一样创建一个寄宿图形，所以无论有多大，都不会占用太多的内存。
     3、不会被图层边界剪裁掉。
     4、不会出现像素化。 */
    CAShapeLayer *slayer = [CAShapeLayer layer];
    slayer.path = path.CGPath;
    slayer.backgroundColor = [UIColor clearColor].CGColor;
    slayer.fillColor = [UIColor clearColor].CGColor;
    slayer.lineCap = kCALineCapRound;
    slayer.lineJoin = kCALineJoinRound;
    slayer.strokeColor = path.color.CGColor;
    slayer.lineWidth = path.lineWidth;
    return slayer;
}

#pragma mark - Getter
- (BOOL)isDrawing {
    return _isWork;
}
- (BOOL)canForward {
    return self.deleteLineArray.count;
}
- (BOOL)canBack {
    return self.lineArray.count;
}
#pragma mark - Event Handle
//前进
- (void)goForward {
    if ([self canForward]) {
        //添加刚删除的线条
        [self.layer addSublayer:self.deleteLayerArray.lastObject];
        [self.lineArray addObject:self.deleteLineArray.lastObject];
        [self.layerArray addObject:self.deleteLayerArray.lastObject];
        //从删除池中除去
        [self.deleteLayerArray removeLastObject];
        [self.deleteLineArray removeLastObject];
    }
}
//返回
- (void)goBack {
    if ([self canBack]) {
        //保存上一步删除的线条
        [self.deleteLineArray addObject:self.lineArray.lastObject];
        [self.deleteLayerArray addObject:self.layerArray.lastObject];
        //删除上一步
        [self.layerArray.lastObject removeFromSuperlayer];
        [self.layerArray removeLastObject];
        [self.lineArray removeLastObject];
    }
}
- (void)clear {
    [self.layerArray removeAllObjects];
    [self.lineArray removeAllObjects];
    [self.deleteLayerArray removeAllObjects];
    [self.deleteLineArray removeAllObjects];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}
#pragma mark  - 数据
- (NSDictionary *)data {
    if (self.lineArray.count) {
        return @{@"kSLDrawViewData":[self.lineArray copy]};
    }
    return nil;
}
- (void)setData:(NSDictionary *)data {
    NSArray *lineArray = data[@"kSLDrawViewData"];
    if (lineArray.count) {
        for (SLDrawBezierPath *path in lineArray) {
            CAShapeLayer *slayer = [self createShapeLayer:path];
            [self.layer addSublayer:slayer];
            [self.layerArray addObject:slayer];
        }
        [self.lineArray addObjectsFromArray:lineArray];
    }
}
@end
