//
//  UIScrollView+SLCommon.m
//  DarkMode
//
//  Created by wsl on 2020/5/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "UIScrollView+SLCommon.h"

@implementation UIScrollView (SLCommon)

- (CGFloat)sl_maxContentOffsetY {
    return MAX(0, self.contentSize.height - self.frame.size.height);
}
- (BOOL)sl_isBottom {
    return self.contentOffset.y + 0.5 >= [self sl_maxContentOffsetY] ||
    fabs(self.contentOffset.y - [self sl_maxContentOffsetY]) < FLT_EPSILON;
}
- (BOOL)sl_isTop {
    return self.contentOffset.y <= 0;
}
- (void)sl_scrollToTopWithAnimated:(BOOL)animated {
    [self setContentOffset:CGPointZero animated:animated];
}

@end
