//
//  SLPictureTransitionAnimation.m
//  TELiveClass
//
//  Created by wsl on 2020/2/28.
//  Copyright © 2020 offcn_c. All rights reserved.
//

#import "SLPictureTransitionAnimation.h"

@interface SLPictureTransitionAnimation ()
@end

@implementation SLPictureTransitionAnimation

#pragma mark - UIViewControllerAnimatedTransitioning
//返回动画时间
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}
//所有的过渡动画事务都在这个代理方法里面完成
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    switch (self.transitionType) {
        case SLTransitionTypePush:
            [self pushAnimation:transitionContext];
            break;
        case SLTransitionTypePop:
            [self popAnimation:transitionContext];
            break;
        case SLTransitionTypePresent:
            [self presentAnimation:transitionContext];
            break;
        case SLTransitionTypeDissmiss:
            [self dissmissAnimation:transitionContext];
            break;
    }
}

#pragma mark - Push/Pop
- (void)pushAnimation:(id <UIViewControllerContextTransitioning>)transitionContext {
    [transitionContext completeTransition:YES];
}
- (void)popAnimation:(id <UIViewControllerContextTransitioning>)transitionContext {
    [transitionContext completeTransition:YES];
}

#pragma mark - Present/Dissmiss
- (void)presentAnimation:(id <UIViewControllerContextTransitioning>)transitionContext {
    //转场后视图控制器上的视图view
    UIView *toView  = [transitionContext viewForKey: UITransitionContextToViewKey];
    toView.hidden = true;
    //这里有个重要的概念containerView，如果要对视图做转场动画，视图就必须要加入containerView中才能进行，可以理解containerView管理着所有做转场动画的视图
    UIView *containerView = transitionContext.containerView;
    //黑色背景视图
    UIView *bgView = [[UIView alloc] initWithFrame: CGRectMake(0,0, containerView.frame.size.width, containerView.frame.size.height)];
    bgView.backgroundColor = [UIColor blackColor];
    [containerView addSubview:toView];
    [containerView addSubview:bgView];
    [containerView addSubview:self.fromAnimatonView];
    //动画
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        if(!CGRectEqualToRect(self.toAnimatonView.frame, CGRectZero)) {
            self.fromAnimatonView.frame = self.toAnimatonView.frame;
            self.fromAnimatonView.layer.contentsRect = self.toAnimatonView.layer.contentsRect;
        }
    } completion:^(BOOL finished) {
        toView.hidden = NO;
        [bgView removeFromSuperview];
        [self.fromAnimatonView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}
- (void)dissmissAnimation:(id <UIViewControllerContextTransitioning>)transitionContext {
    //转场前视图控制器上的视图view
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    fromView.hidden = YES;
    UIView *containerView = transitionContext.containerView;
    //黑色背景视图
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake( 0,0, containerView.frame.size.width, containerView.frame.size.height)];
    bgView.backgroundColor = fromView.backgroundColor;
    [containerView addSubview:bgView];
    [containerView addSubview:self.fromAnimatonView];
    //动画
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        self.fromAnimatonView.frame = self.toAnimatonView.frame;
        self.fromAnimatonView.layer.contentsRect = self.toAnimatonView.layer.contentsRect;
        bgView.alpha = 0;
    } completion:^(BOOL finished) {
        [bgView removeFromSuperview];
        [self.fromAnimatonView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

@end
