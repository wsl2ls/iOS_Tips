//
//  SLScrollViewController.m
//  DarkMode
//
//  Created by wsl on 2020/5/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLScrollViewController.h"
#import "SLDynamicItem.h"

///继承于UIView， 自定义实现UIScrollView的效果
@interface  SLScrollView : UIView <UIGestureRecognizerDelegate, UIDynamicAnimatorDelegate>

/// 内容大小
@property (nonatomic, assign) CGSize contentSize;
/// 滑到顶部、底部最大弹性距离  默认88
@property(nonatomic, assign) CGFloat maxBounceDistance;


/*  UIKit 动力学/仿真物理学：https://blog.csdn.net/meiwenjie110/article/details/46771299
    iOS UIScrollView 动画的力学原理  https://mp.weixin.qq.com/s/5JSiTywD0r3_O7l2OxWZxw */
/// 动力装置  启动力
@property(nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
/// 惯性力    手指滑动松开后，scrollView借助于惯性力，以手指松开时的初速度以及设置的resistance动力减速度运动，直至停止
@property(nonatomic, weak) UIDynamicItemBehavior *inertialBehavior;
/// 吸附力   模拟UIScrollView滑到底部或顶部时的回弹效果
@property(nonatomic, weak) UIAttachmentBehavior *bounceBehavior;

@end
@implementation SLScrollView

#pragma mark - Override
- (instancetype)init {
    self = [super init];
    if (self) {
        [self initScrollView];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initScrollView];
    }
    return self;
}
// 滚动中单击可以停止滚动
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.dynamicAnimator removeAllBehaviors];
}
- (void)initScrollView {
    _maxBounceDistance = 100;
    self.userInteractionEnabled = YES;
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
}

#pragma mark - Help Methods
///是否滑到顶部
- (BOOL)isTop {
    if (self.bounds.origin.y <= 0) {
        return YES;
    }else {
        return NO;
    }
}
///是否滑达底部
- (BOOL)isBottom {
    if (fabs(self.bounds.origin.y) >= [self maxContentOffsetY]) {
        return YES;
    }else {
        return NO;
    }
}
/// 最大偏移量
- (CGFloat)maxContentOffsetY {
    return MAX(0, self.contentSize.height - self.sl_height);
}

