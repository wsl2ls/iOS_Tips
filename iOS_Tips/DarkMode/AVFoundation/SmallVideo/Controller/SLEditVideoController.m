//
//  SLEditViewController.m
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditVideoController.h"
#import <Photos/Photos.h>
#import "UIView+SLImage.h"
#import "SLBlurView.h"
#import "SLEditMenuView.h"
#import "SLAvPlayer.h"
#import "SLAvCaptureTool.h"
#import "SLAvEditExport.h"
#import "SLEditSelectedBox.h"
#import "SLImage.h"
#import "SLImageView.h"
#import "SLDrawView.h"
#import "SLEditTextView.h"
#import "SLEditVideoClipping.h"
#import "UIImage+SLCommon.h"

@interface SLEditVideoController () <UIGestureRecognizerDelegate, SLAvPlayerDelegate>

@property (nonatomic, strong) UIImageView *preview; // 预览视图 展示编辑的图片或视频
@property (nonatomic, strong) SLAvPlayer *avPlayer;  //视频播放预览

@property (nonatomic, strong) SLBlurView *editBtn; //编辑
@property (nonatomic, strong) SLBlurView *againShotBtn;  // 再拍一次
@property (nonatomic, strong) UIButton *saveAlbumBtn;  //保存到相册

@property (nonatomic, strong) UIButton *cancleEditBtn; //取消编辑
@property (nonatomic, strong) UIButton *doneEditBtn; //完成编辑
@property (nonatomic, strong) SLEditMenuView *editMenuView; //编辑菜单栏
@property (nonatomic, strong) UIButton *trashTips; //垃圾桶提示 拖拽删除 贴图或文字

@property (nonatomic, strong) SLDrawView *drawView; // 涂鸦视图
@property (nonatomic, strong) NSMutableArray *watermarkArray; // 水印层 所有的贴图和文本
@property (nonatomic, strong) SLEditSelectedBox *selectedBox; //水印选中框
@property (nonatomic, strong) SLEditVideoClipping * videoClippingView; //视频裁剪 子菜单视图 选择裁剪范围
@property (nonatomic, assign) CMTime clippingBeginTime; //视频裁剪起始点
@property (nonatomic, assign) CMTime clippingEndTime; //视频裁剪结束点

@end

@implementation SLEditVideoController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _avPlayer.delegate = nil;
    [_avPlayer stop];
    _avPlayer = nil;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)dealloc {
    NSLog(@"视频编辑视图释放了");
}
#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.preview];
    
    self.avPlayer.url = self.videoPath;
    self.avPlayer.delegate = self;
    if (self.avPlayer.naturalSize.width != CGSizeZero.width) {
         self.preview.sl_height = self.preview.sl_width *  self.avPlayer.naturalSize.height/ self.avPlayer.naturalSize.width;
    }
    self.avPlayer.monitor = self.preview;
    self.preview.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height/2.0);
    [self.avPlayer play];
    
    [self.view addSubview:self.againShotBtn];
    [self.view addSubview:self.editBtn];
    [self.view addSubview:self.saveAlbumBtn];
    
    [self.view addSubview:self.cancleEditBtn];
    [self.view addSubview:self.doneEditBtn];
}

