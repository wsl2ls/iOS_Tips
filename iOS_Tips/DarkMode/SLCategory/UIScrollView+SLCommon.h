//
//  UIScrollView+SLCommon.h
//  DarkMode
//
//  Created by wsl on 2020/5/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (SLCommon)

/// Y轴方向的最大的偏移量
- (CGFloat)sl_maxContentOffsetY;
/// 在底部
- (BOOL)sl_isBottom;
/// 在顶部
- (BOOL)sl_isTop;
/// 滚动到顶部
- (void)sl_scrollToTopWithAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
