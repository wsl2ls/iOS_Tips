//
//  SLShotViewController.m
//  DarkMode
//
//  Created by wsl on 2019/9/18.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLShotViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "UIView+SLFrame.h"
#import "SLBlurView.h"

#define KMaxDurationOfVideo  15.0

@interface SLShotViewController ()<AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate>
{
    dispatch_source_t _gcdTimer; //计时器
    NSTimeInterval _durationOfVideo;  //录制视频的时长
}

@property (nonatomic, strong) AVCaptureSession *session;
//照片输出流
@property (nonatomic, strong) AVCapturePhotoOutput * capturePhotoOutput;
//视频输出流
@property (nonatomic, strong) AVCaptureMovieFileOutput * captureMovieFileOutPut;

@property (nonatomic, strong) UIButton *backBtn;
//拍摄按钮
@property (nonatomic, strong) SLBlurView *shotBtn;
@property (nonatomic, strong) UIView *whiteView;
//环形进度条
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@property (nonatomic, strong) SLBlurView *editBtn;
@property (nonatomic, strong) SLBlurView *cancleBtn;
@property (nonatomic, strong) UIButton *saveBtn;

@property (nonatomic, strong) UIImage *image; //当前拍摄的照片

@end

@implementation SLShotViewController

#pragma mark - OverWrite
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self configuredScanTool];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.session startRunning];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
    if (_gcdTimer) {
        dispatch_source_cancel(_gcdTimer);
    }
}
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    UIEdgeInsets insets = self.view.safeAreaInsets;
    self.backBtn.frame = CGRectMake(50, self.view.frame.size.height - 50 - insets.bottom, 23, 12);
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
#pragma mark - UI
- (void)setupUI {
    self.title = @"拍摄";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.shotBtn];
    
    [self.view addSubview:self.cancleBtn];
    [self.view addSubview:self.editBtn];
    [self.view addSubview:self.saveBtn];
    
}

//初始化采集配置信息
- (void)configuredScanTool{
    //摄像头采集的内容预览区域
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
}

#pragma mark - Getter
- (AVCaptureSession *)session{
    if (_session == nil){
        //添加一个视频输入设备
        AVCaptureDevice *videoInputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //创建视频输入流
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoInputDevice error:nil];
        if (!videoInput){
            NSLog(@"设备不支持摄像");
            return nil;
        }
        NSError * error = nil;
        //添加一个音频输入设备
        AVCaptureDevice * audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput * audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
        if (error) {
            NSLog(@"获得音频输入设备失败：%@",error.localizedDescription);
        }
        
        //照片输出流
        _capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];
        //        _capturePhotoOutput.livePhotoCaptureEnabled = NO; //是否拍摄 live Photo
        //视频输出流
        _captureMovieFileOutPut = [[AVCaptureMovieFileOutput alloc] init];
        
        // 创建环境光感输出流
        //        AVCaptureVideoDataOutput *lightOutput = [[AVCaptureVideoDataOutput alloc] init];
        //        [lightOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        
        _session = [[AVCaptureSession alloc] init];
        //高质量采集率
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        [_session addInput:videoInput];
        [_session addInput:audioCaptureDeviceInput];
        [_session addOutput:_capturePhotoOutput];
        [_session addOutput:_captureMovieFileOutPut];
        //[_session addOutput:lightOutput];
    }
    return _session;
}
- (UIButton *)backBtn {
    if (_backBtn == nil) {
        _backBtn = [[UIButton alloc] init];
        _backBtn.frame = CGRectMake(0, 0, 30, 30);
        _backBtn.center = CGPointMake(self.view.frame.size.width/3/2.0, self.view.frame.size.height - 80);
        [_backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}
- (UIView *)shotBtn {
    if (_shotBtn == nil) {
        _shotBtn = [[SLBlurView alloc] init];
        _shotBtn.userInteractionEnabled = YES;
        _shotBtn.frame = CGRectMake(0, 0, 70, 70);
        _shotBtn.center = CGPointMake(self.view.frame.size.width/2.0, self.view.frame.size.height - 80);
        _shotBtn.clipsToBounds = YES;
        _shotBtn.layer.cornerRadius = _shotBtn.sl_w/2.0;
        //轻触拍照，长按摄像
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePicture:)];
        [_shotBtn addGestureRecognizer:tap];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(videotape:)];
        [_shotBtn addGestureRecognizer:longPress];
        //中心白色
        self.whiteView.frame = CGRectMake(0, 0, 50, 50);
        self.whiteView.center = CGPointMake(_shotBtn.sl_w/2.0, _shotBtn.sl_h/2.0);
        self.whiteView.layer.cornerRadius = self.whiteView.frame.size.width/2.0;
        [_shotBtn addSubview:self.whiteView];
    }
    return _shotBtn;
}
- (UIView *)whiteView {
    if (_whiteView == nil) {
        _whiteView = [UIView new];
        _whiteView.backgroundColor = [UIColor whiteColor];
    }
    return _whiteView;
}

