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
- (void)reusableManager:(SLReusableManager *)reusableManager didSelectRowAtIndex:(NSInteger)index;
@end

@interface SLReusableManager : NSObject
///数据源代理
@property (nonatomic, weak) id<SLReusableDelegate>delegate;
///数据源代理
@property (nonatomic, weak) id<SLReusableDataSource>dataSource;
/// 父视图
@property (nonatomic, weak) UIScrollView *scrollView;

///刷新数据
- (void)reloadData;
///注册样式
- (void)registerClass:(Class)class forCellReuseIdentifier:(NSString *)cellID;
///根据cellID从复用池reusablePool取可重用的view，如果没有，重新创建一个新对象返回
- (SLReusableCell *)dequeueReusableCellWithIdentifier:(nonnull NSString *)cellID index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
