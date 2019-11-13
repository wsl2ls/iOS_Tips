//
//  SLGPUImageController.m
//  DarkMode
//
//  Created by wsl on 2019/11/11.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLGPUImageController.h"
#import <GPUImage.h>
#import "SLBlurView.h"
#import "SLShotFocusView.h"
#import "SLEditVideoController.h"
#import "NSObject+SLDelayPerform.h"
#import "SLEditImageController.h"
#import "SLAvCaptureSession.h"
#import "SLAvWriterInput.h"
#import <GPUImage.h>

#define KMaxDurationOfVideo  15.0 //录制最大时长 s
#define KRecordVideoFilePath  [NSTemporaryDirectory() stringByAppendingString:@"myVideo.mp4"]

#define COMPRESSEDVIDEOPATH [NSHomeDirectory() stringByAppendingFormat:@"/Documents/CompressionVideoField"]

@interface SLGPUImageController ()<GPUImageVideoCameraDelegate>
{
    dispatch_source_t _gcdTimer; //计时器
    NSTimeInterval _durationOfVideo;  //录制视频的时长
}

@property (nonatomic, strong) GPUImageVideoCamera* videoCamera; //相机
@property (nonatomic, strong) GPUImageView *captureView; //预览视图
@property (nonatomic, strong) GPUImageFilter *filter; //饱和度滤镜
@property (nonatomic,strong) GPUImageMovieWriter *movieWriter; //视频写入

@property (nonatomic, strong) UIButton *switchCameraBtn; // 切换前后摄像头
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *switchFilter; //随机切换滤镜

@property (nonatomic, strong) SLBlurView *shotBtn; //拍摄按钮
@property (nonatomic, strong) UIView *whiteView; //白色圆心
@property (nonatomic, strong) CAShapeLayer *progressLayer; //环形进度条
@property (nonatomic, strong)  UILabel *tipsLabel; //拍摄提示语  轻触拍照 长按拍摄

@property (nonatomic, strong) UIImage *image; //当前拍摄的照片
@property (nonatomic, strong) NSURL *videoPath; //当前拍摄的视频路径

@property (nonatomic, assign) CGFloat currentZoomFactor; //当前焦距比例系数
@property (nonatomic, strong) SLShotFocusView *focusView;   //当前聚焦视图

@property (nonatomic, assign) BOOL isRecording; //是否正在录制

@property (nonatomic, strong) NSArray *filterArray;

@end

@implementation SLGPUImageController

#pragma mark - Override
- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.image = nil;
    self.videoPath = nil;
    [self.videoCamera startCameraCapture];
    [self.view insertSubview:self.captureView atIndex:0];
    [self focusAtPoint:CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight/2.0)];
    //监听设备方向，旋转切换摄像头按钮
    //    [self.avCaptureSession addObserver:self forKeyPath:@"shootingOrientation" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_gcdTimer) {
        dispatch_source_cancel(_gcdTimer);
        _gcdTimer = nil;
    }
    [_videoCamera stopCameraCapture];
    //    [_avCaptureSession removeObserver:self forKeyPath:@"shootingOrientation"];
    [NSObject sl_cancelDelayPerform];
}
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    UIEdgeInsets insets = self.view.safeAreaInsets;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)dealloc {
    _videoCamera.delegate = nil;
    _videoCamera = nil;
    NSLog(@"GPUImage视图释放");
}
#pragma mark - UI
- (void)setupUI {
    self.title = @"拍摄";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.shotBtn];
    [self.view addSubview:self.switchCameraBtn];
    [self.view addSubview:self.switchFilter];
    
    [self.view addSubview:self.tipsLabel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tipsLabel removeFromSuperview];
    });
}

