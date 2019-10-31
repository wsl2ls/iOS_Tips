//
//  SLEditImageController.m
//  DarkMode
//
//  Created by wsl on 2019/10/31.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditImageController.h"
#import <Photos/Photos.h>
#import "SLAvCaptureTool.h"
#import "UIView+SLFrame.h"
#import "UIView+SLImage.h"
#import "SLBlurView.h"
#import "SLEditMenuView.h"
#import "SLEditSelectedBox.h"
#import "NSObject+SLDelayPerform.h"
#import "SLImage.h"
#import "SLImageView.h"
#import "SLDrawView.h"
#import "SLEditTextView.h"
#import "SLMosaicView.h"
#import "UIImage+SLCommon.h"

@interface SLEditImageController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *preview; // 预览视图 展示编辑的图片

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
@property (nonatomic, strong) SLMosaicView *mosaicView; //马赛克画板


@end

@implementation SLEditImageController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)dealloc {
    NSLog(@"编辑视图释放了");
}
#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.preview];
    
    self.preview.image = self.image;
    self.preview.sl_h = self.preview.sl_w * self.image.size.height/self.image.size.width;
    self.preview.center = CGPointMake(self.view.sl_w/2.0, self.view.sl_h/2.0);
    
    [self.view addSubview:self.againShotBtn];
    [self.view addSubview:self.editBtn];
    [self.view addSubview:self.saveAlbumBtn];
    
    [self.view addSubview:self.cancleEditBtn];
    [self.view addSubview:self.doneEditBtn];
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
- (SLBlurView *)editBtn {
    if (_editBtn == nil) {
        _editBtn = [[SLBlurView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _editBtn.center = CGPointMake(self.view.sl_w/2.0, self.view.sl_h - 80);
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
        __weak typeof(self) weakSelf = self;
        _editMenuView.editObject = SLEditObjectPicture;
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
                    imageView.autoPlayAnimatedImage = NO;
                    imageView.userInteractionEnabled = YES;
                    imageView.center = CGPointMake(weakSelf.preview.sl_w/2.0, weakSelf.preview.sl_h/2.0);
                    imageView.image = image;
                    [weakSelf.watermarkArray addObject:imageView];
                    [weakSelf.preview addSubview:imageView];
                    [weakSelf addRotateAndPinchGestureRecognizer:imageView];
                    [weakSelf topSelectedView:imageView];
                    [weakSelf startDelayPerform:^{
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
                    label.center = CGPointMake(weakSelf.preview.sl_w/2.0, weakSelf.preview.sl_h/2.0);
                    [weakSelf.preview addSubview:label];
                    [weakSelf.watermarkArray addObject:label];
                    [weakSelf addRotateAndPinchGestureRecognizer:label];
                    [weakSelf topSelectedView:label];
                    [weakSelf startDelayPerform:^{
                        [weakSelf.selectedBox removeFromSuperview];
                    } afterDelay:1.0];
                };
            }
            if(editMenuType == SLEditMenuTypePictureMosaic) {
                if (setting[@"mosaicType"]) {
                    weakSelf.mosaicView.userInteractionEnabled = ![setting[@"hidden"] boolValue];
                    weakSelf.mosaicView.mosaicType = [setting[@"mosaicType"] integerValue];
                    [weakSelf.preview insertSubview:weakSelf.mosaicView atIndex:0];
                }
                if (setting[@"goBack"]) {
                    [weakSelf.mosaicView goBack];
                }
            }else {
                weakSelf.mosaicView.userInteractionEnabled = NO;
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
- (SLMosaicView *)mosaicView {
    if (!_mosaicView) {
        _mosaicView = [[SLMosaicView alloc] initWithFrame:self.preview.bounds];
        __weak typeof(self) weakSelf = self;
        _mosaicView.brushColor = ^UIColor *(CGPoint point) {
            point.x = point.x/weakSelf.view.frame.size.width*weakSelf.preview.image.size.width;
            point.y = point.y/weakSelf.view.frame.size.height*weakSelf.preview.image.size.height;
            return [weakSelf.preview.image colorAtPixel:point];
        };
        _mosaicView.brushBegan = ^{
            [weakSelf hiddenEditMenus:YES];
        };
        _mosaicView.brushEnded = ^{
            [weakSelf hiddenEditMenus:NO];
        };
        _mosaicView.userInteractionEnabled = YES;
    }
    return _mosaicView;
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
    if(self.image) {
        UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
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
//取消编辑
- (void)cancleEditBtnClicked:(id)sender {
    [self hiddenPreviewButton:NO];
    [self hiddenEditMenus:YES];
    _editMenuView = nil;
    [self.selectedBox removeFromSuperview];
    [self.drawView removeFromSuperview];
    [self.mosaicView removeFromSuperview];
    for (UIView *view in self.watermarkArray) {
        [view removeFromSuperview];
    }
    [self.watermarkArray removeAllObjects];
}
//完成编辑 导出编辑后的对象
- (void)doneEditBtnClicked:(id)sender {
    [self hiddenPreviewButton:YES];
    [self hiddenEditMenus:YES];
    _editMenuView = nil;
    [self.selectedBox removeFromSuperview];
    [self exportEditPicture];
}
//导出编辑后的图片
- (void)exportEditPicture {
    self.image = [self.preview sl_imageByViewInRect:self.preview.bounds];
    self.preview.image = self.image;
    [self hiddenPreviewButton:NO];
    [self.drawView removeFromSuperview];
    [self.mosaicView removeFromSuperview];
    for (UIView *view in self.watermarkArray) {
        [view removeFromSuperview];
    }
}

// 点击水印视图
- (void)singleTapAction:(UITapGestureRecognizer *)singleTap {
    [self topSelectedView:singleTap.view];
    if (singleTap.state == UIGestureRecognizerStateFailed || singleTap.state == UIGestureRecognizerStateEnded) {
        [self startDelayPerform:^{
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
        [self startDelayPerform:^{
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
        //删除拖拽的视图
        if (self.trashTips.center.y < rect.origin.y+rect.size.height/2.0) {
            [pan.view  removeFromSuperview];
            [self.watermarkArray removeObject:(SLImageView *)pan.view];
        }else if (pan.view.sl_y >= self.preview.sl_h) {
            //如果出了父视图preview的范围，则置于父视图中心
            pan.view.center = CGPointMake(self.preview.sl_w/2.0, self.preview.sl_h/2.0);
        }
        [self.trashTips removeFromSuperview];
        [self startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
}
//缩放 水印视图
- (void)pinchAction:(UIPinchGestureRecognizer *)pinch {
    if (pinch.state == UIGestureRecognizerStateBegan) {
        [self topSelectedView:pinch.view];
    }else if (pinch.state == UIGestureRecognizerStateFailed || pinch.state == UIGestureRecognizerStateEnded){
        [self startDelayPerform:^{
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
        [self startDelayPerform:^{
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
    [self cancelDelayPerform]; //取消延迟执行
    [topView addSubview:self.selectedBox];
    self.selectedBox.frame = topView.bounds;
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

@end
