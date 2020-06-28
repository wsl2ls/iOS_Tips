//
//  SLPictureBrowseController.h
//  TELiveClass
//
//  Created by wsl on 2020/2/28.
//  Copyright © 2020 offcn_c. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLPictureAnimationViewDelegate <NSObject>
//用于转场的动画视图
- (UIView *)animationViewOfPictureTransition:(NSIndexPath *)indexPath;
@end

/// 图集浏览控制器
@interface SLPictureBrowseController : UIViewController
@property (nonatomic, strong) NSMutableArray <NSURL *>*imagesArray;
@property (nonatomic, strong) NSIndexPath *indexPath; //数据来源索引
@end

NS_ASSUME_NONNULL_END
