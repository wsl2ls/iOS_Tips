//
//  SLEditMenuView.m
//  DarkMode
//
//  Created by wsl on 2019/10/9.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditMenuView.h"

@interface SLEditMenuView ()

@end

@implementation SLEditMenuView

//- (instancetype)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self createMenus];
//    }
//    return self;
//}
- (instancetype)init {
    self = [super init];
    if (self) {
        [self createMenus];
    }
    return self;
}
- (void)createMenus {
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    //    NSArray *menuTitles = @[@"涂鸦", @"贴纸", @"文字", @"裁剪"];
    NSArray *imageNames = @[@"EditMenuGraffiti", @"EditMenuSticker", @"EditMenuText", @"EditMenuCut"];
    int count = 4;
    CGSize itemSize = CGSizeMake(20, 20);
    CGFloat space = (self.frame.size.width - count * itemSize.width)/count;
    for (int i = 0; i < count; i++) {
        UIButton * menuBtn = [[UIButton alloc] initWithFrame:CGRectMake(space/2.0 + (itemSize.width + space)*i, 0, itemSize.width, self.frame.size.height)];
        menuBtn.tag = i;
        [menuBtn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        [self addSubview:menuBtn];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self createMenus];
}

@end
