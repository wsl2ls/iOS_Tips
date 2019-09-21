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

#pragma mark - Getter
- (AVCaptureSession *)session{
    if (_session == nil){
        // 创建环境光感输出流
        //        AVCaptureVideoDataOutput *lightOutput = [[AVCaptureVideoDataOutput alloc] init];
        //        [lightOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        _session = [[AVCaptureSession alloc] init];
        //高质量采集率
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        [_session addInput:self.videoInput]; //添加视频输入流
        [_session addInput:self.audioInput];  //添加音频输入流
        [_session addOutput:self.capturePhotoOutput]; //添加照片输出流
        [_session addOutput:self.captureMovieFileOutPut]; //添加视频输出流
        //[_session addOutput:lightOutput];
    }
    return _session;
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

#pragma mark - HelpMethods
- (void)configure {
    
}
//获取指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)positon{
    if ([[UIDevice currentDevice].systemVersion floatValue] == 10.0) {
        AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:positon];
        for (AVCaptureDevice *device in dissession.devices) {
            if ([device position] == positon ) {
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

#pragma mark - EventsHandle
- (void)startRunning {
    if(!self.session.isRunning) {
        [self.session startRunning];
    }
}
- (void)stopRunning {
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}
//拍照 输出图片
- (void)outputPhoto {
    //输出样式设置   默认 flashMode：取值AVCaptureFlashModeAuto  autoStillImageStabilizationEnabled：取值YES
    AVCapturePhotoSettings *capturePhotoSettings = [AVCapturePhotoSettings photoSettings];
    //    capturePhotoSettings.highResolutionPhotoEnabled = YES; //高分辨率
    [self.capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self.photoCaptureDelegate];
}
//开始输出录制视频
- (void)startRecordVideo {
    //获得视频输出连接
    AVCaptureConnection * captureConnection = [_captureMovieFileOutPut connectionWithMediaType:AVMediaTypeVideo];
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
        [self.captureMovieFileOutPut startRecordingToOutputFileURL:fileUrl recordingDelegate:self.fileOutputRecordingDelegate];
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

@end