#pragma mark - Getter
- (GPUImageVideoCamera *)videoCamera {
    if (!_videoCamera) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
        //设置输出图像方向，可用于横屏推流。
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        //镜像策略，这里这样设置是最自然的。跟系统相机默认一样。
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        [_videoCamera addTarget:self.filter];
        // 可防止允许声音通过的情况下,避免第一帧黑屏
        [_videoCamera addAudioInputsAndOutputs];
    }
    return _videoCamera;
}
- (GPUImageView *)captureView {
    if (!_captureView) {
        _captureView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight)];
        _captureView.backgroundColor = [UIColor blackColor];
        _captureView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFocusing:)];
        [_captureView addGestureRecognizer:tap];
        UIPinchGestureRecognizer  *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchFocalLength:)];
        [_captureView addGestureRecognizer:pinch];
    }
    return _captureView;
}
- (GPUImageFilter *)filter {
    if (!_filter) {
        _filter = [[GPUImageSaturationFilter alloc] init];
        [_filter addTarget:self.captureView];
    }
    return _filter;
}
- (GPUImageMovieWriter *)movieWriter {
    if (!_movieWriter) {
        self.videoPath = [NSURL fileURLWithPath:KRecordVideoFilePath];
        //一般编/解码器都有16位对齐的处理（有未经证实的说法，也存在32位、64位对齐的），否则会产生绿边问题。
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.videoPath size:CGSizeMake((SL_kScreenWidth - (int)SL_kScreenWidth%16)*[UIScreen mainScreen].scale, (SL_kScreenHeight - (int)SL_kScreenHeight%16)*[UIScreen mainScreen].scale)];
        _movieWriter.encodingLiveVideo = YES;
        _movieWriter.shouldPassthroughAudio = YES;
    }
    return _movieWriter;
}
- (UIButton *)backBtn {
    if (_backBtn == nil) {
        _backBtn = [[UIButton alloc] init];
        _backBtn.frame = CGRectMake(0, 0, 30, 30);
        _backBtn.center = CGPointMake((self.view.sl_w/2 - 70/2.0)/2.0, self.view.sl_h - 80);
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
        _shotBtn.center = CGPointMake(self.view.sl_w/2.0, self.view.sl_h - 80);
        _shotBtn.clipsToBounds = YES;
        _shotBtn.layer.cornerRadius = _shotBtn.sl_w/2.0;
        //轻触拍照，长按摄像
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePicture:)];
        [_shotBtn addGestureRecognizer:tap];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recordVideo:)];
        longPress.minimumPressDuration = 0.3;
        [_shotBtn addGestureRecognizer:longPress];
        //中心白色
        self.whiteView.frame = CGRectMake(0, 0, 50, 50);
        self.whiteView.center = CGPointMake(_shotBtn.sl_w/2.0, _shotBtn.sl_h/2.0);
        self.whiteView.layer.cornerRadius = self.whiteView.frame.size.width/2.0;
        [_shotBtn addSubview:self.whiteView];
    }
    return _shotBtn;
}
- (UIButton *)switchCameraBtn {
    if (_switchCameraBtn == nil) {
        _switchCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.sl_w - 30 - 30, 44 , 30, 30)];
        [_switchCameraBtn setImage:[UIImage imageNamed:@"cameraAround"] forState:UIControlStateNormal];
        [_switchCameraBtn addTarget:self action:@selector(switchCameraClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraBtn;
}
- (UIButton *)switchFilter {
    if (_switchFilter == nil) {
        _switchFilter = [[UIButton alloc] initWithFrame:CGRectMake( 30, 44 , 80, 30)];
        [_switchFilter setTitle:@"切换滤镜" forState:UIControlStateNormal];
        [_switchFilter setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _switchFilter.titleLabel.font = [UIFont systemFontOfSize:16];
        [_switchFilter addTarget:self action:@selector(switchFilterClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchFilter;
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
        _progressLayer.strokeColor = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1].CGColor;
        _progressLayer.strokeStart = 0;
        _progressLayer.strokeEnd = 0;
        //path 决定layer将被渲染成何种形状
        _progressLayer.path = path.CGPath;
    }
    return _progressLayer;
}
- (SLShotFocusView *)focusView {
    if (_focusView == nil) {
        _focusView= [[SLShotFocusView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    }
    return _focusView;
}
- (UILabel *)tipsLabel {
    if (_tipsLabel == nil) {
        _tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.sl_w - 140)/2.0, self.shotBtn.sl_y - 20 - 30, 140, 20)];
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.font = [UIFont systemFontOfSize:14];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.text = @"轻触拍照，按住摄像";
    }
    return  _tipsLabel;
}
- (NSArray *)filterArray {
    if (!_filterArray) {
        _filterArray = [NSMutableArray array];
        //哈哈镜效果
        GPUImageStretchDistortionFilter *stretchDistortionFilter = [[GPUImageStretchDistortionFilter alloc] init];
        //亮度
        GPUImageBrightnessFilter *BrightnessFilter = [[GPUImageBrightnessFilter alloc] init];
        //伽马线滤镜
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        //边缘检测
        GPUImageXYDerivativeFilter *XYDerivativeFilter = [[GPUImageXYDerivativeFilter alloc] init];
        //怀旧
        GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
        //反色
        GPUImageColorInvertFilter *invertFilter = [[GPUImageColorInvertFilter alloc] init];
        //饱和度
        GPUImageSaturationFilter *saturationFilter = [[GPUImageSaturationFilter alloc] init];
        //素描
        GPUImageSketchFilter *sketchFilter = [[GPUImageSketchFilter alloc] init];
        //黑白
        GPUImageMonochromeFilter *thresholdFilter = [[GPUImageMonochromeFilter alloc] init];
        // 滤镜数组
        _filterArray = @[stretchDistortionFilter,BrightnessFilter,gammaFilter,XYDerivativeFilter,sepiaFilter,invertFilter,saturationFilter,sketchFilter,thresholdFilter];
    }
    return _filterArray;
}

#pragma mark - HelpMethods
//最小缩放值 焦距
- (CGFloat)minZoomFactor {
    CGFloat minZoomFactor = 1.0;
    if (@available(iOS 11.0, *)) {
        minZoomFactor = self.videoCamera.inputCamera.minAvailableVideoZoomFactor;
    }
    return minZoomFactor;
}
//最大缩放值 焦距
- (CGFloat)maxZoomFactor {
    CGFloat maxZoomFactor = self.videoCamera.inputCamera.activeFormat.videoMaxZoomFactor;
    if (@available(iOS 11.0, *)) {
        maxZoomFactor = self.videoCamera.inputCamera.maxAvailableVideoZoomFactor;
    }
    if (maxZoomFactor > 6) {
        maxZoomFactor = 6.0;
    }
    return maxZoomFactor;
}
//开始计时录制
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
        SL_DISPATCH_ON_MAIN_THREAD(^{
            //主线程更新UI
            self.progressLayer.strokeEnd = self->_durationOfVideo/KMaxDurationOfVideo;
        });
        
        if(self->_durationOfVideo > KMaxDurationOfVideo) {
            NSLog(@"时长 %f", self->_durationOfVideo);
            SL_DISPATCH_ON_MAIN_THREAD(^{
                self.progressLayer.strokeEnd = 1;
            });
            
            //暂停定时器
            // dispatch_suspend(_gcdTimer);
            //取消计时器
            dispatch_source_cancel(self->_gcdTimer);
            self->_durationOfVideo = 0;
            [self.progressLayer removeFromSuperlayer];
            //停止录制
            [self endRecord];
            self.isRecording = NO;
        }
    });
    // 启动任务，GCD计时器创建后需要手动启动
    dispatch_resume(_gcdTimer);
}
//开始录制
- (void)startRecord {
    //移除重复文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:KRecordVideoFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:KRecordVideoFilePath error:nil];
    }
    [self.filter addTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    [self.movieWriter startRecording];
    
}
//结束录制
- (void)endRecord {
    [self.movieWriter finishRecording];
    [self.videoCamera stopCameraCapture];
    [self.filter removeTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
    _movieWriter = nil;
    
    // 压缩
    //    [self compressVideoWithUrl:self.videoPath compressionType:AVAssetExportPresetMediumQuality filePath:^(NSString *resultPath, float memorySize, NSString *videoImagePath, int seconds) {
    //        NSData *data = [NSData dataWithContentsOfFile:resultPath];
    //        CGFloat totalTime = (CGFloat)data.length / 1024 / 1024;
    //    }];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:KRecordVideoFilePath]) {
        SLEditVideoController * editViewController = [[SLEditVideoController alloc] init];
        editViewController.videoPath = self.videoPath;
        editViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:editViewController animated:NO completion:nil];
    }
    
}

