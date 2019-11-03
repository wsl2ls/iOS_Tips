//
//  SLMosaicView.m
//  DarkMode
//
//  Created by wsl on 2019/10/25.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLMosaicView.h"

#define radiansToDegrees(x) (180.0 * x / M_PI)
///两点之间的角度
CGFloat angleBetweenPoints(CGPoint startPoint, CGPoint endPoint) {
    CGPoint Xpoint = CGPointMake(startPoint.x + 100, startPoint.y);
    CGFloat a = endPoint.x - startPoint.x;
    CGFloat b = endPoint.y - startPoint.y;
    CGFloat c = Xpoint.x - startPoint.x;
    CGFloat d = Xpoint.y - startPoint.y;
    CGFloat rads = acos(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    if (startPoint.y>endPoint.y) {
        rads = -rads;
    }
    return rads;
}
///直线之间的夹角
CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End) {
    CGFloat a = line1End.x - line1Start.x;
    CGFloat b = line1End.y - line1Start.y;
    CGFloat c = line2End.x - line2Start.x;
    CGFloat d = line2End.y - line2Start.y;
    CGFloat rads = acos(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    return radiansToDegrees(rads);
}
/// 马赛克点元素
@interface SLMosaicPointElement : NSObject
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, copy) NSString *imageName;
@end
@implementation SLMosaicPointElement
@end
/// 马赛克线条 遮罩层  线
@interface SLMosaicLineLayer : CALayer
@property (nonatomic, strong) NSMutableArray <SLMosaicPointElement *>*elementArray;
@end
@implementation SLMosaicLineLayer
- (instancetype)init {
    self = [super init];
    if (self) {
        self.contentsScale = [[UIScreen mainScreen] scale];
        self.backgroundColor = [UIColor clearColor].CGColor;
        _elementArray = [@[] mutableCopy];
    }
    return self;
}
- (void)drawInContext:(CGContextRef)context {
    UIGraphicsPushContext( context );
    [[UIColor clearColor] setFill];
    UIRectFill(self.bounds);
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    for (NSInteger i=0; i<self.elementArray.count; i++) {
        SLMosaicPointElement *blur = self.elementArray[i];
        CGRect rect = blur.rect;
        if (blur.imageName) {
            UIImage *image = [UIImage imageNamed:blur.imageName];
            if (image) {
                /** 创建颜色图片 */
                CGColorSpaceRef colorRef = CGColorSpaceCreateDeviceRGB();
                CGContextRef contextRef = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, image.size.width*4, colorRef, kCGImageAlphaPremultipliedFirst);
                
                CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
                CGContextClipToMask(contextRef, imageRect, image.CGImage);
                CGContextSetFillColorWithColor(contextRef, (blur.color ? blur.color.CGColor : [UIColor clearColor].CGColor));
                CGContextFillRect(contextRef,imageRect);
                
                /** 生成图片 */
                CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
                CGContextDrawImage(context, rect, imageRef);
                
                CGImageRelease(imageRef);
                CGContextRelease(contextRef);
                CGColorSpaceRelease(colorRef);
            }
        } else {
            // 设置描边颜色
            //            CGContextSetStrokeColorWithColor(context, (blur.color ? blur.color.CGColor : [UIColor clearColor].CGColor));
            // 模糊矩形可以用到，用于填充矩形
            CGContextSetFillColorWithColor(context, (blur.color ? blur.color.CGColor : [UIColor clearColor].CGColor));
            // 模糊矩形  填充 画完一个小正方形
            CGContextFillRect(context, rect);
        }
    }
    UIGraphicsPopContext();
}

@end

NSString *const kLFSplashViewData = @"LFSplashViewData";
NSString *const kLFSplashViewData_layerArray = @"LFSplashViewData_layerArray";
NSString *const kLFSplashViewData_frameArray = @"LFSplashViewData_frameArray";
/// 马赛克画板
@interface SLMosaicView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}
/** 图层 */
@property (nonatomic, strong) NSMutableArray <SLMosaicLineLayer *>*layerArray;
/** 已显示坐标 */
@property (nonatomic, strong) NSMutableArray <NSValue *>*frameArray;

//@property (nonatomic, assign) BOOL isErase;
@end

@implementation SLMosaicView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

