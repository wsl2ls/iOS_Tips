//
//  SLReusableManager.h
//  DarkMode
//
//  Created by wsl on 2020/6/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLReusableCell : UIView
@end

@class SLReusableManager;
@protocol SLReusableDataSource <NSObject>
@required
///行数
- (NSInteger)numberOfRowsInReusableManager:(SLReusableManager *)reusableManager;
///行位置
- (CGRect)reusableManager:(SLReusableManager *)reusableManager frameForRowAtIndex:(NSInteger)index;
///行内容
- (SLReusableCell *)reusableManager:(SLReusableManager *)reusableManager cellForRowAtIndex:(NSInteger)index;
@end
@protocol SLReusableDelegate <NSObject, UIScrollViewDelegate>
///选中行
- (void)tableView:(SLReusableManager *)reusableManager didSelectRowAtIndex:(NSInteger)index;
@end

@interface SLReusableManager : NSObject
@property (nonatomic, weak) UIScrollView *scrollView;
@end

NS_ASSUME_NONNULL_END
