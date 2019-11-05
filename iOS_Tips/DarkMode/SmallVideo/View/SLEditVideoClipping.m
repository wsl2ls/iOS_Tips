//
//  SLEditVideoClipping.m
//  DarkMode
//
//  Created by wsl on 2019/10/21.
//  CopyrightTime © 2019 wsl. All rightTimes reserved.
//

#import "SLEditVideoClipping.h"

///  定义一个结构体 存储裁剪信息
struct SLVideoClippingState {
    /// 裁剪位置 开头NO  结尾YES
    BOOL position;
    ///时间比例 0 ——1
    CGFloat value;
    /// 裁剪状态  开始、正在、结束
    UIGestureRecognizerState state;
};
typedef struct SLVideoClippingState SLVideoClippingState;

CG_INLINE SLVideoClippingState
SLVideoClippingStateMake(BOOL position, CGFloat value, UIGestureRecognizerState state)
{
    SLVideoClippingState videoClippingState;
    videoClippingState.position = position;
    videoClippingState.value = value;
    videoClippingState.state = state;
    return videoClippingState;
};

/// 视频编辑裁剪选择框
@interface  SLVideoClippingBox : UIView
@property (nonatomic, assign) double totalDuration; //总时长
@property (nonatomic, strong) UIView *boxInside; //裁剪框内
@property (nonatomic, strong) UILabel *leftTime; //左边 起始时间点
@property (nonatomic, strong) UILabel *rightTime; // 右边 结束时间点
@property (nonatomic, copy) void(^changeClippingRange)(SLVideoClippingState clippingState);  //改变选择的裁剪区域
@end
@implementation SLVideoClippingBox
#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview == nil) {
        //        _boxInside = nil;
        //        _leftTime = nil;
        //        _rightTime = nil;
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }else {
        [self addSubview:self.boxInside];
        [self addSubview:self.leftTime];
        [self addSubview:self.rightTime];
    }
}
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] setFill];
    UIRectFill(rect);
    CGRect holeRectIntersection = CGRectIntersection(CGRectMake(self.leftTime.sl_x+10, 0, self.rightTime.sl_x - (self.leftTime.sl_x+10), rect.size.height), rect);
    [[UIColor clearColor] setFill];
    UIRectFill(holeRectIntersection);
}
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    CGRect bounds = self.bounds;
    //扩大响应区域宽至30
    CGFloat widthDelta = MAX(30, 0);
    CGFloat heightDelta = MAX(30, 0);
    bounds = CGRectInset(bounds, -0.5 * widthDelta, -0.5 * heightDelta);
    return CGRectContainsPoint(bounds, point);
}
- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    self.boxInside.frame = CGRectMake(0, 0, self.sl_w, self.sl_h);
    self.leftTime.frame = CGRectMake(-10, 0, 10, self.sl_h);
    self.rightTime.frame = CGRectMake(self.sl_w, 0, 10, self.sl_h);
}
#pragma mark - Getter
- (UIView *)boxInside {
    if (!_boxInside) {
        _boxInside = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.sl_w, self.sl_h)];
        _boxInside.backgroundColor = [UIColor clearColor];
        _boxInside.layer.borderColor = [UIColor whiteColor].CGColor;
        _boxInside.layer.borderWidth = 2;
    }
    return _boxInside;
}
- (UILabel *)leftTime {
    if (!_leftTime) {
        _leftTime = [[UILabel alloc] initWithFrame:CGRectMake(-10, 0, 10, self.sl_h)];
        _leftTime.text = @"||";
        _leftTime.textAlignment = NSTextAlignmentCenter;
        _leftTime.backgroundColor = [UIColor whiteColor];
        _leftTime.textColor = [UIColor grayColor];
        _leftTime.font = [UIFont systemFontOfSize:12];
        _leftTime.userInteractionEnabled = YES;
        _leftTime.tag = 0;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(changeClippingRange:)];
        [_leftTime addGestureRecognizer:pan];
    }
    return _leftTime;
}
- (UILabel *)rightTime {
    if (!_rightTime) {
        _rightTime = [[UILabel alloc] initWithFrame:CGRectMake(self.sl_w, 0, 10, self.sl_h)];
        _rightTime.text = @"||";
        _rightTime.tag = 1;
        _rightTime.textAlignment = NSTextAlignmentCenter;
        _rightTime.backgroundColor = [UIColor whiteColor];
        _rightTime.textColor = [UIColor grayColor];
        _rightTime.font = [UIFont systemFontOfSize:12];
        _rightTime.userInteractionEnabled = YES;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(changeClippingRange:)];
        [_rightTime addGestureRecognizer:pan];
    }
    return _rightTime;
}
#pragma mark - Events Handle
//选择裁剪范围
- (void)changeClippingRange:(UIPanGestureRecognizer *)pan {
    CGPoint transP = [pan translationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.changeClippingRange(SLVideoClippingStateMake(pan.view.tag, (pan.view.tag == 0 ? self.boxInside.sl_x/self.sl_w : self.rightTime.sl_x/self.sl_w), UIGestureRecognizerStateBegan));
    } else if (pan.state == UIGestureRecognizerStateChanged ) {
        if (pan.view == self.leftTime ) {
            //裁剪的视频时长必须>=1秒
            if (pan.view.sl_x + transP.x < -10 || (self.rightTime.sl_x - self.boxInside.sl_x -  transP.x)/self.sl_w*self.totalDuration < 1) {
                NSLog(@"视频超出了裁剪范围或裁剪后的时长小于1s");
            }else {
                self.boxInside.sl_x = self.boxInside.sl_x + transP.x;
                self.boxInside.sl_w = self.boxInside.sl_w - transP.x;
                pan.view.center = CGPointMake(pan.view.center.x + transP.x, pan.view.center.y);
            }
        }else if (pan.view == self.rightTime) {
            if (pan.view.sl_x + transP.x > self.sl_w || (self.rightTime.sl_x + transP.x - self.boxInside.sl_x)/self.sl_w*self.totalDuration < 1) {
                NSLog(@"视频超出了裁剪范围或裁剪后的时长小于1s");
            }else {
                self.boxInside.sl_w = self.boxInside.sl_w + transP.x;
                pan.view.center = CGPointMake(pan.view.center.x + transP.x, pan.view.center.y);
            }
        }
        self.changeClippingRange(SLVideoClippingStateMake(pan.view.tag, (pan.view.tag == 0 ? self.boxInside.sl_x/self.sl_w : self.rightTime.sl_x/self.sl_w), UIGestureRecognizerStateChanged));
        [self setNeedsDisplay];
        [pan setTranslation:CGPointZero inView:self];
    }else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateFailed || pan.state == UIGestureRecognizerStateCancelled) {
        if (pan.view == self.leftTime) {
            if (pan.view.sl_x  < -10) {
                pan.view.sl_x = -10;
            }
        }else if (pan.view == self.rightTime) {
            if (pan.view.sl_x  > self.sl_w) {
                pan.view.sl_x = self.sl_w;
            }
        }
        self.changeClippingRange(SLVideoClippingStateMake(pan.view.tag, (pan.view.tag == 0 ? self.boxInside.sl_x/self.sl_w : self.rightTime.sl_x/self.sl_w), UIGestureRecognizerStateEnded));
    }
}
@end

