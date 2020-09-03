//
//  SLMenuView.h
//  DarkMode
//
//  Created by wsl on 2020/9/3.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SLMenuView;
@protocol SLMenuViewDelegate <NSObject>
- (void)menuView:(SLMenuView *)menuView didSelectItemAtIndex:(NSInteger)index;
@end

@interface SLMenuView : UIView
@property (nonatomic, weak) id<SLMenuViewDelegate>delegate;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, assign) NSInteger currentPage;

@end

NS_ASSUME_NONNULL_END
