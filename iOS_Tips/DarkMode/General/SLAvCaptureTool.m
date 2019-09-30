//
//  SLAvCaptureTool.m
//  DarkMode
//
//  Created by wsl on 2019/9/20.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLAvCaptureTool.h"
#import <CoreMotion/CoreMotion.h>

#define SL_kScreenWidth [UIScreen mainScreen].bounds.size.width
#define SL_kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface SLAvCaptureTool () <AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//摄像头采集内容展示区域

@property (nonatomic, strong) AVCaptureDeviceInput *audioInput; //音频输入流
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput; //视频输入流
@property (nonatomic, strong) AVCapturePhotoOutput *capturePhotoOutput; //照片输出流
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput; //视频数据帧输出流
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput; //音频数据帧输出流

@property (nonatomic, strong) AVAssetWriter *assetWriter;   //音视频数据流文件写入
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;  //写入视频文件
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;  //写入音频文件
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, assign) BOOL canWrite; //是否能写入
@property (nonatomic, copy)  NSURL *outputFileURL; //音视频文件输出路径

@property (nonatomic, assign) BOOL isRecording; //是否正在录制

@property (nonatomic, assign) UIDeviceOrientation shootingOrientation;   //拍摄时的手机方向
@property (nonatomic, strong) CMMotionManager *motionManager;       //运动传感器  监测设备方向

@end

@implementation SLAvCaptureTool

//@synthesize videoInput = _videoInput;

+ (instancetype)sharedAvCaptureTool {
    static SLAvCaptureTool *avCaptureTool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        avCaptureTool = [[SLAvCaptureTool alloc] init];
    });
    return avCaptureTool;
}

#pragma mark - OverWrite
- (instancetype)init {
    self = [super init];
    if (self) {
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
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        [_session addInput:self.videoInput]; //添加视频输入流
        [_session addInput:self.audioInput];  //添加音频输入流
        [_session addOutput:self.capturePhotoOutput]; //添加照片输出流
        [_session addOutput:self.videoDataOutput];  //视频数据输出流 纯画面
        [_session addOutput:self.audioDataOutput];  //音频数据输出流
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
        dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
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
    if (_assetWriter == nil) {
        _assetWriter = [AVAssetWriter assetWriterWithURL:outputFileURL fileType:AVFileTypeMPEG4 error:nil];
    }
}
- (void)setPreview:(nullable UIView *)preview {
    if (preview == nil) {
        [self.previewLayer removeFromSuperlayer];
    }else {
        self.previewLayer.frame = preview.bounds;
        //        [preview.layer insertSublayer:self.previewLayer atIndex:0];
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
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }
        //曝光模式
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:cameraPoint];
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
    
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    } else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
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
//开始输出视频帧
- (void)startRecordVideoToOutputFileAtPath:(NSString *)path {
    //移除重复文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    self.outputFileURL = [NSURL fileURLWithPath:path];
    [self stopUpdateDeviceDirection];
    
    [self.session beginConfiguration];
    //获得视频输出连接
    AVCaptureConnection * captureConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoStabilizationSupported]) {
        //视频稳定模式
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    // 设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来
    if (self.devicePosition == AVCaptureDevicePositionFront && captureConnection.supportsVideoMirroring) {
        captureConnection.videoMirrored = YES;
    }
    //    每次切换这个视频输出方向时，会造成摄像头的短暂黑暗? 故暂弃用此方法来设置输出的正确方向
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    } else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    [self.session commitConfiguration];
    
    //写入视频大小
    NSInteger numPixels = SL_kScreenWidth * SL_kScreenHeight;
    //每像素比特
    CGFloat bitsPerPixel = 12.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(15),
                                             AVVideoMaxKeyFrameIntervalKey : @(15),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    CGFloat width = SL_kScreenWidth;
    CGFloat height = SL_kScreenHeight;
    if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft || self.shootingOrientation == UIDeviceOrientationLandscapeRight) {
        width = SL_kScreenHeight;
        height = SL_kScreenWidth;
    }
    
    //视频属性
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                       AVVideoWidthKey : @(width * [UIScreen mainScreen].scale),
                                       AVVideoHeightKey : @(height * [UIScreen mainScreen].scale),
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    
    if ([self.assetWriter canAddInput:_assetWriterVideoInput]) {
        [self.assetWriter addInput:_assetWriterVideoInput];
    } else {
        NSLog(@"视频写入失败");
    }
    if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
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
        if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting) {
            [_assetWriter finishWritingWithCompletionHandler:^{
                weakSelf.canWrite = NO;
                weakSelf.assetWriter = nil;
                weakSelf.assetWriterAudioInput = nil;
                weakSelf.assetWriterVideoInput = nil;
                if ([weakSelf.delegate respondsToSelector:@selector(captureTool:didFinishRecordingToOutputFileAtURL:error:)]) {
                    DISPATCH_ON_MAIN_THREAD(^{
                        [weakSelf.delegate captureTool:weakSelf didFinishRecordingToOutputFileAtURL:weakSelf.outputFileURL error:weakSelf.assetWriter.error];
                    });
                }
            }];
        }
    }
}
//开始录制音频
- (void)startRecordAudioToOutputFileAtPath:(NSString *)path {
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
        if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting) {
            [_assetWriter finishWritingWithCompletionHandler:^{
                weakSelf.canWrite = NO;
                weakSelf.assetWriter = nil;
                weakSelf.assetWriterAudioInput = nil;
                weakSelf.assetWriterVideoInput = nil;
                if ([weakSelf.delegate respondsToSelector:@selector(captureTool:didFinishRecordingToOutputFileAtURL:error:)]) {
                    DISPATCH_ON_MAIN_THREAD(^{
                        [weakSelf.delegate captureTool:weakSelf didFinishRecordingToOutputFileAtURL:weakSelf.outputFileURL error:weakSelf.assetWriter.error];
                    });
                }
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
                    weakSelf.shootingOrientation = UIDeviceOrientationPortraitUpsideDown;
                } else {
                    //                    NSLog(@"Portrait");
                    weakSelf.shootingOrientation = UIDeviceOrientationPortrait;
                }
            } else {
                if (x >= 0.1f) {
                    //                    NSLog(@"Right");
                    weakSelf.shootingOrientation = UIDeviceOrientationLandscapeRight;
                } else if (x <= 0.1f) {
                    //                    NSLog(@"Left");
                    weakSelf.shootingOrientation = UIDeviceOrientationLandscapeLeft;
                } else  {
                    //                    NSLog(@"Portrait");
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
/// 实时输出音视频帧内容
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(!_isRecording || sampleBuffer == NULL) {
        return;
    }
    @autoreleasepool {
        //视频
        if (output == self.videoDataOutput) {
            @synchronized(self) {
                if (!self.canWrite) {
                    [self.assetWriter startWriting];
                    [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                    self.canWrite = YES;
                }
                //写入视频数据
                if (self.assetWriterVideoInput.readyForMoreMediaData) {
                    BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopRecordVideo];
                        }
                    }
                }
            }
        }
        //音频
        if (output == self.audioDataOutput) {
            @synchronized(self) {
                if (!self.canWrite) {
                    [self.assetWriter startWriting];
                    [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                    self.canWrite = YES;
                }
                if (self.assetWriterAudioInput.readyForMoreMediaData) {
                    //写入音频数据
                    BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopRecordVideo];
                        }
                    }
                }
            }
        }
    }
}

@end
