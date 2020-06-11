//
//  SLNavigationController.m
//  DarkMode
//
//  Created by wsl on 2020/6/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLNavigationController.h"

@interface SLNavigationController ()<UIGestureRecognizerDelegate>

@end

@implementation SLNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor clearColor];
    
    // 获取系统自带滑动手势的target对象
    id target = self.interactivePopGestureRecognizer.delegate;
    // 创建全屏滑动手势，调用系统自带滑动手势的target的action方法
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:target action:@selector(handleNavigationTransition:)];
    // 设置手势代理，拦截手势触发
    pan.delegate = self;
    // 给导航控制器的view添加全屏滑动手势
    [self.view addGestureRecognizer:pan];
    // 禁止使用系统自带的pop滑动手势
    self.interactivePopGestureRecognizer.enabled = NO;
}

#pragma mark -- UIGestureRecognizerDelegate

// 什么时候调用：每次触发手势之前都会询问下代理，是否触发。
// 作用：拦截手势触发
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // 注意：只有非根控制器才有滑动返回功能，根控制器没有。
    // 判断导航控制器是否只有一个子控制器，如果只有一个子控制器，肯定是根控制器
    if (self.childViewControllers.count == 1 ) {
        // 表示用户在根控制器界面，就不需要触发滑动手势，
        return NO;
    }
    return YES;
}
//触发之后是否响应手势事件
//处理侧滑返回与UISlider的拖动手势冲突
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    //如果手势是触摸的UISlider滑块触发的，侧滑返回手势就不响应
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

@end