#pragma mark - HelpMethods
// 添加拖拽、缩放、旋转、单击、双击手势
- (void)addRotateAndPinchGestureRecognizer:(UIView *)view {
    //单击手势选中
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:singleTap];
    if ([view isKindOfClass:[UILabel class]]) {
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.numberOfTouchesRequired = 1;
        [singleTap requireGestureRecognizerToFail:doubleTap];
        [view addGestureRecognizer:doubleTap];
    }
    //拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragAction:)];
    pan.minimumNumberOfTouches = 1;
    [view addGestureRecognizer:pan];
    //缩放手势
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(pinchAction:)];
    pinchGestureRecognizer.delegate = self;
    [view addGestureRecognizer:pinchGestureRecognizer];
    //旋转手势
    UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(rotateAction:)];
    [view addGestureRecognizer:rotateRecognizer];
    rotateRecognizer.delegate = self;
}
//置顶视图
- (void)topSelectedView:(UIView *)topView {
    [self.preview bringSubviewToFront:topView];
    [self.watermarkArray removeObject:topView];
    [self.watermarkArray addObject:topView];
    [SLDelayPerform sl_cancelDelayPerform]; //取消延迟执行
    self.selectedBox.frame = topView.bounds;
    [topView addSubview:self.selectedBox];
}
// 隐藏预览按钮
- (void)hiddenPreviewButton:(BOOL)isHidden {
    self.againShotBtn.hidden = isHidden;
    self.editBtn.hidden = isHidden;
    self.saveAlbumBtn.hidden = isHidden;
}
// 隐藏编辑时菜单按钮
- (void)hiddenEditMenus:(BOOL)isHidden {
    self.cancleEditBtn.hidden = isHidden;
    self.doneEditBtn.hidden = isHidden;
    self.editMenuView.hidden = isHidden;
}
// 视频的涂鸦层
- (CALayer *)graffitiLayer {
    CALayer *graffitiLayer = [CALayer layer];
    graffitiLayer.frame = self.drawView.bounds;
    // 把水印在预览层上的坐标转换为视频资源文件上的坐标
    // 视频Layer上的坐标系原点在左下角，单位是px像素
    CGSize scaleSize = CGSizeMake(self.avPlayer.naturalSize.width/self.preview.sl_width, self.avPlayer.naturalSize.height/self.preview.sl_height);
    CGRect changeRect = CGRectMake(0, 0, CGRectGetWidth(graffitiLayer.frame)*scaleSize.width, CGRectGetHeight(graffitiLayer.frame)*scaleSize.height);
    graffitiLayer.frame = changeRect;
    UIImage *image = [self.drawView sl_imageByViewInRect:self.drawView.bounds];
    /** 缩放至视频大小 */
    UIGraphicsBeginImageContextWithOptions(self.avPlayer.naturalSize, NO, 1);
    [image drawInRect:CGRectMake(0, 0, self.avPlayer.naturalSize.width, self.avPlayer.naturalSize.height)];
    UIImage *graffitiImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    graffitiLayer.contentsScale = [UIScreen mainScreen].scale;
    graffitiLayer.contents = (__bridge id _Nullable)(graffitiImage.CGImage);
    return graffitiLayer;
}
// 视频的 贴画层 和 文本层
- (NSMutableArray *)watermarkLayers {
    NSMutableArray *stickerLayers = [NSMutableArray array];
    for (UIView *view in self.watermarkArray) {
        CALayer *animatedLayer = [CALayer layer];
        animatedLayer.frame = view.bounds;
        // 把水印在预览层上的坐标转换为视频资源文件上的坐标
        // 视频Layer上的坐标系原点在左下角，单位是px像素
        CGSize scaleSize = CGSizeMake(self.avPlayer.naturalSize.width/self.preview.sl_width, self.avPlayer.naturalSize.height/self.preview.sl_height);
        CGRect changeRect = CGRectMake(0, 0, CGRectGetWidth(animatedLayer.frame)*scaleSize.width, CGRectGetHeight(animatedLayer.frame)*scaleSize.height);
        animatedLayer.frame = changeRect;
        animatedLayer.position =  CGPointMake(view.center.x*scaleSize.width, (self.preview.sl_height - view.center.y)*scaleSize.height);
        
        //形变
        CGAffineTransform transform = view.transform;
        // 缩放系数
        CGFloat scale = sqrt(transform.a*transform.a + transform.c*transform.c);
        //反转 主要用来解决旋转反向的问题
        CGAffineTransform rotationTransform = CGAffineTransformInvert(transform);
        CGAffineTransform scaleTransform = CGAffineTransformScale(rotationTransform, scale, scale);
        animatedLayer.affineTransform = CGAffineTransformScale(scaleTransform, scale, scale);
        
        if ([view isKindOfClass:[SLImageView class]]) {
            SLImageView *imageView = (SLImageView *)view;
            if (imageView.imageType == SLImageTypeGIF) {
                CAKeyframeAnimation *gifLayerAnimation = [self animationForGifWithImage:imageView.animatedImage];
                gifLayerAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
                gifLayerAnimation.removedOnCompletion = NO;
                [animatedLayer addAnimation:gifLayerAnimation forKey:@"gif"];
            }else {
                animatedLayer.contentsScale = [UIScreen mainScreen].scale;
                animatedLayer.contents = (__bridge id _Nullable)(imageView.image.CGImage);
            }
        } else if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            SLImage *image = [SLImage imageWithData:UIImagePNGRepresentation([label sl_imageByViewInRect:label.bounds])];
            animatedLayer.contentsScale = [UIScreen mainScreen].scale;
            animatedLayer.contents = (__bridge id _Nullable)(image.CGImage);
        }
        [stickerLayers addObject:animatedLayer];
    }
    return stickerLayers;
}
// Gif CALayer关键帧动画
- (CAKeyframeAnimation *)animationForGifWithImage:(SLImage *)image {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    NSMutableArray * frames = [NSMutableArray new];
    NSMutableArray *times = [NSMutableArray arrayWithCapacity:3];
    CGFloat currentTime = 0;
    CGFloat totalTime = image.totalTime;
    NSInteger frameCount = image.frameCount;
    for (int i = 0; i < frameCount; ++i) {
        [times addObject:[NSNumber numberWithFloat:(currentTime / totalTime)]];
        currentTime += [image imageDurationAtIndex:i];
        [frames addObject:(__bridge id)[image imageAtIndex:i].CGImage];
    }
    animation.keyTimes = times;
    animation.values = frames;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = totalTime;
    animation.repeatCount = HUGE_VALF;
    return animation;
}

