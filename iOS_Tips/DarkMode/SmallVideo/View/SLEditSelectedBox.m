//
//  SLEditSelectedBox.m
//  DarkMode
//
//  Created by wsl on 2019/10/23.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditSelectedBox.h"

@implementation SLEditSelectedBox

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initView];
    }
    return self;
}
- (instancetype)init{
    if (self = [super init]) {
        [self initView];
    }
    return self;
}
#pragma mark - help Methods
- (void)initView {
    // 初始化遮罩
    self.userInteractionEnabled = YES;
    self.layer.borderColor = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1].CGColor;
    self.layer.borderWidth = 2;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    CALayer *topLeft = [CALayer layer];
    topLeft.frame = CGRectMake(-2, -2, 6, 6);
    topLeft.backgroundColor = self.layer.borderColor;
    [self.layer addSublayer:topLeft];
    
    CALayer *topRight = [CALayer layer];
    topRight.frame = CGRectMake(self.bounds.size.width - 4, -2, 6, 6);
    topRight.backgroundColor = self.layer.borderColor;
    [self.layer addSublayer:topRight];
    
    CALayer *bottomLeft = [CALayer layer];
    bottomLeft.frame = CGRectMake(-2, self.frame.size.height - 4, 6, 6);
    bottomLeft.backgroundColor = self.layer.borderColor;
    [self.layer addSublayer:bottomLeft];
    
    CALayer *bottomRight = [CALayer layer];
    bottomRight.frame = CGRectMake(self.frame.size.width - 4, self.frame.size.height - 4, 6, 6);
    bottomRight.backgroundColor = self.layer.borderColor;
    [self.layer addSublayer:bottomRight];
}

@end