// 压缩视频
-(void)compressVideoWithUrl:(NSURL *)url compressionType:(NSString *)type filePath:(void(^)(NSString *resultPath,float memorySize,NSString * videoImagePath,int seconds))resultBlock {
    
    NSString *resultPath;
    
    // 视频压缩前大小
    NSData *data = [NSData dataWithContentsOfURL:url];
    CGFloat totalSize = (float)data.length / 1024 / 1024;
    NSLog(@"压缩前大小：%.2fM",totalSize);
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    CMTime time = [avAsset duration];
    
    // 视频时长
    int seconds = ceil(time.value / time.timescale);
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:type]) {
        
        // 中等质量
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        
        // 用时间给文件命名 防止存储被覆盖
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        
        // 若压缩路径不存在重新创建
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isExist = [manager fileExistsAtPath:COMPRESSEDVIDEOPATH];
        if (!isExist) {
            [manager createDirectoryAtPath:COMPRESSEDVIDEOPATH withIntermediateDirectories:YES attributes:nil error:nil];
        }
        resultPath = [COMPRESSEDVIDEOPATH stringByAppendingPathComponent:[NSString stringWithFormat:@"user%outputVideo-%@.mp4",arc4random_uniform(10000),[formatter stringFromDate:[NSDate date]]]];
        
        session.outputURL = [NSURL fileURLWithPath:resultPath];
        session.outputFileType = AVFileTypeMPEG4;
        session.shouldOptimizeForNetworkUse = YES;
        [session exportAsynchronouslyWithCompletionHandler:^{
            
            switch (session.status) {
                case AVAssetExportSessionStatusUnknown:
                    break;
                case AVAssetExportSessionStatusWaiting:
                    break;
                case AVAssetExportSessionStatusExporting:
                    break;
                case AVAssetExportSessionStatusCancelled:
                    break;
                case AVAssetExportSessionStatusFailed:
                    break;
                case AVAssetExportSessionStatusCompleted:{
                    
                    NSData *data = [NSData dataWithContentsOfFile:resultPath];
                    // 压缩过后的大小
                    float compressedSize = (float)data.length / 1024 / 1024;
                    resultBlock(resultPath,compressedSize,@"",seconds);
                    NSLog(@"压缩后大小：%.2f",compressedSize);
                }
                default:
                    break;
            }
        }];
    }
}