#pragma mark - Getter
- (UIImageView *)preview {
    if (_preview == nil) {
        _preview = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _preview.contentMode = UIViewContentModeScaleAspectFit;
        _preview.backgroundColor = [UIColor blackColor];
        _preview.userInteractionEnabled = YES;
        _preview.clipsToBounds = YES;
    }
    return _preview;
}
- (SLAvPlayer *)avPlayer {
    if (!_avPlayer) {
        _avPlayer = [[SLAvPlayer alloc] init];
    }
    return _avPlayer;
}
- (SLBlurView *)editBtn {
    if (_editBtn == nil) {
        _editBtn = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _editBtn.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height - 80);
        _editBtn.layer.cornerRadius = _editBtn.sl_width/2.0;
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
        _doneEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.sl_width - 50 - 15, 30, 40, 30)];
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
        _editMenuView = [[SLEditMenuView alloc] initWithFrame:CGRectMake(0, self.view.sl_height - 80 -  60, self.view.sl_width, 80 + 60)];
        _editMenuView.hidden = YES;
        _editMenuView.editObject = SLEditObjectVideo;
        __weak typeof(self) weakSelf = self;
        _editMenuView.selectEditMenu = ^(SLEditMenuType editMenuType, NSDictionary * _Nullable setting) {
            if (editMenuType == SLEditMenuTypeGraffiti) {
                weakSelf.drawView.userInteractionEnabled = ![setting[@"hidden"] boolValue];
                [weakSelf.preview insertSubview:weakSelf.drawView atIndex:1];
                if (setting[@"lineColor"]) {
                    weakSelf.drawView.lineColor = setting[@"lineColor"];
                }
                if (setting[@"goBack"]) {
                    [weakSelf.drawView goBack];
                }
            }else {
                weakSelf.drawView.userInteractionEnabled = NO;
            }
            if (editMenuType == SLEditMenuTypeSticking) {
                SLImage *image = setting[@"image"];
                if (image) {
                    SLImageView *imageView = [[SLImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width/[UIScreen mainScreen].scale, image.size.height/[UIScreen mainScreen].scale)];
                    imageView.autoPlayAnimatedImage = YES;
                    imageView.userInteractionEnabled = YES;
                    imageView.center = CGPointMake(weakSelf.preview.sl_width/2.0, weakSelf.preview.sl_height/2.0);
                    imageView.image = image;
                    [weakSelf.watermarkArray addObject:imageView];
                    [weakSelf.preview addSubview:imageView];
                    [weakSelf addRotateAndPinchGestureRecognizer:imageView];
                    [weakSelf topSelectedView:imageView];
                    [SLDelayPerform sl_startDelayPerform:^{
                        [weakSelf.selectedBox removeFromSuperview];
                    } afterDelay:1.0];
                }
            }
            if (editMenuType == SLEditMenuTypeText) {
                SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight)];
                [weakSelf.view addSubview:editTextView];
                editTextView.editTextCompleted = ^(UILabel * _Nullable label) {
                    if (label.text.length == 0 || label == nil) {
                        return;
                    }
                    label.center = CGPointMake(weakSelf.preview.sl_width/2.0, weakSelf.preview.sl_height/2.0);
                    [weakSelf.preview addSubview:label];
                    [weakSelf.watermarkArray addObject:label];
                    [weakSelf addRotateAndPinchGestureRecognizer:label];
                    [weakSelf topSelectedView:label];
                    [SLDelayPerform sl_startDelayPerform:^{
                        [weakSelf.selectedBox removeFromSuperview];
                    } afterDelay:1.0];
                };
            }
            if(editMenuType == SLEditMenuTypeVideoClipping) {
                weakSelf.videoClippingView.exitClipping = ^{
                    [weakSelf hiddenEditMenus:NO];
                    weakSelf.preview.transform = CGAffineTransformIdentity;
                    weakSelf.preview.center = CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight/2.0);
                };
                [weakSelf hiddenEditMenus:YES];
                weakSelf.preview.transform = CGAffineTransformMakeScale((SL_kScreenWidth - 30 * 2)/SL_kScreenWidth, (SL_kScreenWidth - 30 * 2)/SL_kScreenWidth);
                weakSelf.preview.center = CGPointMake(SL_kScreenWidth/2.0, (SL_kScreenHeight - weakSelf.videoClippingView.sl_height)/2.0);
                weakSelf.videoClippingView.asset = [AVAsset assetWithURL:weakSelf.videoPath];
                [weakSelf.view addSubview:weakSelf.videoClippingView];
            }
        };
        [self.view addSubview:_editMenuView];
    }
    return _editMenuView;
}
- (UIButton *)trashTips {
    if (!_trashTips) {
        _trashTips = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        _trashTips.center = CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight - 60);
        [_trashTips setTitle:@"拖动到此处删除" forState:UIControlStateNormal];
        [_trashTips setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _trashTips.titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _trashTips;
}
- (SLDrawView *)drawView {
    if (!_drawView) {
        _drawView = [[SLDrawView alloc] initWithFrame:self.preview.bounds];
        _drawView.backgroundColor = [UIColor clearColor];
        __weak typeof(self) weakSelf = self;
        _drawView.drawBegan = ^{
            [weakSelf hiddenEditMenus:YES];
        };
        _drawView.drawEnded = ^{
            [weakSelf hiddenEditMenus:NO];
        };
    }
    return _drawView;
}
- (NSMutableArray *)watermarkArray {
    if (!_watermarkArray) {
        _watermarkArray = [NSMutableArray array];
    }
    return _watermarkArray;
}
- (SLEditSelectedBox *)selectedBox {
    if (!_selectedBox) {
        _selectedBox = [[SLEditSelectedBox alloc] init];
    }
    return _selectedBox;
}
- (SLEditVideoClipping *)videoClippingView {
    if (!_videoClippingView) {
        _videoClippingView = [[SLEditVideoClipping alloc] initWithFrame:CGRectMake(0, SL_kScreenHeight - 110, SL_kScreenWidth, 110)];
        _videoClippingView.backgroundColor = [UIColor blackColor];
        __weak typeof(self) weakSelf = self;
        _videoClippingView.selectedClippingBegin = ^(CMTime beginTime, CMTime endTime, UIGestureRecognizerState state) {
            [weakSelf.avPlayer seekToTime:beginTime completionHandler:nil];
            if (state == UIGestureRecognizerStateEnded) {
                weakSelf.clippingBeginTime = beginTime;
                [weakSelf.avPlayer  play];
                NSLog(@"裁剪范围：%.2f %.2f",CMTimeGetSeconds(weakSelf.clippingBeginTime), CMTimeGetSeconds(weakSelf.clippingEndTime));
            }
        };
        _videoClippingView.selectedClippingEnd = ^(CMTime beginTime, CMTime endTime, UIGestureRecognizerState state) {
            [weakSelf.avPlayer seekToTime:endTime completionHandler:nil];
            if (state == UIGestureRecognizerStateEnded) {
                weakSelf.clippingEndTime = endTime;
                [weakSelf.avPlayer  seekToTime:beginTime completionHandler:nil];
                [weakSelf.avPlayer  play];
                NSLog(@"裁剪范围：%.2f %.2f",CMTimeGetSeconds(weakSelf.clippingBeginTime), CMTimeGetSeconds(weakSelf.clippingEndTime));
            }
        };
        
    }
    return _videoClippingView;
}
- (CMTime)clippingBeginTime {
    if (_clippingBeginTime.value == 0) {
        _clippingBeginTime = CMTimeMake(0, self.clippingEndTime.timescale);
    }
    return _clippingBeginTime;
}
- (CMTime)clippingEndTime {
    if (_clippingEndTime.value == 0) {
        _clippingEndTime = self.avPlayer.duration;
    }
    return _clippingEndTime;
}

#pragma mark - Events Handle
//编辑
- (void)editBtnClicked:(id)sender {
    [self hiddenEditMenus:NO];
    [self hiddenPreviewButton:YES];
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
            [self againShotBtnClicked:nil];
        });
        NSString *result = success ? @"视频保存至相册 成功" : @"保存视频到相册 失败 ";
        NSLog(@"%@", result);
        SL_DISPATCH_ON_MAIN_THREAD(^{
            [SLAlertView showAlertViewWithText:result delayHid:1];
        });
    }];
    
}
//保存图片完成后调用的方法
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    SL_DISPATCH_ON_MAIN_THREAD(^{
        [self dismissViewControllerAnimated:NO completion:^{
            NSString *result = error ? @"图片保存至相册 失败" : @"图片保存到相册 成功";
            NSLog(@"%@", result);
            [SLAlertView showAlertViewWithText:result delayHid:1];
        }];
    });
}
//取消编辑
- (void)cancleEditBtnClicked:(id)sender {
    [self hiddenPreviewButton:NO];
    [self hiddenEditMenus:YES];
    [self.selectedBox removeFromSuperview];
    [_editMenuView removeFromSuperview];
    _editMenuView = nil;
    [_drawView removeFromSuperview];
    _drawView = nil;
    for (UIView *view in self.watermarkArray) {
        [view removeFromSuperview];
    }
    [self.watermarkArray removeAllObjects];
    _videoClippingView = nil;
    self.clippingBeginTime = kCMTimeZero;
    self.clippingEndTime = kCMTimeZero;
}
//完成编辑 导出编辑后的对象
- (void)doneEditBtnClicked:(id)sender {
    [self.selectedBox removeFromSuperview];
    [self exportEditVideo];
}
//导出编辑后的视频
- (void)exportEditVideo {
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.frame = CGRectMake(0, 0, 50, 50);
    activityIndicatorView.color = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1];
    activityIndicatorView.center = CGPointMake(SL_kScreenWidth/2.0, SL_kScreenHeight/2.0);
    [activityIndicatorView startAnimating];
    [self.view addSubview:activityIndicatorView];
    //    NSString *myBundlePath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
    //    NSBundle *myBundle = [NSBundle bundleWithPath:myBundlePath];
    //    NSString *audioPath = [myBundle pathForResource:@"The love of one's life" ofType:@"mp3" inDirectory:@"Audio"];
    //    NSURL *bgsoundUrl = [NSURL fileURLWithPath:audioPath];
    SLAvEditExport *videoExportSession = [[SLAvEditExport alloc] initWithAsset:[AVAsset assetWithURL:self.videoPath]];
    NSString *outputVideoFielPath = [NSTemporaryDirectory() stringByAppendingString:@"EditMyVideo.mp4"];
    videoExportSession.outputURL = [NSURL fileURLWithPath:outputVideoFielPath];
    videoExportSession.timeRange = CMTimeRangeMake(self.clippingBeginTime,CMTimeSubtract(self.clippingEndTime, self.clippingBeginTime));
    videoExportSession.graffitiLayer = [self graffitiLayer];
    videoExportSession.stickerLayers = [self watermarkLayers];
    //    videoExportSession.audioUrls = @[bgsoundUrl];
    videoExportSession.isNativeAudio = YES;
    [videoExportSession exportAsynchronouslyWithCompletionHandler:^(NSError * _Nonnull error) {
        self.avPlayer .url = videoExportSession.outputURL;
        self.avPlayer .delegate = self;
        self.videoPath = videoExportSession.outputURL;
        [self cancleEditBtnClicked:nil];
        [activityIndicatorView stopAnimating];
        [activityIndicatorView removeFromSuperview];
        NSString *result = error ? @"导出失败" : @"导出成功";
        [SLAlertView showAlertViewWithText:result delayHid:1];
    } progress:^(float progress) {
        //        NSLog(@"视频导出进度 %f",progress);
    }];
}
// 点击水印视图
- (void)singleTapAction:(UITapGestureRecognizer *)singleTap {
    [self topSelectedView:singleTap.view];
    if (singleTap.state == UIGestureRecognizerStateFailed || singleTap.state == UIGestureRecognizerStateEnded) {
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
}
//双击 文本水印 开始编辑文本
- (void)doubleTapAction:(UITapGestureRecognizer *)doubleTap {
    [self topSelectedView:doubleTap.view];
    doubleTap.view.hidden = YES;
    UILabel *tapLabel = (UILabel *)doubleTap.view;
    SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight)];
    editTextView.configureEditParameters(@{@"textColor":tapLabel.textColor, @"backgroundColor":tapLabel.backgroundColor, @"text":tapLabel.text});
    editTextView.editTextCompleted = ^(UILabel * _Nullable label) {
        doubleTap.view.hidden = NO;
        if (label == nil) {
            return;
        }
        label.transform = tapLabel.transform;
        label.center = tapLabel.center;
        [tapLabel removeFromSuperview];
        [self.watermarkArray removeObject:tapLabel];
        [self.watermarkArray addObject:label];
        [self.preview addSubview:label];
        [self addRotateAndPinchGestureRecognizer:label];
        [self topSelectedView:label];
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    };
    [self.view addSubview:editTextView];
}
// 拖拽 水印视图
- (void)dragAction:(UIPanGestureRecognizer *)pan {
    // 返回的是相对于最原始的手指的偏移量
    CGPoint transP = [pan translationInView:self.preview];
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.preview.clipsToBounds = NO;
        [self hiddenEditMenus:YES];
        [self.view addSubview:self.trashTips];
        [self topSelectedView:pan.view];
    } else if (pan.state == UIGestureRecognizerStateChanged ) {
        pan.view.center = CGPointMake(pan.view.center.x + transP.x, pan.view.center.y + transP.y);
        [pan setTranslation:CGPointZero inView:self.preview];
        //获取拖拽的视图在屏幕上的位置
        CGRect rect = [pan.view convertRect: pan.view.bounds toView:self.view];
        //是否删除 删除视图Y < 视图中心点Y坐标
        if (self.trashTips.center.y < rect.origin.y+rect.size.height/2.0) {
            [self.trashTips setTitle:@"松手即可删除" forState:UIControlStateNormal];
            [self.trashTips setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        }else {
            [self.trashTips setTitle:@"拖动到此处删除" forState:UIControlStateNormal];
            [self.trashTips setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    } else if (pan.state == UIGestureRecognizerStateFailed || pan.state == UIGestureRecognizerStateEnded) {
        [self hiddenEditMenus:NO];
        self.preview.clipsToBounds = YES;
        //获取拖拽的视图在屏幕上的位置
        CGRect rect = [pan.view convertRect: pan.view.bounds toView:self.view];
        CGRect previewRect = [self.view convertRect:self.preview.frame toView:self.view];
        //删除拖拽的视图
        if (self.trashTips.center.y < rect.origin.y+rect.size.height/2.0) {
            [pan.view  removeFromSuperview];
            [self.watermarkArray removeObject:(SLImageView *)pan.view];
        }else if (!CGRectIntersectsRect(previewRect, rect)) {
            //如果出了父视图preview的范围，则置于父视图中心
            pan.view.center = CGPointMake(self.preview.sl_width/2.0, self.preview.sl_height/2.0);
        }
        [self.trashTips removeFromSuperview];
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
}
//缩放 水印视图
- (void)pinchAction:(UIPinchGestureRecognizer *)pinch {
    if (pinch.state == UIGestureRecognizerStateBegan) {
        [self topSelectedView:pinch.view];
    }else if (pinch.state == UIGestureRecognizerStateFailed || pinch.state == UIGestureRecognizerStateEnded){
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
    pinch.view.transform = CGAffineTransformScale(pinch.view.transform, pinch.scale, pinch.scale);
    pinch.scale = 1.0;
}
//旋转 水印视图 注意：旋转之后的frame会变！！！
- (void)rotateAction:(UIRotationGestureRecognizer *)rotation {
    if (rotation.state == UIGestureRecognizerStateBegan) {
        [self topSelectedView:rotation.view];
    }else if (rotation.state == UIGestureRecognizerStateFailed || rotation.state == UIGestureRecognizerStateEnded){
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
    rotation.view.transform = CGAffineTransformRotate(rotation.view.transform, rotation.rotation);
    // 将旋转的弧度清零(注意不是将图片旋转的弧度清零, 而是将当前手指旋转的弧度清零)
    rotation.rotation = 0;
}

#pragma mark - UIGestureRecognizerDelegate
// 该方法返回的BOOL值决定了view是否能够同时响应多个手势
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //     NSLog(@"%@ - %@", gestureRecognizer.class, otherGestureRecognizer.class);
    return YES;
}

#pragma mark - SLAvPlayerDelegate
- (void)avPlayer:(SLAvPlayer *)avPlayer playingToCurrentTime:(CMTime)currentTime totalTime:(CMTime)totalTime {
    if (CMTimeGetSeconds(currentTime) >= CMTimeGetSeconds(self.clippingEndTime)) {
        [avPlayer seekToTime:self.clippingBeginTime completionHandler:nil];
        [avPlayer play];
    }
}

@end
