//
//  SLPictureTransitionAnimation.h
//  TELiveClass
//
//  Created by wsl on 2020/2/28.
//  Copyright © 2020 offcn_c. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//定义枚举 转场类型
typedef enum : NSUInteger {
    SLTransitionTypePush,
    SLTransitionTypePop,
    SLTransitionTypePresent,
    SLTransitionTypeDissmiss
} SLTransitionType;

/// 图片浏览转场动画
@interface SLPictureTransitionAnimation : NSObject<UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign) SLTransitionType transitionType;
@property (nonatomic, strong) UIView *toAnimatonView;  //动画前的视图
@property (nonatomic, strong) UIView *fromAnimatonView; //动画后的视图
//@property (nonatomic, assign) CGRect animatonRect;
//@property (nonatomic, strong) UIView *animatonView;
@end

NS_ASSUME_NONNULL_END
