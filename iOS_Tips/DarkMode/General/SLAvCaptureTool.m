//
//  SLAvCaptureTool.m
//  DarkMode
//
//  Created by wsl on 2019/9/20.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLAvCaptureTool.h"

@interface SLAvCaptureTool ()

@property (nonatomic, strong) AVCaptureSession *session;
//音频输入流
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
//视频输入流
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
//照片输出流
@property (nonatomic, strong) AVCapturePhotoOutput *capturePhotoOutput;
//视频输出流
@property (nonatomic, strong) AVCaptureMovieFileOutput *captureMovieFileOutPut;
//摄像头采集内容展示区域
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

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
        //                [self configure];
    }
    return self;
}
#pragma mark - HelpMethods
- (void)configure {
    
}
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
        [_session addOutput:self.captureMovieFileOutPut]; //添加视频文件输出流
        //[_session addOutput:lightOutput];
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
            NSLog(@"设备不支持摄像");
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
- (AVCaptureMovieFileOutput *)captureMovieFileOutPut {
    if (_captureMovieFileOutPut == nil) {
        _captureMovieFileOutPut = [[AVCaptureMovieFileOutput alloc] init];
    }
    return _captureMovieFileOutPut;
}
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}
- (BOOL)isRunning {
    return self.session.isRunning;
}
- (AVCaptureDevicePosition)devicePosition {
    return [[self.videoInput device] position];
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
        //        [preview.layer insertSublayer:self.previewLayer atIndex:0];
        [preview.layer addSublayer:self.previewLayer];
    }
    _preview = preview;
}
- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor {
    NSError *error = nil;
    if (videoZoomFactor < self.maxZoomFactor &&
        videoZoomFactor > self.minZoomFactor){
        if ([[self.videoInput device] lockForConfiguration:&error] ) {
            [self.videoInput device].videoZoomFactor = videoZoomFactor;
            [[self.videoInput device] unlockForConfiguration];
        } else {
            NSLog( @"调节焦距失败: %@", error );
        }
    }
}

#pragma mark - EventsHandle
///启动捕获
- (void)startRunning {
    if(!self.session.isRunning) {
        [self.session startRunning];
    }
}
///结束捕获
- (void)stopRunning {
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}
//拍照 输出图片
- (void)outputPhotoWithDelegate:(id<AVCapturePhotoCaptureDelegate>)delegate {
    //输出样式设置
    AVCapturePhotoSettings *capturePhotoSettings = [AVCapturePhotoSettings photoSettings];
    //    capturePhotoSettings.highResolutionPhotoEnabled = YES; //高分辨率
    capturePhotoSettings.flashMode = _flashMode;  //闪光灯 根据环境亮度自动决定是否打开闪光灯
    [self.capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:delegate];
}
//开始输出录制视频
- (void)startRecordVideoWithDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate {
    //获得视频输出连接
    AVCaptureConnection * captureConnection = [self.captureMovieFileOutPut connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoStabilizationSupported]) {
        captureConnection.preferredVideoStabilizationMode= AVCaptureVideoStabilizationModeAuto;
    }
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutPut isRecording]) {
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.previewLayer connection].videoOrientation;
        //临时存储路径
        NSString *outputVideoFielPath = [NSTemporaryDirectory() stringByAppendingString:@"myMovie.mov"];
        NSURL *fileUrl=[NSURL fileURLWithPath:outputVideoFielPath];
        [self.captureMovieFileOutPut startRecordingToOutputFileURL:fileUrl recordingDelegate:delegate];
    }
}
//结束输出录制视频
- (void)stopRecordVideo {
    if (self.captureMovieFileOutPut.isRecording) {
        [self.captureMovieFileOutPut stopRecording];
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
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:videoInput];
        self.videoInput = videoInput;
    }
    //提交新的输入对象
    [self.session commitConfiguration];
}
//设置聚焦点  默认自动聚焦模式
- (void)focusAtPoint:(CGPoint)focalPoint {
    //将UI坐标转化为摄像头坐标  (0,0) -> (1,1)
    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:focalPoint];
    AVCaptureDevice *captureDevice = [self.videoInput device];
    NSError * error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }
        [captureDevice unlockForConfiguration];
    } else {
        NSLog(@"设置聚焦点错误：%@", error.localizedDescription);
    }
}
@end
