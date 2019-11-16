//
//  SLWaterMarkController.h
//  DarkMode
//
//  Created by wsl on 2019/11/14.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 添加水印 文字和GIF图
@interface SLWaterMarkController : UIViewController
@property (nonatomic, strong) NSURL *videoPath; //当前拍摄的视频路径
@property (nonatomic, assign) UIDeviceOrientation videoOrientation;// 视频方向
@end

NS_ASSUME_NONNULL_END
