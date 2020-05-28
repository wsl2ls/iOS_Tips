//
//  SLWaterMarkController.m
//  DarkMode
//
//  Created by wsl on 2019/11/14.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWaterMarkController.h"
#import "GPUImage.h"
#import <Photos/Photos.h>
#import "SLImage.h"
#import "SLImageView.h"
#import "SLBlurView.h"
#import "SLAvPlayer.h"

//水印视频输出地址
#define KWatermarkVideoFilePath  [NSTemporaryDirectory() stringByAppendingString:@"WatermarkVideo.mp4"]

@interface SLWaterMarkController ()<GPUImageMovieWriterDelegate, SLAvPlayerDelegate>
@property (nonatomic, strong) GPUImageMovie *movieFile;  //读取视频文件
@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter; // 混合滤镜  混合视频帧和水印
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter; //写入导出视频

@property (nonatomic, strong) SLBlurView *addWatermark; //添加水印  文本和GIF
@property (nonatomic, strong) SLBlurView *againShotBtn;  // 再拍一次
@property (nonatomic, strong) UIButton *saveAlbumBtn;  //保存到相册

@property (nonatomic, strong) SLAvPlayer *avPlayer;  //视频播放预览
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView; //

@end

@implementation SLWaterMarkController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.blendFilter removeAllTargets];
    [self.movieFile removeAllTargets];
    [self.movieWriter finishRecording];
    [self.movieFile endProcessing];
    [self.avPlayer stop];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)dealloc {
    self.movieWriter.delegate = nil;
    self.movieWriter = nil;
    self.avPlayer.delegate = nil;
    self.avPlayer = nil;
    //如果有重复删除，否则报错
    if ([[NSFileManager defaultManager] fileExistsAtPath:KWatermarkVideoFilePath]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:KWatermarkVideoFilePath error:&error];
    }
    NSLog(@"%@ 释放了", NSStringFromClass(self.class));
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    self.avPlayer.url = self.videoPath;
    self.avPlayer.monitor = self.view;
    [self.avPlayer play];
    
    [self.view addSubview:self.againShotBtn];
    [self.view addSubview:self.addWatermark];
    [self.view addSubview:self.saveAlbumBtn];
    //如果有重复删除，否则报错
    if ([[NSFileManager defaultManager] fileExistsAtPath:KWatermarkVideoFilePath]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:KWatermarkVideoFilePath error:&error];
    }
}