- (CAShapeLayer *)progressLayer {
    if (_progressLayer == nil) {
        //设置画笔路径
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.shotBtn.frame.size.width/2.0, self.shotBtn.frame.size.height/2.0) radius:self.shotBtn.frame.size.width/2.0 startAngle:- M_PI_2 endAngle:-M_PI_2 + M_PI * 2 clockwise:YES];
        //按照路径绘制圆环
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = _shotBtn.bounds;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineWidth = 10;
        //线头的样式
        _progressLayer.lineCap = kCALineCapButt;
        //圆环颜色
        _progressLayer.strokeColor = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1].CGColor;;
        _progressLayer.strokeStart = 0;
        _progressLayer.strokeEnd = 0;
        //path 决定layer将被渲染成何种形状
        _progressLayer.path = path.CGPath;
    }
    return _progressLayer;
}
- (SLBlurView *)editBtn {
    if (_editBtn == nil) {
        _editBtn = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _editBtn.center = CGPointMake(self.view.sl_w/2.0, self.view.sl_h - 80);
        _editBtn.hidden = YES;
        _editBtn.backgroundColor = [UIColor clearColor];
        _editBtn.layer.cornerRadius = _editBtn.sl_w/2.0;
//        UIButton * btn = [[UIButton alloc] initWithFrame:_editBtn.bounds];
//        [btn setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
//        [btn addTarget:self action:@selector(editBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [_editBtn addSubview:btn];
    }
    return _editBtn;
}
- (SLBlurView *)cancleBtn {
    if (_cancleBtn == nil) {
        _cancleBtn = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _cancleBtn.center = CGPointMake(self.view.sl_w/2/2.0, self.view.sl_h - 80);
        _cancleBtn.hidden = YES;
        _cancleBtn.layer.cornerRadius = _cancleBtn.sl_w/2.0;
        _cancleBtn.backgroundColor = [UIColor clearColor];
//        UIButton * btn = [[UIButton alloc] initWithFrame:_cancleBtn.bounds];
//        [btn setImage:[UIImage imageNamed:@"cancle"] forState:UIControlStateNormal];
//        [btn addTarget:self action:@selector(cancleBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [_cancleBtn addSubview:btn];
    }
    return _cancleBtn;
}
- (UIButton *)saveBtn {
    if (_saveBtn == nil) {
        _saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _saveBtn.center = CGPointMake(self.view.sl_w/2.0 + self.view.sl_w/2/2.0, self.view.sl_h - 80);
        _saveBtn.hidden = YES;
        _saveBtn.layer.cornerRadius = _saveBtn.sl_w/2.0;
        _saveBtn.backgroundColor = [UIColor whiteColor];
        [_saveBtn setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(saveBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

#pragma mark - HelpMethods
//开始计时
- (void)startTimer{
    /** 创建定时器对象
     * para1: DISPATCH_SOURCE_TYPE_TIMER 为定时器类型
     * para2-3: 中间两个参数对定时器无用
     * para4: 最后为在什么调度队列中使用
     */
    _gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    /** 设置定时器
     * para2: 任务开始时间
     * para3: 任务的间隔
     * para4: 可接受的误差时间，设置0即不允许出现误差
     * Tips: 单位均为纳秒
     */
    //定时器延迟时间
    NSTimeInterval delayTime = 0.f;
    //定时器间隔时间
    NSTimeInterval timeInterval = 0.1f;
    //设置开始时间
    dispatch_time_t startDelayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC));
    dispatch_source_set_timer(_gcdTimer, startDelayTime, timeInterval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    /** 设置定时器任务
     * 可以通过block方式
     * 也可以通过C函数方式
     */
    //    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_gcdTimer, ^{
        self->_durationOfVideo+= timeInterval;
        dispatch_async(dispatch_get_main_queue(), ^{
            //主线程更新UI
            self.progressLayer.strokeEnd = self->_durationOfVideo/KMaxDurationOfVideo;
        });
        
        if(self->_durationOfVideo > KMaxDurationOfVideo) {
            NSLog(@"时长 %f", self->_durationOfVideo);
            dispatch_async(dispatch_get_main_queue(), ^{
                //主线程更新UI
                self.progressLayer.strokeEnd = 1;
            });
            //暂停定时器
            // dispatch_suspend(_gcdTimer);
            //取消计时器
            dispatch_source_cancel(self->_gcdTimer);
            self->_durationOfVideo = 0;
            [self.progressLayer removeFromSuperlayer];
            //停止录制
            if ([self.captureMovieFileOutPut isRecording]) {
                [self.captureMovieFileOutPut stopRecording];
            }
        }
    });
    // 启动任务，GCD计时器创建后需要手动启动
    dispatch_resume(_gcdTimer);
}

#pragma mark - EventsHandle
- (void)backBtn:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//编辑
- (void)editBtnClicked:(id)sender {
    
}
//取消
- (void)cancleBtnClicked:(id)sender {
    [self.session startRunning];
    
    self.cancleBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.saveBtn.hidden = YES;
    self.backBtn.hidden = NO;
    self.shotBtn.hidden = NO;
    
}
//保存
- (void)saveBtnClicked:(id)sender {
    if(self.image) {
        //存到相册
        UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
    }
}
//保存图片完成后调用的方法
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    if (error) {
        NSLog(@"保存图片出错%@", error.localizedDescription);
    } else {
        NSLog(@"保存图片成功");
    }
}
//轻触拍照
- (void)takePicture:(UITapGestureRecognizer *)tap {
    //输出设置 默认 flashMode：取值AVCaptureFlashModeAuto  autoStillImageStabilizationEnabled：取值YES
    AVCapturePhotoSettings *capturePhotoSettings = [AVCapturePhotoSettings photoSettings];
    //    capturePhotoSettings.highResolutionPhotoEnabled = YES; //高分辨率
    [_capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
    NSLog(@"拍照");
}
//长按摄像 小视频
- (void)videotape:(UILongPressGestureRecognizer *)longPress {
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:{
            self.shotBtn.sl_size = CGSizeMake(100, 100);
            self.shotBtn.center = CGPointMake(self.view.sl_w/2.0, self.view.sl_h - 80);
            self.shotBtn.layer.cornerRadius =  self.shotBtn.sl_h/2.0;
            self.whiteView.sl_size = CGSizeMake(40, 40);
            self.whiteView.center = CGPointMake(self.shotBtn.sl_w/2.0, self.shotBtn.sl_h/2.0);
            self.whiteView.layer.cornerRadius = self.whiteView.sl_w/2.0;
            //开始计时
            [self startTimer];
            //添加进度条
            [self.shotBtn.layer addSublayer:self.progressLayer];
            self.progressLayer.strokeEnd = 0;
            
            //根据设备输出获得连接
            AVCaptureConnection * captureConnection = [_captureMovieFileOutPut connectionWithMediaType:AVMediaTypeVideo];
            if ([captureConnection isVideoStabilizationSupported]) {
                captureConnection.preferredVideoStabilizationMode= AVCaptureVideoStabilizationModeAuto;
            }
            //根据连接取得设备输出的数据
            if (![self.captureMovieFileOutPut isRecording]) {
                //预览图层和视频方向保持一致
                //                captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
                //临时存储路径
                NSString *outputVideoFielPath = [NSTemporaryDirectory() stringByAppendingString:@"myMovie.mov"];
                NSURL *fileUrl=[NSURL fileURLWithPath:outputVideoFielPath];
                [self.captureMovieFileOutPut startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
            }
        }
            //            NSLog(@"开始摄像");
            break;
        case UIGestureRecognizerStateChanged:{
        }
            //            NSLog(@"正在摄像");
            break;
        case UIGestureRecognizerStateEnded:{
            self.shotBtn.sl_size = CGSizeMake(70, 70);
            self.shotBtn.center = CGPointMake(self.view.sl_w/2.0, self.view.sl_h - 80);
            self.shotBtn.layer.cornerRadius =  self.shotBtn.sl_h/2.0;
            self.whiteView.sl_size = CGSizeMake(50, 50);
            self.whiteView.center = CGPointMake(self.shotBtn.sl_w/2.0, self.shotBtn.sl_h/2.0);
            self.whiteView.layer.cornerRadius = self.whiteView.sl_w/2.0;
            //取消计时器
            dispatch_source_cancel(self->_gcdTimer);
            self->_durationOfVideo = 0;
            self.progressLayer.strokeEnd = 0;
            [self.progressLayer removeFromSuperlayer];
            
            //停止录制
            if ([self.captureMovieFileOutPut isRecording]) {
                [self.captureMovieFileOutPut stopRecording];
            }
        }
            //            NSLog(@"结束摄像");
            break;
        default:
            break;
    }
}

//#pragma mark - AVCaptureMetadataOutputObjectsDelegate
////扫描完成后执行
//-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
//
//    if (metadataObjects.count > 0){
//        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
//        // 扫描完成后的字符
//        //        NSLog(@"扫描出 %@",metadataObject.stringValue);
//    }
//}

#pragma mark - AVCapturePhotoCaptureDelegate 图片输出代理
//捕获拍摄图片的回调
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0)) {
    NSData *data = [photo fileDataRepresentation];
    self.image = [UIImage imageWithData:data];
    [self.session stopRunning];
    
    self.cancleBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.saveBtn.hidden = NO;
    self.backBtn.hidden = YES;
    self.shotBtn.hidden = YES;
}
#pragma mark - AVCaptureFileOutputRecordingDelegate 视频输出代理
//开始录制
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制");
}
//视频录制完成
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
    self.cancleBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.saveBtn.hidden = NO;
    self.backBtn.hidden = YES;
    self.shotBtn.hidden = YES;
    
    return;
    //视频录入完成之后在将视频保存到相簿  如果视频过大的话，建议创建一个后台任务去保存到相册
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"视频保存至相册 成功");
        } else {
            NSLog(@"保存视频到相册 失败 ");
        }
    }];
}

/*
 #pragma mark- AVCaptureVideoDataOutputSampleBufferDelegate的方法
 //采集数据过程中
 - (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
 
 CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
 NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
 CFRelease(metadataDict);
 NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
 float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
 
 //    NSLog(@"环境光感 ： %f",brightnessValue);
 
 // 根据brightnessValue的值来判断是否需要打开和关闭闪光灯
 AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
 BOOL result = [device hasTorch];// 判断设备是否有闪光灯
 if ((brightnessValue < 0) && result) {
 // 环境太暗，可以打开闪光灯了
 }else if((brightnessValue > 0) && result){
 // 环境亮度可以
 }
 
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
