//
//  SLAvCaptureSession.m
//  DarkMode
//
//  Created by wsl on 2019/11/7.
//  Copyright © 2019 https://github.com/wsl2ls   -----  All rights reserved.
//

#import "SLAvCaptureSession.h"
#import <CoreMotion/CoreMotion.h>

@interface SLAvCaptureSession () <AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;  //采集会话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//摄像头采集内容展示区域

@property (nonatomic, strong) AVCaptureDeviceInput *audioInput; //音频输入流
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput; //视频输入流
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput; //视频数据帧输出流
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput; //音频数据帧输出流

@property (nonatomic, strong) CMMotionManager *motionManager;       //运动传感器  监测设备方向

@end

@implementation SLAvCaptureSession

+ (instancetype)sharedAvCaptureSession {
    static SLAvCaptureSession *avCaptureSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        avCaptureSession = [[SLAvCaptureSession alloc] init];
    });
    return avCaptureSession;
}

#pragma mark - Override
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
        [_session setSessionPreset:AVCaptureSessionPreset1280x720];
        if([_session canAddInput:self.videoInput]) [_session addInput:self.videoInput]; //添加视频输入流
        if([_session canAddInput:self.audioInput])  [_session addInput:self.audioInput];  //添加音频输入流
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
    AVCaptureDevicePosition devicePosition = [[self.videoInput device] position];
    return devicePosition;
}
- (CGFloat)videoZoomFactor {
    return [self.videoInput device].videoZoomFactor;
}

#pragma mark - Setter
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
    if (self.devicePosition == AVCaptureDevicePositionFront && captureConnection.supportsVideoMirroring) {
        captureConnection.videoMirrored = YES;
    }
    captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    //提交新的输入对象
    [self.session commitConfiguration];
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

#pragma mark -  AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate 实时输出音视频
/// 实时输出采集到的音视频帧内容
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!sampleBuffer) {
        return;
    }
    //提供对外接口，方便自定义处理
    if (output == self.videoDataOutput) {
        if([self.delegate respondsToSelector:@selector(captureSession:didOutputVideoSampleBuffer:fromConnection:)]) {
            [self.delegate captureSession:self didOutputVideoSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
    if (output == self.audioDataOutput) {
        if([self.delegate respondsToSelector:@selector(captureSession:didOutputAudioSampleBuffer:fromConnection:)]) {
            [self.delegate captureSession:self didOutputAudioSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
}
/// 实时输出丢弃的音视频帧内容
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0)) {
    
}

@end
