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
#import "SLAvPlayer.h"
#import "SLAvCaptureTool.h"

#define KMaxDurationOfVideo  15.0 //录制最大时长 s

#define DISPATCH_ON_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(),mainQueueBlock);  //主线程操作

@interface SLShotViewController ()<AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate>
{
    dispatch_source_t _gcdTimer; //计时器
    NSTimeInterval _durationOfVideo;  //录制视频的时长
}

//摄像头采集工具
@property (nonatomic, strong) SLAvCaptureTool *avCaptureTool;
@property (nonatomic, strong) UIView *captureView; // 捕获视图

@property (nonatomic, strong) UIButton *backBtn;
//拍摄按钮
@property (nonatomic, strong) SLBlurView *shotBtn;
@property (nonatomic, strong) UIView *whiteView;
//环形进度条
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@property (nonatomic, strong) SLBlurView *editBtn;
@property (nonatomic, strong) SLBlurView *againShotBtn;
@property (nonatomic, strong) UIButton *saveAlbumBtn;

@property (nonatomic, strong) UIImage *image; //当前拍摄的照片
@property (nonatomic, strong) NSURL *videoPath; //当前拍摄的视频路径

@end

@implementation SLShotViewController

#pragma mark - OverWrite
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.avCaptureTool startRunning];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.avCaptureTool stopRunning];
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
    [self.view addSubview:self.captureView];
    
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.shotBtn];
    [self.view addSubview:self.againShotBtn];
    [self.view addSubview:self.editBtn];
    [self.view addSubview:self.saveAlbumBtn];
}

#pragma mark - Getter
- (SLAvCaptureTool *)avCaptureTool {
    if (_avCaptureTool == nil) {
        _avCaptureTool = [[SLAvCaptureTool alloc] init];
        _avCaptureTool.preview = self.captureView;
        _avCaptureTool.photoCaptureDelegate = self;
        _avCaptureTool.fileOutputRecordingDelegate = self;
    }
    return _avCaptureTool;
}
- (UIView *)captureView {
    if (_captureView == nil) {
        _captureView = [[UIView alloc] initWithFrame:self.view.bounds];
        _captureView.backgroundColor = [UIColor whiteColor];
    }
    return _captureView;
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
        _editBtn.layer.cornerRadius = _editBtn.sl_w/2.0;
        UIButton * btn = [[UIButton alloc] initWithFrame:_editBtn.bounds];
        [btn setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(editBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_editBtn addSubview:btn];
    }
    return _editBtn;
}
- (SLBlurView *)againShotBtn {
    if (_againShotBtn == nil) {
        _againShotBtn = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _againShotBtn.center = CGPointMake(self.view.sl_w/2/2.0, self.view.sl_h - 80);
        _againShotBtn.hidden = YES;
        _againShotBtn.layer.cornerRadius = _againShotBtn.sl_w/2.0;
        UIButton * btn = [[UIButton alloc] initWithFrame:_againShotBtn.bounds];
        [btn setImage:[UIImage imageNamed:@"cancle"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(againShotBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_againShotBtn addSubview:btn];
    }
    return _againShotBtn;
}
- (UIButton *)saveAlbumBtn {
    if (_saveAlbumBtn == nil) {
        _saveAlbumBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _saveAlbumBtn.center = CGPointMake(self.view.sl_w/2.0 + self.view.sl_w/2/2.0, self.view.sl_h - 80);
        _saveAlbumBtn.hidden = YES;
        _saveAlbumBtn.layer.cornerRadius = _saveAlbumBtn.sl_w/2.0;
        _saveAlbumBtn.backgroundColor = [UIColor whiteColor];
        [_saveAlbumBtn setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
        [_saveAlbumBtn addTarget:self action:@selector(saveAlbumBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveAlbumBtn;
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
        DISPATCH_ON_MAIN_THREAD(^{
            //主线程更新UI
            self.progressLayer.strokeEnd = self->_durationOfVideo/KMaxDurationOfVideo;
        });
        
        if(self->_durationOfVideo > KMaxDurationOfVideo) {
            NSLog(@"时长 %f", self->_durationOfVideo);
            DISPATCH_ON_MAIN_THREAD(^{
                self.progressLayer.strokeEnd = 1;
            });
            
            //暂停定时器
            // dispatch_suspend(_gcdTimer);
            //取消计时器
            dispatch_source_cancel(self->_gcdTimer);
            self->_durationOfVideo = 0;
            [self.progressLayer removeFromSuperlayer];
            //停止录制
            [self.avCaptureTool stopRecordVideo];
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
//再试一次
- (void)againShotBtnClicked:(id)sender {
    [self.avCaptureTool startRunning];
    
    self.againShotBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.saveAlbumBtn.hidden = YES;
    self.backBtn.hidden = NO;
    self.shotBtn.hidden = NO;
    
    [SLAvPlayer sharedAVPlayer].monitor = nil ;
}
//保存到相册
- (void)saveAlbumBtnClicked:(id)sender {
    if(self.image) {
        UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
    }
    if (self.videoPath) {
        //视频录入完成之后在将视频保存到相簿  如果视频过大的话，建议创建一个后台任务去保存到相册
        PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
        [photoLibrary performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.videoPath];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            DISPATCH_ON_MAIN_THREAD(^{
                [self againShotBtnClicked:nil];
                self.videoPath = nil;
            });
            if (success) {
                NSLog(@"视频保存至相册 成功");
            } else {
                NSLog(@"保存视频到相册 失败 ");
            }
        }];
    }
}
//保存图片完成后调用的方法
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    DISPATCH_ON_MAIN_THREAD(^{
        [self againShotBtnClicked:nil];
        self.videoPath = nil;
    });
    if (error) {
        NSLog(@"保存图片出错%@", error.localizedDescription);
    } else {
        NSLog(@"保存图片成功");
    }
}
//轻触拍照
- (void)takePicture:(UITapGestureRecognizer *)tap {
    [self.avCaptureTool outputPhoto];
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
            //开始录制视频
            [self.avCaptureTool startRecordVideo];
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
            
            //            停止录制视频
            [self.avCaptureTool stopRecordVideo];
        }
            //            NSLog(@"结束摄像");
            break;
        default:
            break;
    }
}

#pragma mark - AVCapturePhotoCaptureDelegate 图片输出代理
//捕获拍摄图片的回调
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0)) {
    NSData *data = [photo fileDataRepresentation];
    self.image = [UIImage imageWithData:data];
    [self.avCaptureTool stopRunning];
    
    self.againShotBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.saveAlbumBtn.hidden = NO;
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
    
    self.againShotBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.saveAlbumBtn.hidden = NO;
    self.backBtn.hidden = YES;
    self.shotBtn.hidden = YES;
    
    self.videoPath = outputFileURL;
    SLAvPlayer *avPlayer = [SLAvPlayer sharedAVPlayer];
    avPlayer.url = outputFileURL;
    avPlayer.monitor = self.captureView;
    [avPlayer play];
    [self.avCaptureTool stopRunning];
    
}

@end
