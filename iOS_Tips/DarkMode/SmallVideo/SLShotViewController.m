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
#import "SLShotFocusView.h"
#import "SLEditMenuView.h"

#define KMaxDurationOfVideo  15.0 //录制最大时长 s

@interface SLShotViewController ()<SLAvCaptureToolDelegate>
{
    dispatch_source_t _gcdTimer; //计时器
    NSTimeInterval _durationOfVideo;  //录制视频的时长
}

@property (nonatomic, strong) SLAvCaptureTool *avCaptureTool; //摄像头采集工具
@property (nonatomic, strong) UIImageView *captureView; // 捕获预览视图

@property (nonatomic, strong) UIButton *switchCameraBtn; // 切换前后摄像头
@property (nonatomic, strong) UIButton *backBtn;

@property (nonatomic, strong) SLBlurView *shotBtn; //拍摄按钮
@property (nonatomic, strong) UIView *whiteView; //白色圆心
@property (nonatomic, strong) CAShapeLayer *progressLayer; //环形进度条
@property (nonatomic, strong)  UILabel *tipsLabel; //拍摄提示语  轻触拍照 长按拍摄

@property (nonatomic, strong) SLBlurView *editBtn; //编辑
@property (nonatomic, strong) SLBlurView *againShotBtn;  // 再拍一次
@property (nonatomic, strong) UIButton *saveAlbumBtn;  //保存到相册

@property (nonatomic, strong) UIImage *image; //当前拍摄的照片
@property (nonatomic, strong) NSURL *videoPath; //当前拍摄的视频路径

@property (nonatomic, assign) CGFloat currentZoomFactor; //当前焦距比例系数
@property (nonatomic, strong) SLShotFocusView *focusView;

