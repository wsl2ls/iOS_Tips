//
//  SLFilterViewController.m
//  DarkMode
//
//  Created by wsl on 2019/11/7.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLFilterViewController.h"
#import "SLBlurView.h"
#import "SLShotFocusView.h"
#import "SLEditVideoController.h"
#import "SLEditImageController.h"
#import "SLAvCaptureSession.h"
#import "SLAvWriterInput.h"

#define KMaxDurationOfVideo  15.0 //录制最大时长 s

@interface SLFilterViewController ()<SLAvCaptureSessionDelegate, SLAvWriterInputDelegate>
{
    dispatch_source_t _gcdTimer; //计时器
    NSTimeInterval _durationOfVideo;  //录制视频的时长
}

@property (nonatomic, strong) SLAvCaptureSession *avCaptureSession; //摄像头采集工具
@property (nonatomic, strong) SLAvWriterInput *avWriterInput;  //音视频写入输出文件

@property (nonatomic, strong) UIImageView *captureView; // 预览视图
@property (nonatomic, strong) UIButton *switchCameraBtn; // 切换前后摄像头
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *switchFilter; //随机切换滤镜

@property (nonatomic, strong) SLBlurView *shotBtn; //拍摄按钮
@property (nonatomic, strong) UIView *whiteView; //白色圆心
@property (nonatomic, strong) CAShapeLayer *progressLayer; //环形进度条
@property (nonatomic, strong)  UILabel *tipsLabel; //拍摄提示语  轻触拍照 长按拍摄

@property (nonatomic, assign) CGFloat currentZoomFactor; //当前焦距比例系数
@property (nonatomic, strong) SLShotFocusView *focusView;   //当前聚焦视图

@property (nonatomic, assign) BOOL isRecording; //是否正在录制

@property (nonatomic, strong) CIFilter* filter;  //滤镜
@property (nonatomic, strong) NSMutableArray <NSString *> *filterArray;
@property (nonatomic, strong) CIContext* context;

@end

@implementation SLFilterViewController

#pragma mark - OverWrite
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.avCaptureSession startRunning];
    [self focusAtPoint:CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight/2.0)];
    //监听设备方向，旋转切换摄像头按钮
    [self.avCaptureSession addObserver:self forKeyPath:@"shootingOrientation" options:NSKeyValueObservingOptionNew context:nil];
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
    [_avCaptureSession stopRunning];
    [_avCaptureSession removeObserver:self forKeyPath:@"shootingOrientation"];
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
    _avCaptureSession.delegate = nil;
    _avCaptureSession = nil;
    NSLog(@"滤镜视图释放");
}
#pragma mark - UI
- (void)setupUI {
    self.title = @"拍摄";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.captureView];
    
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
- (SLAvCaptureSession *)avCaptureSession {
    if (_avCaptureSession == nil) {
        _avCaptureSession = [[SLAvCaptureSession alloc] init];
        _avCaptureSession.delegate = self;
    }
    return _avCaptureSession;
}
- (SLAvWriterInput *)avWriterInput {
    if (!_avWriterInput) {
        _avWriterInput = [[SLAvWriterInput alloc] init];
        _avWriterInput.videoSize = CGSizeMake(SL_kScreenWidth*0.8, SL_kScreenHeight*0.8);
        _avWriterInput.delegate = self;
    }
    return _avWriterInput;
}
- (UIView *)captureView {
    if (_captureView == nil) {
        _captureView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _captureView.contentMode = UIViewContentModeScaleAspectFit;
        _captureView.backgroundColor = [UIColor blackColor];
        _captureView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFocusing:)];
        [_captureView addGestureRecognizer:tap];
        UIPinchGestureRecognizer  *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchFocalLength:)];
        [_captureView addGestureRecognizer:pinch];
    }
    return _captureView;
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
-(CIContext *)context{
    // default creates a context based on GPU
    if (_context == nil) {
        _context = [CIContext contextWithOptions:nil];
    }
    return _context;
}
- (CIFilter *)filter{
    if (_filter == nil) {
        _filter = [CIFilter filterWithName:self.filterArray[arc4random()%self.filterArray.count]];
    }
    return _filter;
}
- (NSMutableArray *)filterArray {
    if (!_filterArray) {
        _filterArray = [NSMutableArray array];
        [_filterArray addObject:@"CIPhotoEffectFade"];
        [_filterArray addObject:@"CIColorInvert"];
        [_filterArray addObject:@"CIPhotoEffectTonal"];
        [_filterArray addObject:@"CIPhotoEffectProcess"];
        [_filterArray addObject:@"CIPhotoEffectChrome"];
        [_filterArray addObject:@"CIPhotoEffectTransfer"];
        [_filterArray addObject:@"CIPhotoEffectNoir"];
        [_filterArray addObject:@"CIPhotoEffectInstant"];
    }
    return _filterArray;
}

