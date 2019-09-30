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

#define DISPATCH_ON_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(),mainQueueBlock);  //主线程操作

@class SLAvCaptureTool;

/// 捕获工具输出代理
@protocol SLAvCaptureToolDelegate <NSObject>
///  完成拍照 ，返回image
/// @param image 输出的图片
/// @param error 错误信息
- (void)captureTool:(SLAvCaptureTool *_Nonnull)captureTool didOutputPhoto:(UIImage *_Nullable)image error:(nullable NSError *)error;
///  完成音视频录制，返回临时文件地址
/// @param outputFileURL 文件地址
/// @param error 错误信息
- (void)captureTool:(SLAvCaptureTool *_Nonnull)captureTool didFinishRecordingToOutputFileAtURL:(NSURL *_Nullable)outputFileURL error:(nullable NSError *)error;
@end

NS_ASSUME_NONNULL_BEGIN
API_AVAILABLE(ios(10.0))
///摄像头捕获工具    配置都是默认的
@interface SLAvCaptureTool : NSObject

/// 摄像头采集内容预览视图
@property (nonatomic, strong, nullable) UIView *preview;
/// 摄像头是否正在运行
@property (nonatomic, assign, readonly) BOOL isRunning;
/// 摄像头方向
@property (nonatomic, assign, readonly) AVCaptureDevicePosition devicePosition;
/// 闪光灯状态  默认是关闭的，即黑暗情况下拍照不打开闪光灯   （打开/关闭/自动）
@property (nonatomic, assign) AVCaptureFlashMode flashMode;
/// 当前焦距    默认最小值1  最大值6
@property (nonatomic, assign) CGFloat videoZoomFactor;
/// 捕获工具输出代理
@property (nonatomic, weak) id<SLAvCaptureToolDelegate> delegate;

///启动捕获
- (void)startRunning;
///结束捕获
- (void)stopRunning;
/// 聚焦点  默认是连续聚焦模式  范围是在previewLayer上
- (void)focusAtPoint:(CGPoint)focalPoint;
/// 切换前/后置摄像头
- (void)switchsCamera:(AVCaptureDevicePosition)devicePosition;
/// 输出图片
- (void)outputPhoto;
/// 开始录制视频
/// @param path 录制的视频输出路径
- (void)startRecordVideoToOutputFileAtPath:(NSString *)path;
/// 结束录制视频
- (void)stopRecordVideo;
/// 开始录制音频
/// @param path 录制的音频输出路径
- (void)startRecordAudioToOutputFileAtPath:(NSString *)path;
/// 结束录制音频
- (void)stopRecordAudio;

@end

NS_ASSUME_NONNULL_END
