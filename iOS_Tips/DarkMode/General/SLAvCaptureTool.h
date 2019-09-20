//
//  SLAvCaptureTool.h
//  DarkMode
//
//  Created by wsl on 2019/9/20.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
///摄像头捕获工具    配置都是默认的
@interface SLAvCaptureTool : NSObject

/// 摄像头采集内容展示视图
@property (nonatomic, strong, nullable) UIView *preview;
/// 摄像头是否正在运行
@property (nonatomic, assign, readonly) BOOL isRunning;
/// 照片捕获代理 
@property (nonatomic, weak) id <AVCapturePhotoCaptureDelegate> photoCaptureDelegate;
/// 录制文件输出代理
@property (nonatomic, weak) id<AVCaptureFileOutputRecordingDelegate> fileOutputRecordingDelegate;

///启动捕获
- (void)startRunning;
///结束捕获
- (void)stopRunning;

/// 输出图片
- (void)outputPhoto;
///开始输出录制视频
- (void)startRecordVideo;
///结束输出录制视频
- (void)stopRecordVideo;

@end

NS_ASSUME_NONNULL_END
