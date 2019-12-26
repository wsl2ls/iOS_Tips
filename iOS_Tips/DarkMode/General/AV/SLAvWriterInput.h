//
//  SLAvWriterInput.h
//  DarkMode
//
//  Created by wsl on 2019/11/7.
//  Copyright © 2019 https://github.com/wsl2ls   ----- All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/// 写入的音视频文件类型
typedef NS_ENUM(NSUInteger, SLAvWriterFileType) {
    /// 音视频  默认
    SLAvWriterFileTypeVideo = 0,
    /// 无声视频
    SLAvWriterFileTypeSilentVideo,
    /// 音频
    SLAvWriterFileTypeAudio
};

@class SLAvWriterInput;
/// 音视频写入完成
@protocol SLAvWriterInputDelegate <NSObject>
@optional
///  写入音视频完成，返回文件地址
/// @param outputFileURL 文件地址
/// @param error 错误信息
- (void)writerInput:(SLAvWriterInput *_Nonnull)writerInput didFinishRecordingToOutputFileAtURL:(NSURL *_Nullable)outputFileURL error:(nullable NSError *)error;
@end

NS_ASSUME_NONNULL_BEGIN

/// 写入音视频样本 生成文件
@interface SLAvWriterInput : NSObject

/// 视频宽高  默认设备宽高  已home键朝下为准
@property (nonatomic, assign) CGSize videoSize;
///写入代理
@property (nonatomic, weak) id<SLAvWriterInputDelegate> delegate;

// 开始写入 设置写入的输出文件地址和格式、设备方向
- (void)startWritingToOutputFileAtPath:(NSString *)path fileType:(SLAvWriterFileType)fileType deviceOrientation:(UIDeviceOrientation)deviceOrientation;
/// 实时写入视频样本   如果filterImage == nil，就表示不需要加滤镜
- (void)writingVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection filterImage:(CIImage * _Nullable)filterImage;
/// 实时写入音频样本
- (void)writingAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
/// 完成写入
- (void)finishWriting;

@end

NS_ASSUME_NONNULL_END