#pragma mark - Getter
- (GPUImageMovie *)movieFile {
    if (!_movieFile) {
        AVAsset *asset = [AVAsset assetWithURL:self.videoPath];
        //读取视频文件
        _movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
        // 按视频真实帧率播放
        _movieFile.playAtActualSpeed = YES;
        // 重复播放
        _movieFile.shouldRepeat = YES;
        // 是否在控制台输出当前帧时间
        _movieFile.runBenchmark = NO;
    }
    return _movieFile;
}
- (GPUImageAlphaBlendFilter *)blendFilter {
    if (!_blendFilter) {
        // 混合滤镜，它会把水印层图像和视频帧图像混合：GPUImageNormalBlendFilter 就是把水印层图像添加到视频帧上，不做其他处理；GPUImageAlphaBlendFilter 水印层上的内容处于半透明的状态； GPUImageAddBlendFilter 水印层图像会受到视频帧本身滤镜的影响；GPUImageDissolveBlendFilter会造成视频帧变暗
        _blendFilter  = [[GPUImageAlphaBlendFilter alloc] init];
    }
    return _blendFilter;
}
- (GPUImageMovieWriter *)movieWriter {
    if (!_movieWriter) {
        //一般编/解码器都有16位对齐的处理（有未经证实的说法，也存在32位、64位对齐的），否则会产生绿边问题。
        //视频写入
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:KWatermarkVideoFilePath] size:CGSizeMake((SL_kScreenWidth - (int)SL_kScreenWidth%16)*[UIScreen mainScreen].scale, (SL_kScreenHeight - (int)SL_kScreenHeight%16)*[UIScreen mainScreen].scale)];
        _movieWriter.shouldPassthroughAudio = YES;//是否使用源音源
        _movieWriter.delegate = self;
    }
    return _movieWriter;
}
- (SLBlurView *)addWatermark {
    if (_addWatermark == nil) {
        _addWatermark = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _addWatermark.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height - 80);
        _addWatermark.layer.cornerRadius = _addWatermark.sl_width/2.0;
        UIButton * btn = [[UIButton alloc] initWithFrame:_addWatermark.bounds];
        [btn setTitle:@"add水印" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(addWatermarkClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_addWatermark addSubview:btn];
    }
    return _addWatermark;
}
- (SLBlurView *)againShotBtn {
    if (_againShotBtn == nil) {
        _againShotBtn = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _againShotBtn.center = CGPointMake((self.view.sl_width/2 - 70/2.0)/2.0, self.view.sl_height - 80);
        _againShotBtn.layer.cornerRadius = _againShotBtn.sl_width/2.0;
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
        _saveAlbumBtn.center = CGPointMake(self.view.sl_width/2.0 + 70/2.0+ (self.view.sl_width/2 - 70/2.0)/2.0, self.view.sl_height - 80);
        _saveAlbumBtn.layer.cornerRadius = _saveAlbumBtn.sl_width/2.0;
        _saveAlbumBtn.backgroundColor = [UIColor whiteColor];
        [_saveAlbumBtn setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
        [_saveAlbumBtn addTarget:self action:@selector(saveAlbumBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveAlbumBtn;
}
- (SLAvPlayer *)avPlayer {
    if (!_avPlayer) {
        _avPlayer = [[SLAvPlayer alloc] init];
        _avPlayer.delegate = self;
    }
    return _avPlayer;
}
- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicatorView.frame = CGRectMake(0, 0, 50, 50);
        _activityIndicatorView.color = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1];
        _activityIndicatorView.center = CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight/2.0);
    }
    return _activityIndicatorView;
}
#pragma mark - EventsHandle
//添加水印
- (void)addWatermarkClicked:(id)sender {
    self.addWatermark.hidden = YES;
    [self.activityIndicatorView startAnimating];
    [self.view addSubview:self.activityIndicatorView];
    // 水印层
    UIView *watermarkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight)];
    watermarkView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.sl_width, 80)];
    label.text = @"简书：且行且珍惜_iOS \n GitHub：wsl2ls";
    label.font = [UIFont systemFontOfSize:24];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor redColor];
    SLImageView *imageView = [[SLImageView alloc] initWithFrame:CGRectMake(0, 88, 100, 100)];
    imageView.sl_centerX = self.view.sl_width/2.0;
    NSString *myBundlePath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
    NSBundle *myBundle = [NSBundle bundleWithPath:myBundlePath];
    NSString *imagePath = [myBundle pathForResource:@"stickers_1" ofType:@"gif" inDirectory:@"StickingImages"];
    SLImage *image = [SLImage imageWithContentsOfFile:imagePath];
    imageView.image = image;
    [watermarkView addSubview:imageView];
    [watermarkView addSubview:label];
    //GPUImageUIElement继承GPUImageOutput类，作为响应链的源头。通过CoreGraphics把UIView渲染到图像，并通过glTexImage2D绑定到outputFramebuffer指定的纹理，最后通知targets纹理就绪。
    GPUImageUIElement *uielement = [[GPUImageUIElement alloc] initWithView:watermarkView];
    //目的是每帧回调
    GPUImageFilter* progressFilter = [[GPUImageFilter alloc] init];
    //每一帧渲染完毕后的回调
    static int index = 0;
    [progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        @autoreleasepool {
            if(index >= image.frameCount) index = 0;
            SL_DISPATCH_ON_MAIN_THREAD(^{
                //如果imageView加载在屏幕上并播放了，这里就不需要更新当前图像
                UIImage *currentImage = [image imageAtIndex:index++];
                imageView.image = currentImage;
            });
        }
        //需要调用update操作：因为update只会输出一次纹理信息，只适用于一帧，所以需要实时更新水印层图像
        [uielement updateWithTimestamp:time];
    }];
    //视频帧输出给progressFilter
    [self.movieFile addTarget:progressFilter];
    // 把原视频帧图像和水印层图像 输出给 混合滤镜进行渲染写入处理
    [progressFilter addTarget:self.blendFilter];
    [uielement addTarget:self.blendFilter];
    // 混合滤镜输出 给movieWriter写入
    [self.blendFilter addTarget:self.movieWriter];
    
    //把视频文件的音频交给self.movieWriter 写入
    self.movieFile.audioEncodingTarget = self.movieWriter;
    //使用MovieWriter同步编码写入
    [self.movieFile enableSynchronizedEncodingUsingMovieWriter:self.movieWriter];
    
    //调整方向
    CGAffineTransform transform;
    if (self.videoOrientation == UIDeviceOrientationLandscapeRight) {
        transform = CGAffineTransformMakeRotation(M_PI/2);
    } else if (self.videoOrientation == UIDeviceOrientationLandscapeLeft) {
        transform = CGAffineTransformMakeRotation(-M_PI/2);
    } else if (self.videoOrientation == UIDeviceOrientationPortraitUpsideDown) {
        transform = CGAffineTransformMakeRotation(M_PI);
    } else {
        transform = CGAffineTransformMakeRotation(0);
    }
    //开始写入
    [self.movieWriter startRecordingInOrientation:transform];
    //开始处理
    [self.movieFile startProcessing];
}
//再试一次 继续拍摄
- (void)againShotBtnClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}
//保存到相册
- (void)saveAlbumBtnClicked:(id)sender {
    //视频录入完成之后在将视频保存到相簿  如果视频过大的话，建议创建一个后台任务去保存到相册
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.videoPath];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        SL_DISPATCH_ON_MAIN_THREAD(^{
            [self dismissViewControllerAnimated:NO completion:^{
                NSString *result = success ? @"视频保存至相册 成功" : @"保存视频到相册 失败 ";
                [SLAlertView showAlertViewWithText:result delayHid:1];
            }];
        });
    }];
    
}
#pragma mark - GPUImageMovieWriterDelegate
//视频写入导出完成
- (void)movieRecordingCompleted {
    [self.movieWriter finishRecording];
    [self.movieFile endProcessing];
    [self.blendFilter removeAllTargets];
    [self.movieFile removeAllTargets];
    self.movieWriter = nil;
    NSLog(@"add水印成功");
    SL_DISPATCH_ON_MAIN_THREAD(^{
        [SLAlertView showAlertViewWithText:@"add水印成功" delayHid:1];
        self.videoPath = [NSURL fileURLWithPath:KWatermarkVideoFilePath];
        self.avPlayer.url = self.videoPath;
        [self.activityIndicatorView stopAnimating];
        [self.activityIndicatorView removeFromSuperview];
    });
}
//视频写入失败
- (void)movieRecordingFailedWithError:(NSError *)error {
    NSLog(@"add水印失败");
    SL_DISPATCH_ON_MAIN_THREAD(^{
        [SLAlertView showAlertViewWithText:@"add水印失败" delayHid:1];
        [self.activityIndicatorView stopAnimating];
        [self.activityIndicatorView removeFromSuperview];
    });
}
#pragma mark - SLAvPlayerDelegate
//播放完成
- (void)playDidEndOnAvplyer:(SLAvPlayer *)avPlayer {
    //    循环播放
    [avPlayer seekToTime:kCMTimeZero completionHandler:nil];
    [avPlayer play];
}

@end
