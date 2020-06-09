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
#import "SLWaterMarkController.h"
#import "SLEditImageController.h"
#import "UIView+SLImage.h"
#import "GPUImage.h"
#import <CoreMotion/CoreMotion.h>

#define KMaxDurationOfVideo  15.0 //录制最大时长 s
#define KRecordVideoFilePath  [NSTemporaryDirectory() stringByAppendingString:@"myVideo.mp4"]  //视频录制输出地址

@interface SLGPUImageController ()<GPUImageVideoCameraDelegate>
{
    dispatch_source_t _gcdTimer; //计时器
    NSTimeInterval _durationOfVideo;  //录制视频的时长
}
//GPUImageStillCamera 继承自 GPUImageVideoCamera
@property (nonatomic, strong) GPUImageStillCamera* videoCamera; //相机
@property (nonatomic, strong) GPUImageView *captureView; //预览视图
@property (nonatomic, strong) GPUImageFilter *filter; //原图像
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter; //视频写入
@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter; // 混合滤镜  混合视频帧和水印
@property (nonatomic, strong) NSArray *filterArray;  //滤镜集合

@property (nonatomic, strong) UIButton *switchCameraBtn; // 切换前后摄像头
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *switchFilter; //随机切换滤镜

@property (nonatomic, strong) SLBlurView *shotBtn; //拍摄按钮
@property (nonatomic, strong) UIView *whiteView; //白色圆心
@property (nonatomic, strong) CAShapeLayer *progressLayer; //环形进度条
@property (nonatomic, strong)  UILabel *tipsLabel; //拍摄提示语  轻触拍照 长按拍摄

@property (nonatomic, assign) CGFloat currentZoomFactor; //当前焦距比例系数
@property (nonatomic, strong) SLShotFocusView *focusView;   //当前聚焦视图

