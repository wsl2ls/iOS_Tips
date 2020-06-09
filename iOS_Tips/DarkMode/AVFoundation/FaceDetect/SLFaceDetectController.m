//
//  SLFaceDetectController.m
//  DarkMode
//
//  Created by wsl on 2019/11/6.
//  Copyright © 2019 https://github.com/wsl2ls/iOS_Tips.git All rights reserved.
//

#import "SLFaceDetectController.h"
#import <AVFoundation/AVFoundation.h>
#import "SLBlurView.h"

@interface SLFaceDetectController () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureSession *session;  //采集会话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//摄像头采集内容展示区域
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput; // 视频输入流
@property(nonatomic,strong) AVCaptureMetadataOutput *metadataOutput; //输出元数据流   可以捕获输出二维码、条形码、人脸/猫/狗数据等

@property(nonatomic,strong)CALayer *overlayLayer;    //透明覆盖层 用来添加人脸层
@property(strong,nonatomic)NSMutableDictionary *faceLayers; //所有检测到的人脸对应层

@property (nonatomic, strong) UIButton *switchCameraBtn; // 切换前后摄像头
@property (nonatomic, strong) UIButton *backBtn;

@end

@implementation SLFaceDetectController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.faceLayers = [NSMutableDictionary dictionary];
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    //将子图层添加到预览图层来
    [self.previewLayer addSublayer:self.overlayLayer];
    [self.view addSubview:self.switchCameraBtn];
    [self.view addSubview:self.backBtn];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.session startRunning];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}
- (void)dealloc {
    NSLog(@"人脸检测控制器释放");
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
#pragma mark - UI

#pragma mark - HelpMethods
//获取指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)positon{
    if (@available(iOS 10.2, *)) {
        AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:positon];
        for (AVCaptureDevice *device in dissession.devices) {
            if ([device position] == positon) {
                return device;
            }
        }
    } else {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == positon) {
                return device;
            }
        }
    }
    return nil;
}

static CATransform3D CATransform3DMakePerspective(CGFloat eyePosition) {
    //CATransform3D 图层的旋转，缩放，偏移，歪斜和应用的透
    //CATransform3DIdentity是单位矩阵，该矩阵没有缩放，旋转，歪斜，透视。该矩阵应用到图层上，就是设置默认值。
    CATransform3D  transform = CATransform3DIdentity;
    //透视效果（就是近大远小），是通过设置m34 m34 = -1.0/D 默认是0.D越小透视效果越明显
    //D:eyePosition 观察者到投射面的距离
    transform.m34 = -1.0/eyePosition;
    return transform;
}
static CGFloat THDegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

//将检测到的人脸进行可视化
- (void)didDetectFaces:(NSArray *)faces {
    //创建一个本地数组 保存转换后的人脸数据
    NSArray *transformedFaces = [self transformedFacesFromFaces:faces];
    
    //获取faceLayers的key，用于确定哪些人移除了视图并将对应的图层移出界面。
    /*
     支持同时识别10个人脸
     */
    NSMutableArray *lostFaces = [self.faceLayers.allKeys mutableCopy];
    
    //遍历每个转换的人脸对象
    for (AVMetadataFaceObject *face in transformedFaces) {
        //获取关联的faceID。这个属性唯一标识一个检测到的人脸
        NSNumber *faceID = @(face.faceID);
        //将对象从lostFaces 移除
        [lostFaces removeObject:faceID];
        //拿到当前faceID对应的layer
        CALayer *layer = self.faceLayers[faceID];
        
        //如果给定的faceID 没有找到对应的图层
        if (!layer) {
            //调用makeFaceLayer 创建一个新的人脸图层
            layer = [self makeFaceLayer];
            //将新的人脸图层添加到 overlayLayer上
            [self.overlayLayer addSublayer:layer];
            //将layer加入到字典中
            self.faceLayers[faceID] = layer;
        }
        //设置图层的transform属性 CATransform3DIdentity 图层默认变化 这样可以重新设置之前应用的变化
        layer.transform = CATransform3DIdentity;
        //图层的大小 = 人脸的大小
        layer.frame = face.bounds;
        
        //判断人脸对象是否具有有效的斜倾交。
        if (face.hasRollAngle) {
            //如果为YES,则获取相应的CATransform3D 值
            CATransform3D t = [self transformForRollAngle:face.rollAngle];
            //将它与标识变化关联在一起，并设置transform属性
            layer.transform = CATransform3DConcat(layer.transform, t);
        }
        //判断人脸对象是否具有有效的偏转角
        if (face.hasYawAngle) {
            //如果为YES,则获取相应的CATransform3D 值
            CATransform3D  t = [self transformForYawAngle:face.yawAngle];
            layer.transform = CATransform3DConcat(layer.transform, t);
        }
    }
    //遍历数组将剩下的人脸ID集合从上一个图层和faceLayers字典中移除
    for (NSNumber *faceID in lostFaces) {
        CALayer *layer = self.faceLayers[faceID];
        [layer removeFromSuperlayer];
        [self.faceLayers  removeObjectForKey:faceID];
    }
}