@interface SLEditVideoClipping ()
/// 视频帧图片解析器
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
/// 视频总时长
@property (nonatomic, assign) double totalDuration;
/// 图片帧 容器
@property (nonatomic, strong) UIView *contentView;
/// 视频裁剪框
@property (nonatomic, strong) SLVideoClippingBox *clippingBox; //剪辑选择框
@property (nonatomic, strong) UIButton *cancleBtn;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, assign) CMTime beginTime; //裁剪的开始
@property (nonatomic, assign) CMTime endTime; //裁剪的结束
@end
@implementation SLEditVideoClipping

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if(self.superview == nil) {
        //        _clippingBox = nil;
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }else {
        [self addSubview:self.contentView];
        [self addSubview:self.clippingBox];
        [self addSubview:self.cancleBtn];
        [self addSubview:self.doneBtn];
        [self generateImage];
    }
}

#pragma mark - Setter
- (void)setAsset:(AVAsset *)asset {
    _asset = asset;
    _imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_asset];
}

#pragma mark - Getter
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(40, 10, self.sl_w - 40 * 2, 50)];
        _contentView.backgroundColor = [UIColor blackColor];
        _contentView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _contentView.clipsToBounds = YES;
    }
    return _contentView;
}
- (UIView *)clippingBox {
    if (!_clippingBox) {
        _clippingBox = [[SLVideoClippingBox alloc] initWithFrame:self.contentView.frame];
        __weak typeof(self) weakSelf = self;
        _clippingBox.changeClippingRange = ^(SLVideoClippingState clippingState) {
            switch (clippingState.state) {
                case UIGestureRecognizerStateBegan:
                    weakSelf.contentView.layer.borderWidth = 2;
                    break;
                case UIGestureRecognizerStateChanged:{
                    CMTime duration = weakSelf.asset.duration;
                    if (clippingState.position) {
                        weakSelf.endTime= CMTimeMakeWithSeconds(floor(weakSelf.totalDuration*clippingState.value), duration.timescale);
                        weakSelf.selectedClippingEnd(weakSelf.beginTime, weakSelf.endTime, clippingState.state);
                    }else {
                        weakSelf.beginTime = CMTimeMakeWithSeconds(floor(weakSelf.totalDuration*clippingState.value), duration.timescale);
                        weakSelf.selectedClippingBegin(weakSelf.beginTime, weakSelf.endTime,clippingState.state);
                    }
                }
                    break;
                case UIGestureRecognizerStateEnded:
                    weakSelf.contentView.layer.borderWidth = 0;
                    if (clippingState.position) {
                        weakSelf.selectedClippingEnd(weakSelf.beginTime, weakSelf.endTime, clippingState.state);
                    }else {
                        weakSelf.selectedClippingBegin(weakSelf.beginTime, weakSelf.endTime,clippingState.state);
                    }
                    break;
                default:
                    break;
            }
        };
    }
    return _clippingBox;
}
- (UIButton *)cancleBtn {
    if (_cancleBtn == nil) {
        _cancleBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, self.sl_h - 10 - 30, 30, 30)];
        [_cancleBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancleBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cancleBtn addTarget:self action:@selector(cancleBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancleBtn;
}
- (UIButton *)doneBtn {
    if (_doneBtn == nil) {
        _doneBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.sl_w - 30 - 10, self.sl_h - 10 - 30, 30, 30)];
        [_doneBtn setTitle:@"完成" forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1] forState:UIControlStateNormal];
        _doneBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_doneBtn addTarget:self action:@selector(doneBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}