#pragma mark - EventsHandle
//返回
- (void)backBtn:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//聚焦手势
- (void)tapFocusing:(UITapGestureRecognizer *)tap {
    //如果没在运行，取消聚焦
    if(!self.videoCamera.captureSession.isRunning) {
        return;
    }
    CGPoint point = [tap locationInView:self.captureView];
    if(point.y > self.shotBtn.sl_y || point.y < self.switchCameraBtn.sl_y + self.switchCameraBtn.sl_h) {
        return;
    }
    [self focusAtPoint:point];
}
//设置焦点视图位置
- (void)focusAtPoint:(CGPoint)point {
    self.focusView.center = point;
    [self.focusView removeFromSuperview];
    [self.view addSubview:self.focusView];
    self.focusView.transform = CGAffineTransformMakeScale(1.3, 1.3);
    [UIView animateWithDuration:0.5 animations:^{
        self.focusView.transform = CGAffineTransformIdentity;
    }];
    NSError *error;
    if([self.videoCamera.inputCamera lockForConfiguration:&error]){
        //对焦模式和对焦点,设定前一定要判断该模式是否支持，如果支持就先设定位置，然后再设定模式，单独设定位置是没有用的。曝光设置跟这里一样的原理
        if([self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [self.videoCamera.inputCamera setFocusPointOfInterest:point];
            [self.videoCamera.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //曝光模式和曝光点
        if([self.videoCamera.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            [self.videoCamera.inputCamera setExposurePointOfInterest:point];
            [self.videoCamera.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        //当你lockForConfiguration后，完成设置后记住一定要unlock
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    SL_WeakSelf;
    [NSObject sl_startDelayPerform:^{
        [weakSelf.focusView removeFromSuperview];
    } afterDelay:1.0];
}
//调节焦距 手势
- (void)pinchFocalLength:(UIPinchGestureRecognizer *)pinch {
    if(pinch.state == UIGestureRecognizerStateBegan) {
        self.currentZoomFactor = self.videoCamera.inputCamera.videoZoomFactor;
    }
    if (pinch.state == UIGestureRecognizerStateChanged) {
        NSError *error;
        if([self.videoCamera.inputCamera lockForConfiguration:&error]){
            if (self.currentZoomFactor * pinch.scale >= [self minZoomFactor] && self.currentZoomFactor * pinch.scale <= [self maxZoomFactor]) {
                self.videoCamera.inputCamera.videoZoomFactor = self.currentZoomFactor * pinch.scale;
            }
            //当你lockForConfiguration后，完成设置后记住一定要unlock
            [self.videoCamera.inputCamera unlockForConfiguration];
        }
    }
}
//切换前/后摄像头
- (void)switchCameraClicked:(id)sender {
    [self.videoCamera rotateCamera];
}
//随机切换滤镜
- (void)switchFilterClicked:(id)sender {
    GPUImageFilter *filter = self.filterArray[arc4random()%self.filterArray.count];
    [self.videoCamera removeAllTargets];
    [self.videoCamera addTarget:filter];
    [filter addTarget:self.captureView];
    self.filter = filter;
}
//轻触拍照
- (void)takePicture:(UITapGestureRecognizer *)tap {
    [self.videoCamera stopCameraCapture];
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    //    switch (self.avCaptureSession.shootingOrientation) {
    //        case UIDeviceOrientationLandscapeLeft:
    //            imageOrientation = UIImageOrientationLeft;
    //            break;
    //        case UIDeviceOrientationLandscapeRight:
    //            imageOrientation = UIImageOrientationRight;
    //            break;
    //        case UIDeviceOrientationPortraitUpsideDown:
    //            imageOrientation = UIImageOrientationDown;
    //            break;
    //        default:
    //            break;
    //    }
    //    UIImage *image = [UIImage imageWithCGImage:self.captureView.image.CGImage scale:[UIScreen mainScreen].scale orientation:imageOrientation];
    //    self.captureView.image = image;
    //    self.image = image;
    
    NSLog(@"拍照结束");
    SLEditImageController * editViewController = [[SLEditImageController alloc] init];
    editViewController.image = self.image;
    editViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:editViewController animated:NO completion:nil];
    NSLog(@"拍照");
}
//长按摄像 小视频
- (void)recordVideo:(UILongPressGestureRecognizer *)longPress {
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
            
            //开始录制视频
            [self startRecord];
            self.isRecording = YES;
        }
            NSLog(@"开始摄像");
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
            //    结束录制视频
            [self endRecord];
            self.isRecording = NO;
            NSLog(@"结束录制");
        }
            break;
        default:
            break;
    }
}
// KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"shootingOrientation"]) {
        UIDeviceOrientation deviceOrientation = [change[@"new"] intValue];
        [UIView animateWithDuration:0.3 animations:^{
            switch (deviceOrientation) {
                case UIDeviceOrientationPortrait:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(0);
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                    break;
                case UIDeviceOrientationLandscapeRight:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    self.switchCameraBtn.transform = CGAffineTransformMakeRotation(-M_PI);
                    break;
                default:
                    break;
            }
        }];
    }
}

#pragma mark - SLAvCaptureSessionDelegate 音视频实时输出代理
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
}

@end
