//
//  SLAvCaptureTool.m
//  DarkMode
//
//  Created by wsl on 2019/9/20.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLAvCaptureTool.h"
#import <CoreMotion/CoreMotion.h>

@interface SLAvCaptureTool () <AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;  //采集会话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//摄像头采集内容展示区域

@property (nonatomic, strong) AVCaptureDeviceInput *audioInput; //音频输入流
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput; //视频输入流
@property (nonatomic, strong) AVCapturePhotoOutput *capturePhotoOutput; //照片输出流
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput; //视频数据帧输出流
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput; //音频数据帧输出流

@property (nonatomic, strong) AVAssetWriter *assetWriter;   //音视频数据流文件写入
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;  //写入视频文件
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;  //写入音频文件
@property (nonatomic, strong) NSDictionary *videoCompressionSettings; //视频写入配置
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;  //音频写入配置
@property (nonatomic, assign) BOOL canWrite; //是否能写入
@property (nonatomic, copy)  NSURL *outputFileURL; //音视频文件输出路径

@property (nonatomic, assign) BOOL isRecording; //是否正在录制
@property (nonatomic, assign) SLAvCaptureType  avCaptureType; //音视频捕获类型 默认 SLAvCaptureTypeAv

@property (nonatomic, assign) UIDeviceOrientation shootingOrientation;   //拍摄录制时的手机方向
@property (nonatomic, strong) CMMotionManager *motionManager;       //运动传感器  监测设备方向

@end

@implementation SLAvCaptureTool

+ (instancetype)sharedAvCaptureTool {
    static SLAvCaptureTool *avCaptureTool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        avCaptureTool = [[SLAvCaptureTool alloc] init];
    });
    return avCaptureTool;
}

#pragma mark - Override
- (instancetype)init {
    self = [super init];
    if (self) {
        self.videoSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    return self;
}
- (void)dealloc {
    [self stopRunning];
}
#pragma mark - HelpMethods
//获取指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)positon{
    if (@available(iOS 10.2, *)) {
        AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:positon];
        for (AVCaptureDevice *device in dissession.devices) {
            if ([device position] == positon) {
                return device;
            }
        }
    } else {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == positon) {
                return device;
            }
        }
    }
    return nil;
}

//最小缩放值 焦距
- (CGFloat)minZoomFactor {
    CGFloat minZoomFactor = 1.0;
    if (@available(iOS 11.0, *)) {
        minZoomFactor = [self.videoInput device].minAvailableVideoZoomFactor;
    }
    return minZoomFactor;
}
//最大缩放值 焦距
- (CGFloat)maxZoomFactor {
    CGFloat maxZoomFactor = [self.videoInput device].activeFormat.videoMaxZoomFactor;
    if (@available(iOS 11.0, *)) {
        maxZoomFactor = [self.videoInput device].maxAvailableVideoZoomFactor;
    }
    if (maxZoomFactor > 6) {
        maxZoomFactor = 6.0;
    }
    return maxZoomFactor;
}

