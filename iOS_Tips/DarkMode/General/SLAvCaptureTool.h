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
API_AVAILABLE(ios(10.0))
///摄像头捕获工具    配置都是默认的
@interface SLAvCaptureTool : NSObject

/// 摄像头采集内容预览视图
@property (nonatomic, strong, nullable) UIView *preview;
/// 摄像头是否正在运行
@property (nonatomic, assign, readonly) BOOL isRunning;
/// 拍摄方向
@property (nonatomic, assign, readonly) AVCaptureDevicePosition devicePosition;
/// 闪光灯状态样式 默认是关闭的，即黑暗情况下拍照不打开闪光灯
@property (nonatomic, assign) AVCaptureFlashMode flashMode;
/// 当前焦距    默认最小值1  最大值6
@property (nonatomic, assign) CGFloat videoZoomFactor;

///启动捕获
- (void)startRunning;
///结束捕获
- (void)stopRunning;

/// 输出图片
/// @param delegate 照片输出代理
- (void)outputPhotoWithDelegate:(id<AVCapturePhotoCaptureDelegate>)delegate;
/// 开始输出录制视频
/// @param delegate 录制文件输出代理
- (void)startRecordVideoWithDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate;
///结束输出录制视频
- (void)stopRecordVideo;
/// 切换前/后置摄像头
- (void)switchsCamera:(AVCaptureDevicePosition)devicePosition;
/// 聚焦点  默认是自动聚焦模式  范围是在previewLayer上
- (void)focusAtPoint:(CGPoint)focalPoint;

@end

NS_ASSUME_NONNULL_END