//将设备的坐标空间的人脸转换为视图空间的对象集合
- (NSArray *)transformedFacesFromFaces:(NSArray *)faces {
    NSMutableArray *transformeFaces = [NSMutableArray array];
    for (AVMetadataObject *face in faces) {
        //将摄像头的人脸数据 转换为 视图上的可展示的数据
        //简单说：UIKit的坐标 与 摄像头坐标系统（0，0）-（1，1）不一样。所以需要转换
        //转换需要考虑图层、镜像、视频重力、方向等因素 在iOS6.0之前需要开发者自己计算，但iOS6.0后提供方法
        AVMetadataObject *transformedFace = [self.previewLayer transformedMetadataObjectForMetadataObject:face];
        //转换成功后，加入到数组中
        [transformeFaces addObject:transformedFace];
    }
    return transformeFaces;
}
//人脸标记层
- (CALayer *)makeFaceLayer {
    //创建一个layer
    CALayer *layer = [CALayer layer];
    //边框宽度为5.0f
    //    layer.borderWidth = 5.0f;
    //边框颜色为红色
    //    layer.borderColor = [UIColor whiteColor].CGColor;
    layer.contents = (id)[UIImage imageNamed:@"face"].CGImage;
    //返回layer
    return layer;
}
//将 RollAngle 的 rollAngleInDegrees 值转换为 CATransform3D
- (CATransform3D)transformForRollAngle:(CGFloat)rollAngleInDegrees {
    //将人脸对象得到的RollAngle 单位“度” 转为Core Animation需要的弧度值
    CGFloat rollAngleInRadians = THDegreesToRadians(rollAngleInDegrees);
    //将结果赋给CATransform3DMakeRotation x,y,z轴为0，0，1 得到绕Z轴倾斜角旋转转换
    return CATransform3DMakeRotation(rollAngleInRadians, 0.0f, 0.0f, 1.0f);
}
//将 YawAngle 的 yawAngleInDegrees 值转换为 CATransform3D
- (CATransform3D)transformForYawAngle:(CGFloat)yawAngleInDegrees {
    //将角度转换为弧度值
    CGFloat yawAngleInRaians = THDegreesToRadians(yawAngleInDegrees);
    //将结果CATransform3DMakeRotation x,y,z轴为0，-1，0 得到绕Y轴选择。
    //由于overlayer 需要应用sublayerTransform，所以图层会投射到z轴上，人脸从一侧转向另一侧会有3D 效果
    CATransform3D yawTransform = CATransform3DMakeRotation(yawAngleInRaians, 0.0f, -1.0f, 0.0f);
    
    //因为应用程序的界面固定为垂直方向，但需要为设备方向计算一个相应的旋转变换
    //如果不这样，会造成人脸图层的偏转效果不正确
    return CATransform3DConcat(yawTransform, [self orientationTransform]);
}
- (CATransform3D)orientationTransform {
    CGFloat angle = 0.0;
    //拿到设备方向
    switch ([UIDevice currentDevice].orientation) {
            //方向：下
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
            //方向：右
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI / 2.0f;
            break;
            //方向：左
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI /2.0f;
            break;
            //其他
        default:
            angle = 0.0f;
            break;
    }
    return CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
}