#pragma mark - Getter
- (AVCaptureSession *)session{
    if (_session == nil){
        _session = [[AVCaptureSession alloc] init];
        //高质量采集率
        [_session setSessionPreset:AVCaptureSessionPreset1280x720];
        if([_session canAddInput:self.videoInput]) [_session addInput:self.videoInput]; //添加视频输入流
        if([_session canAddInput:self.audioInput])  [_session addInput:self.audioInput];  //添加音频输入流
        if([_session canAddOutput:self.capturePhotoOutput]) [_session addOutput:self.capturePhotoOutput]; //添加照片输出流
        if([_session canAddOutput:self.videoDataOutput]) [_session addOutput:self.videoDataOutput];  //视频数据输出流 纯画面
        if([_session canAddOutput:self.audioDataOutput]) [_session addOutput:self.audioDataOutput];  //音频数据输出流
        
        AVCaptureConnection * captureVideoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        // 设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来
        if (self.devicePosition == AVCaptureDevicePositionFront && captureVideoConnection.supportsVideoMirroring) {
            captureVideoConnection.videoMirrored = YES;
        }
        captureVideoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _session;
}
- (AVCaptureDeviceInput *)videoInput {
    if (_videoInput == nil) {
        //添加一个视频输入设备  默认是后置摄像头
        AVCaptureDevice *videoCaptureDevice =  [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
        //创建视频输入流
        _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:nil];
        if (!_videoInput){
            NSLog(@"获得摄像头失败");
            return nil;
        }
    }
    return _videoInput;
}
- (AVCaptureDeviceInput *)audioInput {
    if (_audioInput == nil) {
        NSError * error = nil;
        //添加一个音频输入/捕获设备
        AVCaptureDevice * audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
        if (error) {
            NSLog(@"获得音频输入设备失败：%@",error.localizedDescription);
        }
    }
    return _audioInput;
}
- (AVCapturePhotoOutput *)capturePhotoOutput {
    if (_capturePhotoOutput == nil) {
        _capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];
        //        _capturePhotoOutput.livePhotoCaptureEnabled = NO; //是否拍摄 live Photo
    }
    return _capturePhotoOutput;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    }
    return _videoDataOutput;
}
- (AVCaptureAudioDataOutput *)audioDataOutput {
    if (_audioDataOutput == nil) {
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    }
    return _audioDataOutput;
}
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return _previewLayer;
}
- (AVAssetWriterInput *)assetWriterVideoInput {
    if (!_assetWriterVideoInput) {
        //写入视频大小
        NSInteger numPixels = self.videoSize.width * [UIScreen mainScreen].scale * self.videoSize.height * [UIScreen mainScreen].scale;
        //每像素比特
        CGFloat bitsPerPixel = 12.0;
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
                                           AVVideoWidthKey : @(width ),
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
- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}
- (BOOL)isRunning {
    return self.session.isRunning;
}
- (AVCaptureDevicePosition)devicePosition {
    if([[self.videoInput device] position] == AVCaptureDevicePositionUnspecified) {
        return AVCaptureDevicePositionBack;
    }
    return [[self.videoInput device] position];
}
- (CGFloat)videoZoomFactor {
    return [self.videoInput device].videoZoomFactor;
}

#pragma mark - Setter
- (void)setOutputFileURL:(NSURL *)outputFileURL {
    _outputFileURL = outputFileURL;
    if (self.avCaptureType == SLAvCaptureTypeAudio) {
        _assetWriter = [AVAssetWriter assetWriterWithURL:outputFileURL fileType:AVFileTypeAC3 error:nil];
    } else if (self.avCaptureType == SLAvCaptureTypeVideo || self.avCaptureType == SLAvCaptureTypeAv) {
        _assetWriter = [AVAssetWriter assetWriterWithURL:outputFileURL fileType:AVFileTypeMPEG4 error:nil];
    }
}
- (void)setPreview:(nullable UIView *)preview {
    if (preview == nil) {
        [self.previewLayer removeFromSuperlayer];
    }else {
        self.previewLayer.frame = preview.bounds;
        [preview.layer addSublayer:self.previewLayer];
    }
    _preview = preview;
}
- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor {
    NSError *error = nil;
    if (videoZoomFactor <= self.maxZoomFactor &&
        videoZoomFactor >= self.minZoomFactor){
        if ([[self.videoInput device] lockForConfiguration:&error] ) {
            [self.videoInput device].videoZoomFactor = videoZoomFactor;
            [[self.videoInput device] unlockForConfiguration];
        } else {
            NSLog( @"调节焦距失败: %@", error );
        }
    }
}
- (void)setShootingOrientation:(UIDeviceOrientation)shootingOrientation {
    if (_shootingOrientation == shootingOrientation) {
        return;
    }
    _shootingOrientation = shootingOrientation;
}
#pragma mark - EventsHandle
///启动捕获
- (void)startRunning {
    if(!self.session.isRunning) {
        [self.session startRunning];
    }
    [self startUpdateDeviceDirection];
}
///结束捕获
- (void)stopRunning {
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
    [self stopUpdateDeviceDirection];
}
//设置聚焦点和模式  默认连续自动聚焦和自动曝光模式
- (void)focusAtPoint:(CGPoint)focalPoint {
    //将UI坐标转化为摄像头坐标  (0,0) -> (1,1)
    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:focalPoint];
    AVCaptureDevice *captureDevice = [self.videoInput device];
    NSError * error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            if ([captureDevice isFocusPointOfInterestSupported]) {
                [captureDevice setFocusPointOfInterest:cameraPoint];
            }
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //曝光模式
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            if ([captureDevice isExposurePointOfInterestSupported]) {
                [captureDevice setExposurePointOfInterest:cameraPoint];
            }
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [captureDevice unlockForConfiguration];
    } else {
        NSLog(@"设置聚焦点错误：%@", error.localizedDescription);
    }
}
//切换前/后置摄像头
- (void)switchsCamera:(AVCaptureDevicePosition)devicePosition {
    //当前设备方向
    if (self.devicePosition == devicePosition) {
        return;
    }
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self getCameraDeviceWithPosition:devicePosition] error:nil];
    //先开启配置，配置完成后提交配置改变
    [self.session beginConfiguration];
    //移除原有输入对象
    [self.session removeInput:self.videoInput];
    //添加新的输入对象
    if ([self.session canAddInput:videoInput]) {
        [self.session addInput:videoInput];
        self.videoInput = videoInput;
    }
    
    //视频输入对象发生了改变  视频输出的链接也要重新初始化
    AVCaptureConnection * captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoStabilizationSupported]) {
        //视频稳定模式
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    if (self.devicePosition == AVCaptureDevicePositionFront && captureConnection.supportsVideoMirroring) {
        captureConnection.videoMirrored = YES;
    }
    captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    //提交新的输入对象
    [self.session commitConfiguration];
}
//拍照 输出图片
- (void)outputPhoto {
    //获得图片输出连接
    AVCaptureConnection * captureConnection = [self.capturePhotoOutput connectionWithMediaType:AVMediaTypeVideo];
    // 设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来
    if (self.devicePosition == AVCaptureDevicePositionFront && captureConnection.supportsVideoMirroring) {
        captureConnection.videoMirrored = YES;
    }
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    } else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    //输出样式设置 AVVideoCodecKey:AVVideoCodecJPEG等
    AVCapturePhotoSettings *capturePhotoSettings = [AVCapturePhotoSettings photoSettings];
    //    capturePhotoSettings.highResolutionPhotoEnabled = YES; //高分辨率
    capturePhotoSettings.flashMode = _flashMode;  //闪光灯 根据环境亮度自动决定是否打开闪光灯
    [self.capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
}
//开始录制视频
- (void)startRecordVideoToOutputFileAtPath:(NSString *)path recordType:(SLAvCaptureType)avCaptureType{
    self.avCaptureType = avCaptureType;
    //移除重复文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    self.outputFileURL = [NSURL fileURLWithPath:path];
    [self stopUpdateDeviceDirection];
    
    //获得视频输出连接
    AVCaptureConnection * captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    // 设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来
    if (self.devicePosition == AVCaptureDevicePositionFront && captureConnection.supportsVideoMirroring) {
        captureConnection.videoMirrored = YES;
    }
    //这个API 每次开始录制时设置视频输出方向，会造成摄像头的短暂黑暗，有问题的代码可以看此类文件夹下的SLAvCaptureTool-bug副本；切换摄像头时设置此属性没有较大的影响
    // captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    //由于上述原因，故采用在写入输出视频时调整方向
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight) {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI/2);
    } else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft) {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(-M_PI/2);
    } else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI);
    } else {
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(0);
    }
    if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
        [self.assetWriter addInput:self.assetWriterVideoInput];
    } else {
        NSLog(@"视频写入失败");
    }
    if ([self.assetWriter canAddInput:self.assetWriterAudioInput] && self.avCaptureType == SLAvCaptureTypeAv) {
        [self.assetWriter addInput:self.assetWriterAudioInput];
    } else {
        NSLog(@"音频写入失败");
    }
    _isRecording = YES;
}
/// 结束捕获视频帧
- (void)stopRecordVideo {
    if (_isRecording) {
        _isRecording = NO;
        __weak typeof(self) weakSelf = self;
        if(_assetWriter && self.canWrite && self.assetWriter.status != AVAssetWriterStatusUnknown) {
            [_assetWriter finishWritingWithCompletionHandler:^{
                if ([weakSelf.delegate respondsToSelector:@selector(captureTool:didFinishRecordingToOutputFileAtURL:error:)]) {
                    SL_DISPATCH_ON_MAIN_THREAD(^{
                        [weakSelf.delegate captureTool:weakSelf didFinishRecordingToOutputFileAtURL:weakSelf.outputFileURL error:weakSelf.assetWriter.error];
                    });
                }
                weakSelf.canWrite = NO;
                weakSelf.assetWriter = nil;
                weakSelf.assetWriterAudioInput = nil;
                weakSelf.assetWriterVideoInput = nil;
            }];
        }
    }
}
//开始录制音频
- (void)startRecordAudioToOutputFileAtPath:(NSString *)path {
    self.avCaptureType = SLAvCaptureTypeAudio;
    //移除重复文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    self.outputFileURL = [NSURL fileURLWithPath:path];
    [self stopUpdateDeviceDirection];
    [self.session beginConfiguration];
    //移除视频输出对象
    [self.session removeOutput:self.videoDataOutput];
    [self.session commitConfiguration];
    if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
        [self.assetWriter addInput:self.assetWriterAudioInput];
    } else {
        NSLog(@"音频写入失败");
    }
    _isRecording = YES;
}
//结束音频录制
- (void)stopRecordAudio {
    if (_isRecording) {
        _isRecording = NO;
        __weak typeof(self) weakSelf = self;
        if(_assetWriter && self.canWrite && self.assetWriter.status != AVAssetWriterStatusUnknown) {
            [_assetWriter finishWritingWithCompletionHandler:^{
                if ([weakSelf.delegate respondsToSelector:@selector(captureTool:didFinishRecordingToOutputFileAtURL:error:)]) {
                    SL_DISPATCH_ON_MAIN_THREAD(^{
                        [weakSelf.delegate captureTool:weakSelf didFinishRecordingToOutputFileAtURL:weakSelf.outputFileURL error:weakSelf.assetWriter.error];
                    });
                }
                weakSelf.canWrite = NO;
                weakSelf.assetWriter = nil;
                weakSelf.assetWriterAudioInput = nil;
                weakSelf.assetWriterVideoInput = nil;
            }];
        }
    }
}
#pragma mark - 重力感应监测设备方向
///开始监听设备方向
- (void)startUpdateDeviceDirection {
    if ([self.motionManager isAccelerometerAvailable] == YES) {
        //回调会一直调用,建议获取到就调用下面的停止方法，需要再重新开始，当然如果需求是实时不间断的话可以等离开页面之后再stop
        [self.motionManager setAccelerometerUpdateInterval:1.0];
        __weak typeof(self) weakSelf = self;
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            double x = accelerometerData.acceleration.x;
            double y = accelerometerData.acceleration.y;
            if ((fabs(y) + 0.1f) >= fabs(x)) {
                if (y >= 0.1f) {
                    //                    NSLog(@"Down");
                    if (weakSelf.shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
                        return ;
                    }
                    weakSelf.shootingOrientation = UIDeviceOrientationPortraitUpsideDown;
                } else {
                    //                    NSLog(@"Portrait");
                    if (weakSelf.shootingOrientation == UIDeviceOrientationPortrait) {
                        return ;
                    }
                    weakSelf.shootingOrientation = UIDeviceOrientationPortrait;
                }
            } else {
                if (x >= 0.1f) {
                    //                    NSLog(@"Right");
                    if (weakSelf.shootingOrientation == UIDeviceOrientationLandscapeRight) {
                        return ;
                    }
                    weakSelf.shootingOrientation = UIDeviceOrientationLandscapeRight;
                } else if (x <= 0.1f) {
                    //                    NSLog(@"Left");
                    if (weakSelf.shootingOrientation == UIDeviceOrientationLandscapeLeft) {
                        return ;
                    }
                    weakSelf.shootingOrientation = UIDeviceOrientationLandscapeLeft;
                } else  {
                    //                    NSLog(@"Portrait");
                    if (weakSelf.shootingOrientation == UIDeviceOrientationPortrait) {
                        return ;
                    }
                    weakSelf.shootingOrientation = UIDeviceOrientationPortrait;
                }
            }
        }];
    }
}
/// 停止监测方向
- (void)stopUpdateDeviceDirection {
    if ([self.motionManager isAccelerometerActive] == YES) {
        [self.motionManager stopAccelerometerUpdates];
        _motionManager = nil;
    }
}

