//
//  SLEditViewController.h
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 拍摄完毕后 编辑
@interface SLEditVideoController : UIViewController
@property (nonatomic, strong) NSURL *videoPath; //当前拍摄的视频路径
@end

NS_ASSUME_NONNULL_END
