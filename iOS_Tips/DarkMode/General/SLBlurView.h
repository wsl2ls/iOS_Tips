//
//  SLBlurView.h
//  DarkMode
//
//  Created by wsl on 2019/9/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 高斯模糊视图
@interface SLBlurView : UIView
//高斯模糊
@property (nonatomic, strong) UIVisualEffectView *blurView;
@end

NS_ASSUME_NONNULL_END
