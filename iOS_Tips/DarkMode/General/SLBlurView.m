//
//  SLBlurView.m
//  DarkMode
//
//  Created by wsl on 2019/9/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLBlurView.h"

@implementation SLBlurView

/*
 Only override drawRect: if you perform custom drawing.
 An empty implementation adversely affects performance during animation.
 */

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        [self addSubview:self.blurView];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        [self addSubview:self.blurView];
    }
    return self;
}

- (UIVisualEffectView *)blurView {
    if (_blurView == nil) {
        //高斯模糊
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _blurView.alpha = 0.9;
        _blurView.frame = self.bounds;
    }
    return _blurView;
}

- (void)layoutSubviews {
    [self sendSubviewToBack:self.blurView];
    self.blurView.frame = self.bounds;
}


@end
