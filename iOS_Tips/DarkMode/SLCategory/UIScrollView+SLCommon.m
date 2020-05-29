//
//  UIScrollView+SLCommon.m
//  DarkMode
//
//  Created by wsl on 2020/5/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "UIScrollView+SLCommon.h"

@implementation UIScrollView (SLCommon)

- (CGFloat)maxContentOffsetY {
    return MAX(0, self.contentSize.height - self.frame.size.height);
}
- (BOOL)isBottom {
    return self.contentOffset.y + 0.5 >= [self maxContentOffsetY] ||
    fabs(self.contentOffset.y - [self maxContentOffsetY]) < FLT_EPSILON;
}
- (BOOL)isTop {
    return self.contentOffset.y <= 0;
}
- (void)scrollToTopWithAnimated:(BOOL)animated {
    [self setContentOffset:CGPointZero animated:animated];
}

@end