#pragma mark - HelpMethods
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
                [self.avWriterInput finishWriting];
                [self.avCaptureSession stopRunning];
                self.isRecording = NO;
            });
        }
    });
    // 启动任务，GCD计时器创建后需要手动启动
    dispatch_resume(_gcdTimer);
}

#pragma mark - EventsHandle
//返回
- (void)backBtn:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//聚焦手势
- (void)tapFocusing:(UITapGestureRecognizer *)tap {
    //如果没在运行，取消聚焦
    if(!self.avCaptureSession.isRunning) {
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
    [self.avCaptureSession focusAtPoint:point];
    SL_WeakSelf;
    [SLDelayPerform sl_startDelayPerform:^{
        [weakSelf.focusView removeFromSuperview];
    } afterDelay:1.0];
}
//调节焦距 手势
- (void)pinchFocalLength:(UIPinchGestureRecognizer *)pinch {
    if(pinch.state == UIGestureRecognizerStateBegan) {
        self.currentZoomFactor = self.avCaptureSession.videoZoomFactor;
    }
    if (pinch.state == UIGestureRecognizerStateChanged) {
        self.avCaptureSession.videoZoomFactor = self.currentZoomFactor * pinch.scale;
    }
}
//切换前/后摄像头
- (void)switchCameraClicked:(id)sender {
    if (self.avCaptureSession.devicePosition == AVCaptureDevicePositionFront) {
        [self.avCaptureSession switchsCamera:AVCaptureDevicePositionBack];
    } else if(self.avCaptureSession.devicePosition == AVCaptureDevicePositionBack) {
        [self.avCaptureSession switchsCamera:AVCaptureDevicePositionFront];
    }
}
//随机切换滤镜
- (void)switchFilterClicked:(id)sender {
    _filter = [CIFilter filterWithName:self.filterArray[arc4random()%self.filterArray.count]];
}
//轻触拍照
- (void)takePicture:(UITapGestureRecognizer *)tap {
    [self.avCaptureSession stopRunning];
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (self.avCaptureSession.shootingOrientation) {
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
    UIImage *image = [UIImage imageWithCGImage:self.captureView.image.CGImage scale:[UIScreen mainScreen].scale orientation:imageOrientation];
    self.captureView.image = image;
    
    NSLog(@"拍照结束");
    SLEditImageController * editViewController = [[SLEditImageController alloc] init];
    editViewController.image = image;
    editViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:editViewController animated:NO completion:nil];
    NSLog(@"拍照");
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
            NSString *outputVideoFielPath = [NSTemporaryDirectory() stringByAppendingString:@"myVideo.mp4"];
            //开始录制视频
            [self.avWriterInput startWritingToOutputFileAtPath:outputVideoFielPath fileType:SLAvWriterFileTypeVideo deviceOrientation:self.avCaptureSession.shootingOrientation];
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
            [self.avCaptureSession stopRunning];
            [self.avWriterInput finishWriting];
            self.isRecording = NO;
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
//实时输出视频样本
- (void)captureSession:(SLAvCaptureSession * _Nullable)captureSession didOutputVideoSampleBuffer:(CMSampleBufferRef _Nullable)sampleBuffer fromConnection:(AVCaptureConnection * _Nullable)connection {
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage* image = [CIImage imageWithCVImageBuffer:imageBuffer];
        //滤镜处理
        [self.filter setValue:image forKey:kCIInputImageKey];
        CIImage *filterImage = self.filter.outputImage;
        CGImageRef filterImageRef = [self.context createCGImage:filterImage fromRect:filterImage.extent];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.captureView.image = [UIImage imageWithCGImage:filterImageRef];
            CGImageRelease(filterImageRef);
        });
        if (self.isRecording) {
            [self.avWriterInput writingVideoSampleBuffer:sampleBuffer fromConnection:connection filterImage:filterImage];
        }
    }
}
//实时输出音频样本
- (void)captureSession:(SLAvCaptureSession * _Nullable)captureSession didOutputAudioSampleBuffer:(CMSampleBufferRef _Nullable)sampleBuffer fromConnection:(AVCaptureConnection * _Nullable)connection {
    if (self.isRecording) {
        [self.avWriterInput writingAudioSampleBuffer:sampleBuffer fromConnection:connection];
    }
}

#pragma mark - SLAvWriterInputDelegate 音视频写入完成
//音视频写入完成
- (void)writerInput:(SLAvWriterInput *)writerInput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    [self.avCaptureSession stopRunning];
    NSLog(@"结束录制");
    SLEditVideoController * editViewController = [[SLEditVideoController alloc] init];
    editViewController.videoPath = outputFileURL;
    editViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:editViewController animated:NO completion:^{
        NSString *result = error ? @"录制失败" : @"录制成功";
        NSLog(@"%@ %@", result , error.localizedDescription);
        [SLAlertView showAlertViewWithText:result delayHid:1];
    }];
}

@end
