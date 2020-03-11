//
//  SLAvWriterInput.m
//  DarkMode
//
//  Created by wsl on 2019/11/7.
//  Copyright © 2019 https://github.com/wsl2ls   ----- All rights reserved.
//

#import "SLAvWriterInput.h"

@interface SLAvWriterInput ()

@property (nonatomic, strong) AVAssetWriter *assetWriter;   //音视频数据流文件写入
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;  //写入视频文件
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;  //写入音频文件
@property (nonatomic, strong) NSDictionary *videoCompressionSettings; //视频写入配置
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;  //音频写入配置

@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor* inputPixelBufferAdptor; //输入像素缓冲器  把缓冲样本滤镜处理之后再写入
@property (nonatomic, assign) CMTime currentSampleTime;  // 当前采样时间
@property (nonatomic, assign) CMVideoDimensions currentVideoDimensions;  //尺寸
@property (nonatomic, strong) CIContext* context;

@property (nonatomic, assign) BOOL isStartWriting; //是否开始写入
@property (nonatomic, copy)  NSURL *outputFileURL; //音视频文件输出路径
@property (nonatomic, assign) SLAvWriterFileType  outputFileType; //写入输出文件类型 默认 SLAvWriterFileTypeVideo

@end

@implementation SLAvWriterInput

