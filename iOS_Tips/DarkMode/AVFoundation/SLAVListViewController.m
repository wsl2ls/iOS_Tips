//
//  SLAVListTableViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAVListViewController.h"

#import "SLShotViewController.h"
#import "SLFaceDetectController.h"
#import "SLFilterViewController.h"
#import "SLGPUImageController.h"
#import "SLColorPickerViewController.h"
#import "SLWebViewController.h"

@interface SLAVListViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableArray *classArray;
@end

@implementation SLAVListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self getData];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}
- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - UI
- (void)setupUI {
    self.navigationItem.title = @"AVFoundation 音视频";
    self.navigationController.navigationBar.translucent = YES;
    self.tableView.estimatedRowHeight = 1;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
}

#pragma mark - Data
- (void)getData {
    [self.dataSource addObjectsFromArray:@[
        @"AVFoundation 高仿微信相机拍摄和编辑功能",
        @"AVFoundation 人脸检测",
        @"AVFoundation 实时滤镜拍摄和导出",
        @"GPUImage框架的使用",
        @"VideoToolBox和AudioToolBox音视频编解码",
        @"AVFoundation 利用摄像头实时识别物体颜色",
        @"AVFoundation 原生二维码扫描识别和生成"]];
    [self.classArray addObjectsFromArray:@[[SLShotViewController class],
                                           [SLFaceDetectController class],
                                           [SLFilterViewController class],
                                           [SLGPUImageController class],
                                           [UIViewController class],
                                           [SLColorPickerViewController class],
                                           [SLWebViewController class]]];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}
- (NSMutableArray *)classArray {
    if (_classArray == nil) {
        _classArray = [NSMutableArray array];
    }
    return _classArray;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row ,self.dataSource[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIViewController *nextVc = [[self.classArray[indexPath.row] alloc] init];
    switch (indexPath.row) {
        case 0:
        case 1:
        case 2:
        case 3: {
            nextVc.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:nextVc animated:YES completion:nil];
        }
            break;
        case 4:
            [SLAlertView showAlertViewWithText:@"查看本仓库下的VideoEncoder&Decoder" delayHid:2];
            break;
        case 6:
             ((SLWebViewController *)nextVc).urlString = @"https://juejin.im/post/5c0e1db651882539c60d0434";
        default:
            [self.navigationController pushViewController:nextVc animated:YES];
            break;
        }
    }
@end