#pragma mark - Events Handle
- (void)cancleBtnClicked:(UIButton *)btn {
    [self removeFromSuperview];
    self.exitClipping();
}
- (void)doneBtnClicked:(UIButton *)btn {
    [self removeFromSuperview];
    self.exitClipping();
}
- (void)generateImage {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //最多10帧
    NSInteger maxImageCount = 10;
    NSArray *assetVideoTracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
    //导出的视频帧图片大小 单位是px像素
    CGSize maximumSize = CGSizeMake(self.contentView.frame.size.height* [UIScreen mainScreen].scale, self.contentView.frame.size.height* [UIScreen mainScreen].scale);
    //图片视图大小
    CGSize imageViewSize = CGSizeMake(self.contentView.frame.size.height, self.contentView.frame.size.height);
    if (assetVideoTracks.count > 0) {
        AVAssetTrack *track = [assetVideoTracks firstObject];
        //像素
        CGSize size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
        CGSize dimensions = CGSizeMake(fabs(size.width), fabs(size.height));
        CGFloat height = self.contentView.frame.size.height * [UIScreen mainScreen].scale;
        maximumSize = CGSizeMake(dimensions.width/dimensions.height*height, height);
    }
    if (maxImageCount * maximumSize.width/[UIScreen mainScreen].scale < self.contentView.frame.size.width) {
        maxImageCount = self.contentView.frame.size.width * [UIScreen mainScreen].scale / maximumSize.width;
        self.contentView.sl_w = maxImageCount * maximumSize.width/[UIScreen mainScreen].scale;
        self.contentView.sl_x = (self.sl_w - self.contentView.sl_w)/2.0;
        self.clippingBox.frame = self.contentView.frame;
        imageViewSize = CGSizeMake(self.contentView.sl_h*maximumSize.width/maximumSize.height, self.contentView.sl_h);
    }else {
        imageViewSize = CGSizeMake(self.contentView.sl_w/maxImageCount, self.contentView.sl_h);
    }
    
    //视频帧大小 像素
    _imageGenerator.maximumSize = maximumSize;
    _imageGenerator.appliesPreferredTrackTransform = YES;
    
    CMTime duration = _asset.duration;
    self.totalDuration = CMTimeGetSeconds(duration);
    self.clippingBox.totalDuration = self.totalDuration;
    self.beginTime= kCMTimeZero;
    self.endTime = duration;
    
    NSInteger index = maxImageCount;
    CMTimeValue intervalSeconds = duration.value/index;
    CMTime time = CMTimeMake(0, duration.timescale);
    NSMutableArray *times = [NSMutableArray array];
    for (NSUInteger i = 0; i < index; i++) {
        [times addObject:[NSValue valueWithCMTime:time]];
        time = CMTimeAdd(time, CMTimeMake(intervalSeconds, duration.timescale));
    }
    //生成视帧图片
    [_imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime,
                                                                                      CGImageRef cgImage,
                                                                                      CMTime actualTime,
                                                                                      AVAssetImageGeneratorResult result,
                                                                                      NSError *error) {
        UIImage *image = nil;
        if (cgImage) {
            image = [[UIImage alloc] initWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger imageIndex = [times indexOfObject:[NSValue valueWithCMTime:requestedTime]];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.layer.borderColor = [UIColor blackColor].CGColor;
            imageView.layer.borderWidth = .5f;
            imageView.frame = CGRectMake(imageIndex*imageViewSize.width, 0, imageViewSize.width, imageViewSize.height);
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            float proportion = imageViewSize.width/image.size.width/[UIScreen mainScreen].scale;
            imageView.layer.contentsRect = CGRectMake((1 - proportion)/2.0, 0, proportion, 1);
            [self.contentView addSubview:imageView];
        });
    }];
    
}
@end