- (instancetype)init {
    self = [super init];
    if (self) {
        self.videoSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    return self;
}

#pragma mark - Setter
- (void)setOutputFileURL:(NSURL *)outputFileURL {
    _outputFileURL = outputFileURL;
    if (self.outputFileType == SLAvWriterFileTypeAudio) {
        _assetWriter = [AVAssetWriter assetWriterWithURL:outputFileURL fileType:AVFileTypeAC3 error:nil];
    } else if (self.outputFileType == SLAvWriterFileTypeVideo || self.outputFileType == SLAvWriterFileTypeSilentVideo) {
        _assetWriter = [AVAssetWriter assetWriterWithURL:outputFileURL fileType:AVFileTypeMPEG4 error:nil];
    }
}
#pragma mark - Getter
- (AVAssetWriterInput *)assetWriterVideoInput {
    if (!_assetWriterVideoInput) {
        //写入视频大小
        NSInteger numPixels = self.videoSize.width * [UIScreen mainScreen].scale  * self.videoSize.height * [UIScreen mainScreen].scale;
        //每像素比特
        CGFloat bitsPerPixel = 24.0;
        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
        // 码率和帧率设置
        NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                                 AVVideoExpectedSourceFrameRateKey : @(15),
                                                 AVVideoMaxKeyFrameIntervalKey : @(15),
                                                 AVVideoProfileLevelKey : AVVideoProfileLevelH264High40 };
        CGFloat width = self.videoSize.width * [UIScreen mainScreen].scale;
        CGFloat height = self.videoSize.height * [UIScreen mainScreen].scale;
        //视频属性
        self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                           AVVideoWidthKey : @(width),
                                           AVVideoHeightKey : @(height),
                                           AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                           AVVideoCompressionPropertiesKey : compressionProperties };
        
        _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
        //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
        _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    }
    return _assetWriterVideoInput;
}
- (AVAssetWriterInput *)assetWriterAudioInput {
    if (_assetWriterAudioInput == nil) {
        /* 注：
         <1>AVNumberOfChannelsKey 通道数  1为单通道 2为立体通道
         <2>AVSampleRateKey 采样率 取值为 8000/44100/96000 影响音频采集的质量
         <3>d 比特率(音频码率) 取值为 8 16 24 32
         <4>AVEncoderAudioQualityKey 质量  (需要iphone8以上手机)
         <5>AVEncoderBitRateKey 比特采样率 一般是128000
         */
        
        /*另注：aac的音频采样率不支持96000，当我设置成8000时，assetWriter也是报错*/
        // 音频设置
        _audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
        
        _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
        _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    }
    return _assetWriterAudioInput;
}
- (AVAssetWriterInputPixelBufferAdaptor *)inputPixelBufferAdptor {
    if (!_inputPixelBufferAdptor) {
        NSDictionary* sourcePixelBufferAttributesDictionary =
        @{
            (NSString*)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
            (NSString*)kCVPixelBufferWidthKey:@(self.currentVideoDimensions.width),
            (NSString*)kCVPixelBufferHeightKey:@(self.currentVideoDimensions.height),
            (NSString*)kCVPixelFormatOpenGLESCompatibility:@(1)
        };
        _inputPixelBufferAdptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    }
    return _inputPixelBufferAdptor;
}
-(CIContext *)context{
    // default creates a context based on GPU
    if (_context == nil) {
        _context = [CIContext contextWithOptions:nil];
    }
    return _context;
}
#pragma mark - HelpMethods
// 开始准备写入 配置写入的输出文件地址和格式  每次开始写入之前都要调用一次
- (void)startWritingToOutputFileAtPath:(NSString *)path fileType:(SLAvWriterFileType)fileType deviceOrientation:(UIDeviceOrientation)deviceOrientation{
    self.outputFileType = fileType;
    //移除相同文件，否则无法写入
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    self.outputFileURL = [NSURL fileURLWithPath:path];
    
    //调整写入时的方向
    if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI/2);
    } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(-M_PI/2);
    } else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI);
    } else {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(0);
    }
    
    if (self.outputFileType == SLAvWriterFileTypeSilentVideo || self.outputFileType == SLAvWriterFileTypeVideo) {
        if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            [self.assetWriter addInput:self.assetWriterVideoInput];
        } else {
            NSLog(@"视频写入失败");
        }
    }
    if (self.outputFileType == SLAvWriterFileTypeAudio || self.outputFileType == SLAvWriterFileTypeVideo){
        if ([self.assetWriter canAddInput:self.assetWriterAudioInput] ) {
            [self.assetWriter addInput:self.assetWriterAudioInput];
        } else {
            NSLog(@"音频写入失败");
        }
    }
}
/// 实时写入视频样本   如果需要给视频加滤镜，就传入filterImage ，如果filterImage == nil，就表示不需要加滤镜
- (void)writingVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection filterImage:(CIImage *)filterImage {
    if (filterImage) {
        //如果需要滤镜处理
        @autoreleasepool {
            @synchronized(self) {
                CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                //样本尺寸
                self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
                // 当前采样时间
                self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
                //开始写入之前必须初始化
                _inputPixelBufferAdptor = self.inputPixelBufferAdptor;
                if (!self.isStartWriting  && (self.outputFileType == SLAvWriterFileTypeVideo || self.outputFileType == SLAvWriterFileTypeSilentVideo)) {
                    //一个写入周期内只能执行一次
                    [self.assetWriter startWriting];
                    [self.assetWriter startSessionAtSourceTime:self.currentSampleTime];
                    self.isStartWriting = YES;
                }
                if (self.inputPixelBufferAdptor.assetWriterInput.isReadyForMoreMediaData && self.isStartWriting) {
                    CVPixelBufferRef newPixelBuffer = NULL;
                    CVPixelBufferPoolCreatePixelBuffer(NULL, self.inputPixelBufferAdptor.pixelBufferPool, &newPixelBuffer);
                    [self.context render:filterImage toCVPixelBuffer:newPixelBuffer bounds:filterImage.extent colorSpace:filterImage.colorSpace];
                    if (newPixelBuffer) {
                        if (self.assetWriter.status == AVAssetWriterStatusWriting) {
                            BOOL success = [self.inputPixelBufferAdptor appendPixelBuffer:newPixelBuffer withPresentationTime:self.currentSampleTime];
                            if (!success) {
                                [self finishWriting];
                            }
                        }
                        CFRelease(newPixelBuffer);
                    }else{
                        NSLog(@"newPixelBuffer is nil");
                    }
                }
            }
        }
        
    }else {
        @autoreleasepool {
            @synchronized(self) {
                if (!self.isStartWriting  && (self.outputFileType == SLAvWriterFileTypeVideo || self.outputFileType == SLAvWriterFileTypeSilentVideo)) {
                    //一个写入周期内只能执行一次
                    [self.assetWriter startWriting];
                    [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                    self.isStartWriting = YES;
                }
                //写入视频数据
                if (self.assetWriterVideoInput.readyForMoreMediaData && self.isStartWriting) {
                    BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self finishWriting];
                        }
                    }
                }
            }
        }
    }
    
}
//实时写入输出的音频
- (void)writingAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        @synchronized(self) {
            if (!self.isStartWriting && self.outputFileType == SLAvWriterFileTypeAudio) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.isStartWriting = YES;
            }
            if (self.assetWriterAudioInput.readyForMoreMediaData && self.isStartWriting == YES) {
                //写入音频数据
                BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    @synchronized (self) {
                        [self finishWriting];
                    }
                }
            }
        }
    }
}
/// 完成写入
- (void)finishWriting {
    __weak typeof(self) weakSelf = self;
    if(_assetWriter && self.isStartWriting) {
        [_assetWriter finishWritingWithCompletionHandler:^{
            weakSelf.isStartWriting = NO;
            weakSelf.inputPixelBufferAdptor = nil;
            weakSelf.context = nil;
            weakSelf.assetWriter = nil;
            weakSelf.assetWriterAudioInput = nil;
            weakSelf.assetWriterVideoInput = nil;
            if ([weakSelf.delegate respondsToSelector:@selector(writerInput:didFinishRecordingToOutputFileAtURL:error:)]) {
                SL_DISPATCH_ON_MAIN_THREAD(^{
                    [weakSelf.delegate writerInput:weakSelf didFinishRecordingToOutputFileAtURL:weakSelf.outputFileURL error:weakSelf.assetWriter.error];
                });
            }
        }];
    }
}

@end