#pragma mark - AVCapturePhotoCaptureDelegate 图片输出代理
/// 捕获拍摄图片的回调
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0)) {
    NSData *data = [photo fileDataRepresentation];
    UIImage *image  = [UIImage imageWithData:data];
    if ([self.delegate respondsToSelector:@selector(captureTool:didOutputPhoto:error:)]) {
        [self.delegate captureTool:self didOutputPhoto:image error:error];
    }else {
        NSLog(@"请实现代理方法：captureTool:didOutputPhoto:error:");
    }
}

#pragma mark -  AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate 实时输出帧内容
/// 实时输出采集到的音视频帧内容
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //提供对外接口，方便自定义处理
    if (output == self.videoDataOutput) {
        if([self.delegate respondsToSelector:@selector(captureTool:didOutputVideoSampleBuffer:fromConnection:)]) {
            [self.delegate captureTool:self didOutputVideoSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
    if (output == self.audioDataOutput) {
        if([self.delegate respondsToSelector:@selector(captureTool:didOutputAudioSampleBuffer:fromConnection:)]) {
            [self.delegate captureTool:self didOutputAudioSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
    
    if(!_isRecording || sampleBuffer == NULL) {
        return;
    }
    if (output == self.videoDataOutput) {
        //写入视频
        [self writerVideoSampleBuffer:sampleBuffer fromConnection:connection];
    }
    if (output == self.audioDataOutput) {
        //写入音频
        [self writerAudioSampleBuffer:sampleBuffer fromConnection:connection];
    }
}
//实时写入输出的视频
- (void)writerVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        @synchronized(self) {
            if (!self.canWrite && (self.avCaptureType == SLAvCaptureTypeAv || self.avCaptureType == SLAvCaptureTypeVideo)) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            //写入视频数据
            if (self.assetWriterVideoInput.readyForMoreMediaData) {
                BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    NSLog(@"视频写入失败, 错误：%@" ,self.assetWriter.error.localizedDescription);
                }
                
                //                if (!success) {
                //                    @synchronized (self) {
                //                        [self stopRecordVideo];
                //                    }
                //                }
            }
        }
    }
}
//实时写入输出的音频
- (void)writerAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        @synchronized(self) {
            if (!self.canWrite && self.avCaptureType == SLAvCaptureTypeAudio) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            if (self.assetWriterAudioInput.readyForMoreMediaData && self.canWrite) {
                //写入音频数据
                BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    NSLog(@"音频写入失败, 错误：%@" ,self.assetWriter.error.localizedDescription);
                }
                //                if (!success) {
                //                    @synchronized (self) {
                //                        if (self.avCaptureType == SLAvCaptureTypeAudio) {
                //                            [self stopRecordAudio];
                //                        }else if (self.avCaptureType == SLAvCaptureTypeAv || self.avCaptureType == SLAvCaptureTypeVideo) {
                //                            [self stopRecordVideo];
                //                        }
                //                    }
                //                }
            }
        }
    }
}

/// 丢帧
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0)) {
    
}

@end