#pragma mark - Help Methods
//初始化
- (void)customInit {
    _squareWidth = 15.f;
    _paintSize = CGSizeMake(50, 50);
    _mosaicType = SLMosaicTypeSquare;
    _layerArray = [@[] mutableCopy];
    _frameArray = [@[] mutableCopy];
}
//返回马赛克元素的位置
- (CGPoint)divideMosaicPoint:(CGPoint)point {
    CGFloat scope = self.squareWidth;
    int x = point.x/scope;
    int y = point.y/scope;
    return CGPointMake(x*scope, y*scope);
}
//马赛克元素在设备上的区域
- (NSArray <NSValue *>*)divideMosaicRect:(CGRect)rect {
    CGFloat scope = self.squareWidth;
    
    NSMutableArray *array = @[].mutableCopy;
    
    if (CGRectEqualToRect(CGRectZero, rect)) {
        return array;
    }
    
    CGFloat minX = CGRectGetMinX(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    /** 左上角 */
    CGPoint leftTop = [self divideMosaicPoint:CGPointMake(minX, minY)];
    /** 右下角 */
    CGPoint rightBoom = [self divideMosaicPoint:CGPointMake(maxX, maxY)];
    
    NSInteger countX = (rightBoom.x - leftTop.x)/scope;
    NSInteger countY = (rightBoom.y - leftTop.y)/scope;
    
    for (NSInteger i = 0; i < countX; i++) {
        for (NSInteger j = 0; j < countY;  j++) {
            CGPoint point = CGPointMake(leftTop.x + i * scope, leftTop.y + j * scope);
            NSValue *value = [NSValue valueWithCGPoint:point];
            [array addObject:value];
        }
    }
    return array;
}
#pragma mark - 绘画
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (touches.allObjects.count == 1) {
        _isWork = NO;
        _isBegan = YES;
        //1、触摸坐标
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        //2、创建LFSplashBlur
        if (self.mosaicType == SLMosaicTypeSquare) {
            CGPoint mosaicPoint = [self divideMosaicPoint:point];
            NSValue *value = [NSValue valueWithCGPoint:mosaicPoint];
            if (![self.frameArray containsObject:value]) {
                [self.frameArray addObject:value];
                
                SLMosaicPointElement *blur = [SLMosaicPointElement new];
                blur.rect = CGRectMake(mosaicPoint.x, mosaicPoint.y, self.squareWidth, self.squareWidth);
                blur.color = self.brushColor ? self.brushColor(blur.rect.origin) : nil;
                
                SLMosaicLineLayer *layer = [SLMosaicLineLayer layer];
                layer.frame = self.bounds;
                [layer.elementArray addObject:blur];
                
                [self.layer addSublayer:layer];
                [self.layerArray addObject:layer];
            } else {
                SLMosaicLineLayer *layer = [SLMosaicLineLayer layer];
                layer.frame = self.bounds;
                
                [self.layer addSublayer:layer];
                [self.layerArray addObject:layer];
            }
        } else if (self.mosaicType == SLMosaicTypePaintbrush) {
            SLMosaicPointElement  *blur = [ SLMosaicPointElement  new];
            blur.rect = CGRectMake(point.x-self.paintSize.width/2, point.y-self.paintSize.height/2, self.paintSize.width, self.paintSize.height);
            blur.imageName = @"EditMosaicBrush.png";
            blur.color = self.brushColor ? self.brushColor(blur.rect.origin) : nil;
            SLMosaicLineLayer *layer = [SLMosaicLineLayer layer];
            layer.frame = self.bounds;
            [layer.elementArray addObject:blur];
            
            [self.layer addSublayer:layer];
            [self.layerArray addObject:layer];
        }
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isBegan || _isWork) {
        //1、触摸坐标
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        
        /** 获取上一个对象坐标判断是否重叠 */
        SLMosaicLineLayer *layer = self.layerArray.lastObject;
        SLMosaicPointElement *prevBlur = layer.elementArray.lastObject;
        
        if (self.mosaicType == SLMosaicTypeSquare) {
            CGPoint mosaicPoint = [self divideMosaicPoint:point];
            NSValue *value = [NSValue valueWithCGPoint:mosaicPoint];
            if (![self.frameArray containsObject:value]) {
                if (_isBegan && self.brushBegan) self.brushBegan();
                _isWork = YES;
                _isBegan = NO;
                [self.frameArray addObject:value];
                //2、创建LFSplashBlur
                SLMosaicPointElement *blur = [SLMosaicPointElement new];
                blur.rect = CGRectMake(mosaicPoint.x, mosaicPoint.y, self.squareWidth, self.squareWidth);
                blur.color = self.brushColor ? self.brushColor(blur.rect.origin) : nil;
                
                [layer.elementArray addObject:blur];
                [layer setNeedsDisplay];
            }
        } else if (self.mosaicType == SLMosaicTypePaintbrush) {
            /** 限制绘画的间隙 */
            if (CGRectContainsPoint(prevBlur.rect, point) == NO) {
                
                if (_isBegan && self.brushBegan) self.brushBegan();
                _isWork = YES;
                _isBegan = NO;
                
                //2、创建LFSplashBlur
                SLMosaicPointElement *blur = [SLMosaicPointElement new];
                blur.imageName = @"EditMosaicBrush.png";
                blur.color = self.brushColor ? self.brushColor(point) : nil;
                /** 新增随机位置 */
                int x = self.paintSize.width + MIN(1, (int)(self.paintSize.width*0.4));
                float randomX = floorf(arc4random()%x) - x/2;
                blur.rect = CGRectMake(point.x-self.paintSize.width/2 + randomX, point.y-self.paintSize.height/2, self.paintSize.width, self.paintSize.height);
                
                [layer.elementArray addObject:blur];
                
                /** 新增额外对象 密集图片 */
                [layer setNeedsDisplay];
                
                /** 扩大范围 */
                CGRect paintRect = CGRectInset(blur.rect, -self.squareWidth, -self.squareWidth);
                [self.frameArray removeObjectsInArray:[self divideMosaicRect:paintRect]];
            }
        }
        
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isWork) {
        SLMosaicLineLayer *layer = self.layerArray.lastObject;
        if (layer.elementArray.count < 2) {
            [self goBack];
        } else {
            if (self.brushEnded) self.brushEnded();
        }
    } else {
        if ((_isBegan)) {
            [self goBack];
        }
    }
    _isBegan = NO;
    _isWork = NO;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isWork) {
        SLMosaicLineLayer *layer = self.layerArray.lastObject;
        if (layer.elementArray.count < 2) {
            [self goBack];
        } else {
            if (self.brushEnded) self.brushEnded();
        }
    } else {
        if ((_isBegan)) {
            [self goBack];
        }
    }
    _isBegan = NO;
    _isWork = NO;
    [super touchesCancelled:touches withEvent:event];
}