@property (nonatomic, strong) CMMotionManager *motionManager;  //运动传感器  监测设备方向
@property (nonatomic, assign) UIDeviceOrientation shootingOrientation;// 拍摄时的设备方向 开始录制时停止更新
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
    [self.filter addTarget:self.captureView];
    [self.videoCamera addTarget:self.filter];
    [self.videoCamera startCameraCapture];
    [self.view insertSubview:self.captureView atIndex:0];
    [self focusAtPoint:CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight/2.0)];
    //监听设备方向，旋转切换摄像头按钮
    [self startUpdateDeviceDirection];
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
    [self stopUpdateDeviceDirection];
    [SLDelayPerform sl_cancelDelayPerform];
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
    [_videoCamera removeAllTargets];
    [_filter removeAllTargets];
    _filter = nil;
    _videoCamera.delegate = nil;
    _videoCamera = nil;
    //移除重复文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:KRecordVideoFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:KRecordVideoFilePath error:nil];
    }
    NSLog(@"GPUImage相机视图释放");
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
- (GPUImageStillCamera *)videoCamera {
    if (!_videoCamera) {
        _videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
        //设置输出图像方向，可用于横屏推流。
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        //镜像策略，这里这样设置是最自然的。跟系统相机默认一样。
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        // 可防止允许声音通过的情况下,避免第一帧黑屏
        [_videoCamera addAudioInputsAndOutputs];
        _videoCamera.delegate = self;
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
        _filter = [[GPUImageFilter alloc] init];
    }
    return _filter;
}
- (GPUImageMovieWriter *)movieWriter {
    if (!_movieWriter) {
        //一般编/解码器都有16位对齐的处理（有未经证实的说法，也存在32位、64位对齐的），否则会产生绿边问题。
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:KRecordVideoFilePath] size:CGSizeMake((SL_kScreenWidth - (int)SL_kScreenWidth%16)*[UIScreen mainScreen].scale, (SL_kScreenHeight - (int)SL_kScreenHeight%16)*[UIScreen mainScreen].scale)];
        _movieWriter.encodingLiveVideo = YES;
        _movieWriter.shouldPassthroughAudio = YES;
    }
    return _movieWriter;
}
- (GPUImageAlphaBlendFilter *)blendFilter {
    if (!_blendFilter) {
        // 混合滤镜，它会把水印层图像和视频帧图像混合：GPUImageNormalBlendFilter 就是把水印层图像添加到视频帧上，不做其他处理；GPUImageAlphaBlendFilter 水印层上的内容处于半透明的状态； GPUImageAddBlendFilter 水印层图像会受到视频帧本身滤镜的影响；GPUImageDissolveBlendFilter会造成视频帧变暗
        _blendFilter  = [[GPUImageAlphaBlendFilter alloc] init];
    }
    return _blendFilter;
}
- (UIButton *)backBtn {
    if (_backBtn == nil) {
        _backBtn = [[UIButton alloc] init];
        _backBtn.frame = CGRectMake(0, 0, 30, 30);
        _backBtn.center = CGPointMake((self.view.sl_width/2 - 70/2.0)/2.0, self.view.sl_height - 80);
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
        _shotBtn.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height - 80);
        _shotBtn.clipsToBounds = YES;
        _shotBtn.layer.cornerRadius = _shotBtn.sl_width/2.0;
        //轻触拍照，长按摄像
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePicture:)];
        [_shotBtn addGestureRecognizer:tap];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recordVideo:)];
        longPress.minimumPressDuration = 0.3;
        [_shotBtn addGestureRecognizer:longPress];
        //中心白色
        self.whiteView.frame = CGRectMake(0, 0, 50, 50);
        self.whiteView.center = CGPointMake(_shotBtn.sl_width/2.0, _shotBtn.sl_height/2.0);
        self.whiteView.layer.cornerRadius = self.whiteView.frame.size.width/2.0;
        [_shotBtn addSubview:self.whiteView];
    }
    return _shotBtn;
}
- (UIButton *)switchCameraBtn {
    if (_switchCameraBtn == nil) {
        _switchCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.sl_width - 30 - 30, 44 , 30, 30)];
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
        _tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.sl_width - 140)/2.0, self.shotBtn.sl_y - 20 - 30, 140, 20)];
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
        //高斯模糊滤镜
        GPUImageGaussianBlurFilter *blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
        blurFilter.blurRadiusInPixels = 10;
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
        _filterArray = @[stretchDistortionFilter,BrightnessFilter,blurFilter,sepiaFilter,invertFilter,saturationFilter,sketchFilter,thresholdFilter];
    }
    return _filterArray;
}
- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}
#pragma mark - Setter
- (void)setShootingOrientation:(UIDeviceOrientation)shootingOrientation {
    _shootingOrientation = shootingOrientation;
    [UIView animateWithDuration:0.3 animations:^{
        switch (shootingOrientation) {
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
                //暂停定时器
                // dispatch_suspend(_gcdTimer);
                //取消计时器
                dispatch_source_cancel(self->_gcdTimer);
                self->_durationOfVideo = 0;
                [self.progressLayer removeFromSuperlayer];
                //停止录制
                [self endRecord];
            });
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
    //把采集的音频交给self.movieWriter 写入
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    //调整写入时的方向
    CGAffineTransform transform;
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight) {
        transform = CGAffineTransformMakeRotation(M_PI/2);
    } else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft) {
        transform = CGAffineTransformMakeRotation(-M_PI/2);
    } else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        transform = CGAffineTransformMakeRotation(M_PI);
    } else {
        transform = CGAffineTransformMakeRotation(0);
    }
    [self stopUpdateDeviceDirection];
    //边添加水印边录制
    [self addWatermark];
    [self.movieWriter startRecordingInOrientation:transform];
}
//结束录制
- (void)endRecord {
    [self.movieWriter finishRecording];
    [self.videoCamera stopCameraCapture];
    [self stopUpdateDeviceDirection];
    [self.filter removeTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
    _movieWriter = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:KRecordVideoFilePath]) {
        SLWaterMarkController * waterMarkController = [[SLWaterMarkController alloc] init];
        waterMarkController.videoPath = [NSURL fileURLWithPath:KRecordVideoFilePath];
        waterMarkController.modalPresentationStyle = UIModalPresentationFullScreen;
        waterMarkController.videoOrientation = self.shootingOrientation;
        [self presentViewController:waterMarkController animated:NO completion:^{
            NSString *result = @"录制成功";
            NSLog(@"%@", result);
            [SLAlertView showAlertViewWithText:result delayHid:1];
        }];
    }else {
         [SLAlertView showAlertViewWithText:@"录制失败" delayHid:1];
    }
}
// 添加水印
- (void)addWatermark {
    //调整水印方向
    CGAffineTransform transform;
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight) {
        transform = CGAffineTransformMakeRotation(M_PI*3/2);
    } else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft) {
        transform = CGAffineTransformMakeRotation(-M_PI*3/2);
    } else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        transform = CGAffineTransformMakeRotation(M_PI);
    } else {
        transform = CGAffineTransformMakeRotation(0);
    }
    // 水印层
    UIView *watermarkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.sl_width, self.view.sl_height)];
    watermarkView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 80)];
    label.text = @"iOS2679114653";
    label.font = [UIFont systemFontOfSize:30];
    [label sizeToFit];
    label.center = CGPointMake(SL_kScreenWidth/2.0, 88);
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor purpleColor];
    [watermarkView addSubview:label];
    label.transform = transform;
    //GPUImageUIElement继承GPUImageOutput类，作为响应链的源头。通过CoreGraphics把UIView渲染到图像，并通过glTexImage2D绑定到outputFramebuffer指定的纹理，最后通知targets纹理就绪。
    GPUImageUIElement *uielement = [[GPUImageUIElement alloc] initWithView:watermarkView];
    //每一帧渲染完毕后的回调
    [self.filter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        SL_DISPATCH_ON_MAIN_THREAD(^{
            label.sl_y = label.sl_y < SL_kScreenHeight ? label.sl_y + 5 : label.sl_y - 5;
        })
        //需要调用update操作：因为update只会输出一次纹理信息，只适用于一帧，所以需要实时更新水印层图像
        [uielement updateWithTimestamp:time];
    }];
    // 把原视频帧图像和水印层图像 输出给 混合滤镜进行渲染写入处理
    [self.filter addTarget:self.blendFilter];
    [uielement addTarget:self.blendFilter];
    // 混合滤镜输出 给movieWriter写入
    [self.blendFilter addTarget:self.movieWriter];
    
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
    if(point.y > self.shotBtn.sl_y || point.y < self.switchCameraBtn.sl_y + self.switchCameraBtn.sl_height) {
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
    [SLDelayPerform sl_startDelayPerform:^{
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
    [self.videoCamera removeTarget:self.filter];
    [self.videoCamera addTarget:filter];
    [filter addTarget:self.captureView];
    self.filter = filter;
    [self addWatermark];
}
//轻触拍照
- (void)takePicture:(UITapGestureRecognizer *)tap {
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (self.shootingOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            imageOrientation = UIImageOrientationLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            imageOrientation = UIImageOrientationRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            imageOrientation = UIImageOrientationDown;
            break;
        default:
            break;
    }
    SL_WeakSelf;
    [self.videoCamera capturePhotoAsJPEGProcessedUpToFilter:weakSelf.filter withOrientation:imageOrientation withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
        if(error){
            NSLog(@"拍照失败");
            return;
        }
        NSLog(@"拍照结束");
        SLEditImageController * editViewController = [[SLEditImageController alloc] init];
        editViewController.image = [UIImage imageWithData:processedJPEG];
        editViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [weakSelf presentViewController:editViewController animated:NO completion:nil];
        [self.videoCamera stopCameraCapture];
    }];
    
}
//长按摄像 小视频
- (void)recordVideo:(UILongPressGestureRecognizer *)longPress {
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:{
            self.shotBtn.sl_size = CGSizeMake(100, 100);
            self.shotBtn.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height - 80);
            self.shotBtn.layer.cornerRadius =  self.shotBtn.sl_height/2.0;
            self.whiteView.sl_size = CGSizeMake(40, 40);
            self.whiteView.center = CGPointMake(self.shotBtn.sl_width/2.0, self.shotBtn.sl_height/2.0);
            self.whiteView.layer.cornerRadius = self.whiteView.sl_width/2.0;
            //开始计时
            [self startTimer];
            //添加进度条
            [self.shotBtn.layer addSublayer:self.progressLayer];
            self.progressLayer.strokeEnd = 0;
            
            //开始录制视频
            [self startRecord];
        }
            NSLog(@"开始摄像");
            break;
        case UIGestureRecognizerStateChanged:{
        }
            //            NSLog(@"正在摄像");
            break;
        case UIGestureRecognizerStateEnded:{
            self.shotBtn.sl_size = CGSizeMake(70, 70);
            self.shotBtn.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height - 80);
            self.shotBtn.layer.cornerRadius =  self.shotBtn.sl_height/2.0;
            self.whiteView.sl_size = CGSizeMake(50, 50);
            self.whiteView.center = CGPointMake(self.shotBtn.sl_width/2.0, self.shotBtn.sl_height/2.0);
            self.whiteView.layer.cornerRadius = self.whiteView.sl_width/2.0;
            //取消计时器
            dispatch_source_cancel(self->_gcdTimer);
            self->_durationOfVideo = 0;
            self.progressLayer.strokeEnd = 0;
            [self.progressLayer removeFromSuperlayer];
            //    结束录制视频
            [self endRecord];
            NSLog(@"结束录制");
        }
            break;
        default:
            break;
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

#pragma mark - GPUImageVideoCameraDelegate 音视频实时输出代理
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
}

@end
