//
//  SLSplitScreenCell.m
//  DarkMode
//
//  Created by wsl on 2019/12/9.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLSplitScreenCell.h"

@interface SLSplitScreenCell ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation SLSplitScreenCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = CGRectInset(self.label.frame, 0, 0);
}

- (void)commonInit {
    self.label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont boldSystemFontOfSize:15];
    self.label.numberOfLines = 0;
    [self addSubview:self.label];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.label.text = title;
}
- (void)setIsSelect:(BOOL)isSelect {
    _isSelect = isSelect;
    self.label.backgroundColor = isSelect ? [UIColor blackColor] : [UIColor orangeColor];
    self.label.textColor = isSelect ? [UIColor whiteColor] : [UIColor blackColor];
}

@end