@property (nonatomic, strong) UIButton *cancleEditBtn; //取消编辑
@property (nonatomic, strong) UIButton *doneEditBtn; //完成编辑
@property (nonatomic, strong) SLEditMenuView *editMenuView; //编辑菜单栏

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
    //    self.backBtn.frame = CGRectMake(50, self.view.frame.size.height - 50 - insets.bottom, 23, 12);
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)dealloc {
    [self.avCaptureTool removeObserver:self forKeyPath:@"shootingOrientation"];
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
    [self.view addSubview:self.switchCameraBtn];
    
    [self.view addSubview:self.cancleEditBtn];
    [self.view addSubview:self.doneEditBtn];
    
    [self.view addSubview:self.tipsLabel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tipsLabel removeFromSuperview];
    });
    //监听设备方向，旋转切换摄像头按钮
    [self.avCaptureTool addObserver:self forKeyPath:@"shootingOrientation" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - Getter
- (SLAvCaptureTool *)avCaptureTool {
    if (_avCaptureTool == nil) {
        _avCaptureTool = [[SLAvCaptureTool alloc] init];
        _avCaptureTool.preview = self.captureView;
        _avCaptureTool.delegate = self;
    }
    return _avCaptureTool;
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
        _focusView.backgroundColor = [UIColor clearColor];
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
        _againShotBtn.center = CGPointMake((self.view.sl_w/2 - 70/2.0)/2.0, self.view.sl_h - 80);
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
        _saveAlbumBtn.center = CGPointMake(self.view.sl_w/2.0 + 70/2.0+ (self.view.sl_w/2 - 70/2.0)/2.0, self.view.sl_h - 80);
        _saveAlbumBtn.hidden = YES;
        _saveAlbumBtn.layer.cornerRadius = _saveAlbumBtn.sl_w/2.0;
        _saveAlbumBtn.backgroundColor = [UIColor whiteColor];
        [_saveAlbumBtn setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
        [_saveAlbumBtn addTarget:self action:@selector(saveAlbumBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveAlbumBtn;
}
- (UIButton *)cancleEditBtn {
    if (_cancleEditBtn == nil) {
        _cancleEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 30, 40, 30)];
        _cancleEditBtn.hidden = YES;
        [_cancleEditBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancleEditBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancleEditBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cancleEditBtn addTarget:self action:@selector(cancleEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancleEditBtn;
}
- (UIButton *)doneEditBtn {
    if (_doneEditBtn == nil) {
        _doneEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.sl_w - 50 - 15, 30, 40, 30)];
        _doneEditBtn.hidden = YES;
        _doneEditBtn.backgroundColor = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1];
        [_doneEditBtn setTitle:@"完成" forState:UIControlStateNormal];
        [_doneEditBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _doneEditBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _doneEditBtn.layer.cornerRadius = 4;
        [_doneEditBtn addTarget:self action:@selector(doneEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneEditBtn;
}
- (SLEditMenuView *)editMenuView {
    if (!_editMenuView) {
        _editMenuView = [[SLEditMenuView alloc] initWithFrame:CGRectMake(0, self.view.sl_h - 80 -  60, self.view.sl_w, 80 + 60)];
        _editMenuView.hidden = YES;
        [self.view addSubview:_editMenuView];
    }
    return _editMenuView;
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
//返回
- (void)backBtn:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//聚焦手势
- (void)tapFocusing:(UITapGestureRecognizer *)tap {
    //如果没在运行，取消聚焦
    if(!self.avCaptureTool.isRunning) {
        return;
    }
    
    CGPoint point = [tap locationInView:self.captureView];
    if(point.y > self.shotBtn.sl_y || point.y < self.switchCameraBtn.sl_y + self.switchCameraBtn.sl_h) {
        return;
    }
    self.focusView.center = point;
    if (![self.view.subviews containsObject:self.focusView]) {
        [self.view addSubview:self.focusView];
    }
    [self.avCaptureTool focusAtPoint:point];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.focusView removeFromSuperview];
    });
}
//调节焦距 手势
- (void)pinchFocalLength:(UIPinchGestureRecognizer *)pinch {
    if(pinch.state == UIGestureRecognizerStateBegan) {
        self.currentZoomFactor = self.avCaptureTool.videoZoomFactor;
    }
    if (pinch.state == UIGestureRecognizerStateChanged) {
        self.avCaptureTool.videoZoomFactor = self.currentZoomFactor * pinch.scale;
    }
}
//编辑
- (void)editBtnClicked:(id)sender {
    self.cancleEditBtn.hidden = NO;
    self.doneEditBtn.hidden = NO;
    self.editMenuView.hidden = NO;
    
    self.againShotBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.saveAlbumBtn.hidden = YES;
}
//再试一次 继续拍摄
- (void)againShotBtnClicked:(id)sender {
    
    self.avCaptureTool.preview = self.captureView;
    [self.avCaptureTool startRunning];
    self.avCaptureTool.videoZoomFactor = 1.0;
    
    self.againShotBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.saveAlbumBtn.hidden = YES;
    
    self.backBtn.hidden = NO;
    self.shotBtn.hidden = NO;
    self.switchCameraBtn.hidden = NO;
    
    [SLAvPlayer sharedAVPlayer].monitor = nil;
    [[SLAvPlayer sharedAVPlayer] pause];
    self.videoPath = nil;
    self.image = nil;
}
//保存到相册
- (void)saveAlbumBtnClicked:(id)sender {
    if(self.image) {
        UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
    }else if (self.videoPath) {
        //视频录入完成之后在将视频保存到相簿  如果视频过大的话，建议创建一个后台任务去保存到相册
        PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
        [photoLibrary performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.videoPath];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            DISPATCH_ON_MAIN_THREAD(^{
                [self againShotBtnClicked:nil];
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
    });
    if (error) {
        NSLog(@"保存图片出错%@", error.localizedDescription);
    } else {
        NSLog(@"保存图片成功");
    }
}
//切换前/后摄像头
- (void)switchCameraClicked:(id)sender {
    if (self.avCaptureTool.devicePosition == AVCaptureDevicePositionFront) {
        [self.avCaptureTool switchsCamera:AVCaptureDevicePositionBack];
    } else if(self.avCaptureTool.devicePosition == AVCaptureDevicePositionBack) {
        [self.avCaptureTool switchsCamera:AVCaptureDevicePositionFront];
    }
}
//轻触拍照
- (void)takePicture:(UITapGestureRecognizer *)tap {
    [self.avCaptureTool outputPhoto];
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
            NSString *outputVideoFielPath = [NSTemporaryDirectory() stringByAppendingString:@"myVideo.mp4"];
            //开始录制视频
            [self.avCaptureTool startRecordVideoToOutputFileAtPath:outputVideoFielPath recordType:SLAvRecordTypeAv];
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
            [self.avCaptureTool stopRunning];
            
            self.againShotBtn.hidden = NO;
            self.editBtn.hidden = NO;
            self.saveAlbumBtn.hidden = NO;
            
            self.backBtn.hidden = YES;
            self.shotBtn.hidden = YES;
            self.switchCameraBtn.hidden = YES;
            
            [self.avCaptureTool stopRecordVideo];
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
- (void)cancleEditBtnClicked:(id)sender {
    self.cancleEditBtn.hidden = YES;
    self.doneEditBtn.hidden = YES;
    self.editMenuView.hidden = YES;
    self.againShotBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.saveAlbumBtn.hidden = NO;
}
- (void)doneEditBtnClicked:(id)sender {
    [self cancleEditBtnClicked:nil];
}

#pragma mark - SLAvCaptureToolDelegate  图片、音视频输出代理
//图片输出完成
- (void)captureTool:(SLAvCaptureTool *)captureTool didOutputPhoto:(UIImage *)image error:(NSError *)error {
    [self.avCaptureTool stopRunning];
    self.avCaptureTool.preview = nil;
    self.captureView.image = image;
    self.image = image;
    
    self.againShotBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.saveAlbumBtn.hidden = NO;
    
    self.backBtn.hidden = YES;
    self.shotBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
}
//音视频输出完成
- (void)captureTool:(SLAvCaptureTool *)captureTool didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    self.againShotBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.saveAlbumBtn.hidden = NO;
    
    self.backBtn.hidden = YES;
    self.shotBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    
    self.videoPath = outputFileURL;
    SLAvPlayer *avPlayer = [SLAvPlayer sharedAVPlayer];
    avPlayer.url = outputFileURL;
    avPlayer.monitor = self.captureView;
    [avPlayer play];
    [self.avCaptureTool stopRunning];
    
    NSLog(@"结束录制");
}

@end