- (BOOL)isDrawing {
    return _isWork;
}

/// 是否可撤销
- (BOOL)canBack {
    return self.layerArray.count;
}
//撤销
- (void)goBack {
    if (!self.canBack) {
        return;
    }
    SLMosaicLineLayer *layer = self.layerArray.lastObject;
    if ([layer.elementArray.firstObject isMemberOfClass:[SLMosaicPointElement class]]) {
        for (SLMosaicPointElement *blur in layer.elementArray) {
            [self.frameArray removeObject:[NSValue valueWithCGPoint:blur.rect.origin]];
        }
    }
    [layer removeFromSuperlayer];
    [self.layerArray removeLastObject];
}
- (void)clear {
    [self.layerArray removeAllObjects];
    [self.frameArray removeAllObjects];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

#pragma mark  - 数据
- (NSDictionary *)data {
    if (self.layerArray.count) {
        NSMutableArray *lineArray = [@[] mutableCopy];
        for (SLMosaicLineLayer *layer in self.layerArray) {
            [lineArray addObject:layer.elementArray];
        }
        
        return @{kLFSplashViewData:@{
                         kLFSplashViewData_layerArray:[lineArray copy],
                         kLFSplashViewData_frameArray:[self.frameArray copy]
        }};
    }
    return nil;
}
- (void)setData:(NSDictionary *)data {
    NSDictionary *dataDict = data[kLFSplashViewData];
    NSArray *lineArray = dataDict[kLFSplashViewData_layerArray];
    for (NSArray *subLineArray in lineArray) {
        SLMosaicLineLayer *layer = [SLMosaicLineLayer layer];
        layer.frame = self.bounds;
        [layer.elementArray addObjectsFromArray:subLineArray];
        
        [self.layer addSublayer:layer];
        [self.layerArray addObject:layer];
        [layer setNeedsDisplay];
    }
    NSArray *frameArray = dataDict[kLFSplashViewData_frameArray];
    [self.frameArray addObjectsFromArray:frameArray];
}

@end
