//
//  SLPaddingLabel.m
//  DarkMode
//
//  Created by wsl on 2019/10/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLPaddingLabel.h"

@implementation SLPaddingLabel
- (void)drawTextInRect:(CGRect)rect {
  [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _textPadding)];
}
- (void)setTextPadding:(UIEdgeInsets)textPadding {
    _textPadding = textPadding;
    [self setNeedsLayout];
}
@end