#pragma mark - Getter
- (AVCaptureSession *)session{
    if (_session == nil){
        _session = [[AVCaptureSession alloc] init];
        //高质量采集率
        [_session setSessionPreset:AVCaptureSessionPreset1280x720];
        if([_session canAddInput:self.videoInput]) [_session addInput:self.videoInput]; //添加视频输入流
        //创建主队列： 因为人脸检测用到了硬件加速，而且许多重要的任务都在主线程中执行，所以需要为这次参数指定主队列。
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        //通过设置AVCaptureVideoDataOutput的代理，就能获取捕获到一帧一帧数据
        [self.metadataOutput setMetadataObjectsDelegate:self queue:mainQueue];
    }
    return _session;
}
- (AVCaptureDeviceInput *)videoInput {
    if (_videoInput == nil) {
        //添加一个视频输入设备  默认是后置摄像头
        AVCaptureDevice *videoCaptureDevice =  [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
        //创建视频输入流
        _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:nil];
        if (!_videoInput){
            NSLog(@"获得摄像头失败");
            return nil;
        }
    }
    return _videoInput;
}
- (AVCaptureMetadataOutput *)metadataOutput {
    if (!_metadataOutput) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        // 添加元数据输出流
        if([self.session canAddOutput:self.metadataOutput]) [self.session addOutput:self.metadataOutput];
        //获得人脸属性
        NSArray *metadatObjectTypes = @[AVMetadataObjectTypeFace];
        //设置metadataObjectTypes 指定对象输出的元数据类型。
        /*
         限制检查到元数据类型集合的做法是一种优化处理方法。可以减少我们实际感兴趣的对象数量
         支持多种元数据。这里只保留对人脸元数据感兴趣
         */
        _metadataOutput.metadataObjectTypes = metadatObjectTypes;
    }
    return _metadataOutput;
}
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.frame = self.view.bounds;
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return _previewLayer;
}
- (CALayer *)overlayLayer {
    if (!_overlayLayer) {
        //初始化overlayLayer
        _overlayLayer = [CALayer layer];
        //设置它的frame
        _overlayLayer.frame = self.view.bounds;
        //子图层形变 sublayerTransform属性
        _overlayLayer.sublayerTransform = CATransform3DMakePerspective(1000);
    }
    return _overlayLayer;
}
- (UIButton *)switchCameraBtn {
    if (_switchCameraBtn == nil) {
        _switchCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.sl_width - 30 - 30, 44 , 30, 30)];
        [_switchCameraBtn setImage:[UIImage imageNamed:@"cameraAround"] forState:UIControlStateNormal];
        [_switchCameraBtn addTarget:self action:@selector(switchCameraClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraBtn;
}
- (UIButton *)backBtn {
    if (_backBtn == nil) {
        _backBtn = [[UIButton alloc] init];
        _backBtn.frame = CGRectMake( 30, 44 , 30, 30);
        [_backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

#pragma mark - EventsHandle
//返回
- (void)backBtn:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//切换前/后置摄像头
- (void)switchCameraClicked:(id)sender {
    AVCaptureDevicePosition devicePosition;
    if ([self.videoInput device].position == AVCaptureDevicePositionBack) {
        devicePosition = AVCaptureDevicePositionFront;
    }else {
        devicePosition = AVCaptureDevicePositionBack;
    }
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self getCameraDeviceWithPosition:devicePosition] error:nil];
    //先开启配置，配置完成后提交配置改变
    [self.session beginConfiguration];
    //移除原有输入对象
    [self.session removeInput:self.videoInput];
    //添加新的输入对象
    if ([self.session canAddInput:videoInput]) {
        [self.session addInput:videoInput];
        self.videoInput = videoInput;
    }
    //提交新的输入对象
    [self.session commitConfiguration];
    for (CALayer *faceLayer in self.faceLayers.allValues) {
        [faceLayer removeFromSuperlayer];
    }
}
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
//捕捉到数据
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        //使用循环，打印人脸数据
        for (AVMetadataFaceObject *face in metadataObjects) {
            //        NSLog(@"Face detected with ID:%li",(long)face.faceID);
            //        NSLog(@"Face bounds:%@",NSStringFromCGRect(face.bounds));
        }
        //将检测到的人脸标记出来
        [self didDetectFaces:metadataObjects];
    }
}

@end