#pragma mark - Event Handles
/// 拖拽手势，模拟UIScrollView滑动
- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            //开始拖动，移除之前所有的动力行为
            [self.dynamicAnimator removeAllBehaviors];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [recognizer translationInView:self];
            [self scrollViewsSetContentOffsetY:translation.y];
            [recognizer setTranslation:CGPointZero inView:self];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            
            // 这个是为了避免在拉到边缘时，以一个非常小的初速度松手不回弹的问题，惯性力的初始速度太小
            if (fabs([recognizer velocityInView:self].y) < 120) {
                if ([self isTop]) {
                    //顶部回弹
                    [self performBounceForScrollViewisAtTop:YES];
                } else if ([self isBottom]) {
                    //底部回弹
                    [self performBounceForScrollViewisAtTop:NO];
                }
                return;
            }
            
            //动力元素 力的操作对象
            SLDynamicItem *item = [[SLDynamicItem alloc] init];
            item.center = CGPointZero;
            __block CGFloat lastCenterY = 0;
            UIDynamicItemBehavior *inertialBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[item]];
            //给item添加初始线速度 手指松开时的速度
            [inertialBehavior addLinearVelocity:CGPointMake(0, -[recognizer velocityInView:self].y) forItem:item];
            //减速度  无速度阻尼
            inertialBehavior.resistance = 2;
            __weak typeof(self) weakSelf = self;
            inertialBehavior.action = ^{
                //惯性力 移动的距离
                [weakSelf scrollViewsSetContentOffsetY:lastCenterY - item.center.y];
                lastCenterY = item.center.y;
            };
            //注意，self.inertialBehavior 的修饰符是weak，惯性力结束停止之后，会释放inertialBehavior对象，self.inertialBehavior = nil
            self.inertialBehavior = inertialBehavior;
            [self.dynamicAnimator addBehavior:inertialBehavior];
        }
            break;
        default:
            break;
    }
}
/// 根据拖拽手势的拖拽距离，调整contentOffset
- (void)scrollViewsSetContentOffsetY:(CGFloat)deltaY {
    CGRect bounds = self.bounds;
    bounds.origin.y = self.bounds.origin.y - deltaY;
    if (deltaY < 0) { //上滑
        if ([self isBottom]) {  //滑到底部 回弹
            if (fabs(self.bounds.origin.y) <= self.maxBounceDistance + [self maxContentOffsetY]) {
                bounds.origin.y = bounds.origin.y >= self.maxBounceDistance + [self maxContentOffsetY] ?  self.maxBounceDistance + [self maxContentOffsetY] : bounds.origin.y;
                self.bounds = bounds;
                [self performBounceIfNeededForScrollViewisAtTop:NO];
            }
        }else {
            bounds.origin.y = bounds.origin.y > [self maxContentOffsetY] ? [self maxContentOffsetY] : bounds.origin.y;
            self.bounds = bounds;
        }
    }else if (deltaY > 0) { //下滑
        if ([self isTop]) { //滑到顶部  回弹
            if (fabs(self.bounds.origin.y) <= self.maxBounceDistance) {
                bounds.origin.y = bounds.origin.y < -_maxBounceDistance ?  -_maxBounceDistance : bounds.origin.y;
                self.bounds = bounds;
                [self performBounceIfNeededForScrollViewisAtTop:YES];
            }
        }else {
            bounds.origin.y = bounds.origin.y < 0 ? 0 : bounds.origin.y;
            self.bounds = bounds;
        }
    }
}
//两种回弹触发方式：
//1.惯性滚动到边缘处回弹
- (void)performBounceIfNeededForScrollViewisAtTop:(BOOL)isTop {
    if (self.inertialBehavior) {
        [self performBounceForScrollViewisAtTop:isTop];
    }
}
//2.手指拉到边缘处回弹
- (void)performBounceForScrollViewisAtTop:(BOOL)isTop {
    if (!self.bounceBehavior) {
        //移除惯性力
        [self.dynamicAnimator removeBehavior:self.inertialBehavior];
        
        //吸附力操作元素
        SLDynamicItem *item = [[SLDynamicItem alloc] init];
        item.center = self.bounds.origin;
        //吸附力的锚点Y
        CGFloat attachedToAnchorY = 0;
        attachedToAnchorY = isTop ? 0 : [self maxContentOffsetY];
        
        //吸附力
        UIAttachmentBehavior *bounceBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:CGPointMake(0, attachedToAnchorY)];
        //吸附点间的距离
        bounceBehavior.length = 0;
        //阻尼/缓冲
        bounceBehavior.damping = 1;
        //频率
        bounceBehavior.frequency = 2;
        bounceBehavior.action = ^{
            CGRect bounds = self.bounds;
            bounds.origin.y = item.center.y;
            self.bounds = bounds;
        };
        self.bounceBehavior = bounceBehavior;
        [self.dynamicAnimator addBehavior:bounceBehavior];
    }
}

#pragma mark - Getter
- (UIDynamicAnimator *)dynamicAnimator {
    if (!_dynamicAnimator) {
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
        _dynamicAnimator.delegate = self;
    }
    return _dynamicAnimator;
}

#pragma mark - UIDynamicAnimatorDelegate
//动力装置即将启动
- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    
}
//动力装置暂停
- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    
}
#pragma mark - UIGestureRecognizerDelegate
// 避免影响横滑手势
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self];
    return fabs(velocity.y) > fabs(velocity.x);
}
@end


@interface SLScrollViewController ()
@end

@implementation SLScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SLScrollView *scrollView = [[SLScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.contentSize = CGSizeMake(self.view.sl_width, 20*100);
    for (int i = 0 ; i < 20; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 100 *i, self.view.sl_width, 100)];
        label.backgroundColor = SL_UIColorFromRandomColor;
        label.numberOfLines = 2;
        label.text = [NSString stringWithFormat:@"%d、 继承于UIView，自定义实现UIScrollView的效果",i];
        label.textAlignment = NSTextAlignmentCenter;
        [scrollView addSubview:label];
    }
    [self.view addSubview:scrollView];
}

@end
