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

///音视频捕获类型
typedef NS_ENUM(NSUInteger, SLAvCaptureType) {
    /// 音视频  默认
    SLAvCaptureTypeAv = 0,
    /// 纯视频 无音频
    SLAvCaptureTypeVideo,
    /// 音频
    SLAvCaptureTypeAudio
};

@class SLAvCaptureTool;
/// 捕获工具输出代理
@protocol SLAvCaptureToolDelegate <NSObject>
@optional
///  完成拍照 ，返回image
/// @param image 输出的图片
/// @param error 错误信息
- (void)captureTool:(SLAvCaptureTool *_Nonnull)captureTool didOutputPhoto:(UIImage *_Nullable)image error:(nullable NSError *)error;
///  完成音视频录制，返回临时文件地址
/// @param outputFileURL 文件地址
/// @param error 错误信息
- (void)captureTool:(SLAvCaptureTool *_Nonnull)captureTool didFinishRecordingToOutputFileAtURL:(NSURL *_Nullable)outputFileURL error:(nullable NSError *)error;

/// 实时输出采集的音视频样本  提供对外接口 方便自定义处理
/// @param captureTool captureTool
/// @param sampleBuffer 样本缓冲
/// @param connection 输入和输出之前的连接
- (void)captureTool:(SLAvCaptureTool *_Nonnull)captureTool didOutputVideoSampleBuffer:(CMSampleBufferRef _Nonnull )sampleBuffer fromConnection:(AVCaptureConnection *_Nonnull)connection;
- (void)captureTool:(SLAvCaptureTool *_Nonnull)captureTool didOutputAudioSampleBuffer:(CMSampleBufferRef _Nonnull )sampleBuffer fromConnection:(AVCaptureConnection *_Nonnull)connection;
@end

NS_ASSUME_NONNULL_BEGIN

// SLAvCaptureTool ----- 拆分为了 SLAvCaptureSession（采集） + SLAvWriterInput（录制） 两个工具类，方便扩展，实现的方式也略有不同
///音视频 采集 录制工具    配置都是默认的
@interface SLAvCaptureTool : NSObject

/// 摄像头采集内容预览视图  
@property (nonatomic, strong, nullable) UIView *preview;
/// 导出的视频宽高  默认设备宽高  已home键朝下为准
@property (nonatomic, assign) CGSize videoSize;
/// 摄像头是否正在运行
@property (nonatomic, assign, readonly) BOOL isRunning;
/// 摄像头方向 默认后置摄像头
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
/// 输出图片 拍照
- (void)outputPhoto;
/// 开始录制视频  默认输出MP4
/// @param path 录制的音视频输出路径
/// @param avRecordType 录制视频类型
- (void)startRecordVideoToOutputFileAtPath:(NSString *)path recordType:(SLAvCaptureType)avRecordType;
/// 结束录制视频
- (void)stopRecordVideo;
/// 开始录制音频 默认输出MP3
/// @param path 录制的音频输出路径
- (void)startRecordAudioToOutputFileAtPath:(NSString *)path;
/// 结束录制音频
- (void)stopRecordAudio;

@end

NS_ASSUME_NONNULL_END
