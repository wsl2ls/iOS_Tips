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
#import "UIColor+SLCommon.h"
#import "SLBlurView.h"

@interface SLColorPickerViewController ()<SLAvCaptureSessionDelegate>
@property (nonatomic, strong) SLAvCaptureSession *avCaptureSession; //摄像头采集工具
@property (nonatomic, strong) UIView *preview; //摄像头采集内容视图
@property (nonatomic, strong) SLBlurView *colorPickerView; //识别的颜色中心
@property (nonatomic, strong) CIContext* context;
@property (nonatomic, assign) int hexColor; //识别的16进制的颜色值
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
    self.navigationController.navigationBar.translucent = NO;
    [self.view addSubview:self.preview];
    [self.view addSubview:self.colorPickerView];
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
- (SLBlurView *)colorPickerView {
    if (!_colorPickerView) {
        _colorPickerView = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _colorPickerView.blurView.alpha = 0.5;
        _colorPickerView.layer.cornerRadius = 20;
        _colorPickerView.layer.masksToBounds = YES;
        _colorPickerView.layer.borderWidth = 1;
        _colorPickerView.center = self.view.center;
    }
    return _colorPickerView;
}
-(CIContext *)context{
    // default creates a context based on GPU
    if (_context == nil) {
        _context = [CIContext contextWithOptions:nil];
    }
    return _context;
}

#pragma mark - SLAvCaptureSessionDelegate 音视频实时输出代理
//实时输出视频样本
- (void)captureSession:(SLAvCaptureSession * _Nullable)captureSession didOutputVideoSampleBuffer:(CMSampleBufferRef _Nullable)sampleBuffer fromConnection:(AVCaptureConnection * _Nullable)connection {
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage* ciimage = [CIImage imageWithCVImageBuffer:imageBuffer];
        CGImageRef imageRef = [self.context createCGImage:ciimage fromRect:ciimage.extent];
        UIImage *img = [UIImage imageWithCGImage:imageRef];
        SL_DISPATCH_ON_MAIN_THREAD((^{
            UIColor *color = [img sl_colorAtPixel:CGPointMake(img.size.width/2.0,img.size.height/2.0)];
            int hex = [UIColor sl_hexValueWithColor:color];
            //误差在0x080808之内，可看作颜色没变化
            if (abs(self.hexColor-hex) >= 0x080808) {
                //每次摄像头采集的图像帧都不是完全一样的，虽然人眼看着一样，但是像素在细微处会有差距，所以采集到的每一帧的颜色也会有误差
                self.hexColor = hex;
                //                 NSLog(@"%x %x",self.hexColor, hex);
            }
            self.navigationController.navigationBar.barTintColor = [UIColor sl_colorWithHex: self.hexColor alpha:1.0];
            self.navigationItem.title = [NSString stringWithFormat:@"识别的颜色：0x%x", self.hexColor];
            CGImageRelease(imageRef);
        }));
    }
}

@end
