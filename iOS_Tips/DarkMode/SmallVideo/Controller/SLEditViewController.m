//
//  SLEditViewController.m
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditViewController.h"
#import <Photos/Photos.h>
#import "UIView+SLFrame.h"
#import "SLBlurView.h"
#import "SLEditMenuView.h"
#import "SLEditViewController.h"
#import "SLAvPlayer.h"
#import "SLAvCaptureTool.h"

@interface SLEditViewController ()

@property (nonatomic, strong) SLBlurView *editBtn; //编辑
@property (nonatomic, strong) SLBlurView *againShotBtn;  // 再拍一次
@property (nonatomic, strong) UIButton *saveAlbumBtn;  //保存到相册

@property (nonatomic, strong) UIButton *cancleEditBtn; //取消编辑
@property (nonatomic, strong) UIButton *doneEditBtn; //完成编辑
@property (nonatomic, strong) SLEditMenuView *editMenuView; //编辑菜单栏

@property (nonatomic, strong) UIImageView *preview; // 预览视图 展示图片或视频

@end

@implementation SLEditViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (BOOL)shouldAutorotate {
    return NO;
}
#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.preview];
    if (self.image) {
        self.preview.image = self.image;
    }else {
        SLAvPlayer *avPlayer = [SLAvPlayer sharedAVPlayer];
        avPlayer.url = self.videoPath;
        avPlayer.monitor = self.preview;
        [avPlayer play];
    }
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
        [self.view addSubview:_editMenuView];
    }
    return _editMenuView;
}

#pragma mark - HelpMethods

#pragma mark - EventsHandle
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
    [self dismissViewControllerAnimated:NO completion:nil];
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

@end
