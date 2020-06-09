//
//  SLColorPickerViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLColorPickerViewController.h"
#import "SLAvCaptureSession.h"
#import "UIImage+SLCommon.h"

@interface SLColorPickerViewController ()<SLAvCaptureSessionDelegate>
@property (nonatomic, strong) SLAvCaptureSession *avCaptureSession; //摄像头采集工具
@property (nonatomic, strong) UIView *preview; //摄像头采集内容视图
@property (nonatomic, strong) UIView *colorPreview; //识别的颜色预览视图
@end

@implementation SLColorPickerViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_avCaptureSession stopRunning];
    _avCaptureSession = nil;
}
- (void)dealloc {
    NSLog(@"%@释放了",NSStringFromClass(self.class));
}
#pragma mark - UI
- (void)setupUI {
    [self.view addSubview:self.preview];
    [self.view addSubview:self.colorPreview];
    self.avCaptureSession.preview = self.preview;
    [self.avCaptureSession startRunning];
}

#pragma mark - Getter
- (SLAvCaptureSession *)avCaptureSession {
    if (_avCaptureSession == nil) {
        _avCaptureSession = [[SLAvCaptureSession alloc] init];
        _avCaptureSession.delegate = self;
    }
    return _avCaptureSession;
}
- (UIView *)preview {
    if (!_preview) {
        _preview = [[UIView alloc] initWithFrame:self.view.bounds];
    }
    return _preview;
}
- (UIView *)colorPreview {
    if (!_colorPreview) {
        _colorPreview = [[UIView alloc] initWithFrame:CGRectMake(0, SL_TopNavigationBarHeight, 50, 50)];
        _colorPreview.backgroundColor = [UIColor blackColor];
    }
    return _colorPreview;
}

#pragma mark - HelpMethods

#pragma mark - EventsHandle

#pragma mark - SLAvCaptureSessionDelegate 音视频实时输出代理
//实时输出视频样本
- (void)captureSession:(SLAvCaptureSession * _Nullable)captureSession didOutputVideoSampleBuffer:(CMSampleBufferRef _Nullable)sampleBuffer fromConnection:(AVCaptureConnection * _Nullable)connection {
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage* image = [CIImage imageWithCVImageBuffer:imageBuffer];
        UIImage *img = [UIImage imageWithCIImage:image];
        SL_DISPATCH_ON_MAIN_THREAD(^{
            UIColor *color = [img sl_colorAtPixel:CGPointMake(self.view.sl_width/2.0, self.view.sl_height/2.0)];
//                self.colorPreview.backgroundColor = color;
        });
    }
}


@end
