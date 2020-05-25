//
//  ViewController.m
//  DarkMode
//
//  Created by wsl on 2019/9/16.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "ViewController.h"
#import "SLDarkModeViewController.h"
#import "SLShotViewController.h"
#import "SLFaceDetectController.h"
#import "SLFilterViewController.h"
#import "SLGPUImageController.h"
#import "SLOpenGLController.h"
#import "SLMenuViewController.h"
#import "SLCrashViewController.h"
#import "SLWebViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation ViewController

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
    self.navigationItem.title = @"iOS Tips";
    self.navigationController.navigationBar.translucent = YES;
    self.tableView.estimatedRowHeight = 1;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
}

#pragma mark - Data
- (void)getData {
    //tableView、UIAlertView等系统控件，在不自定义颜色的情况下，默认颜色都是动态的，支持暗黑模式
    [self.dataSource addObjectsFromArray:@[@"暗黑/光亮模式",
                                           @"AppleId三方登录应用",
                                           @"AVFoundation 高仿微信相机拍摄和编辑功能",
                                           @"AVFoundation 人脸检测",
                                           @"AVFoundation 实时滤镜拍摄和导出",
                                           @"GPUImage框架的使用",
                                           @"VideoToolBox和AudioToolBox音视频编解码",
                                           @"OpenGL-ES学习", @"LeetCode算法练习集合",
                                           @"键盘和UIMenuController不能同时存在的问题",
                                           @"iOS Crash防护",
                                           @"WKWebView优化（doing）"]];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

#pragma mark - HelpMethods

#pragma mark - EventsHandle

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row + 1,self.dataSource[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0: {
            SLDarkModeViewController * darkModeViewController = [[SLDarkModeViewController alloc] init];
            [self.navigationController pushViewController:darkModeViewController animated:YES];
        }
            break;
        case 1: {
            [SLAlertView showAlertViewWithText:@"查看本仓库下的AddingTheSignInWithAppleFlowToYourApp" delayHid:2];
            NSLog(@"查看本仓库下的AddingTheSignInWithAppleFlowToYourApp");
        }
            break;
        case 2: {
            SLShotViewController * shotViewController = [[SLShotViewController alloc] init];
            shotViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:shotViewController animated:YES completion:nil];
        }
            break;
        case 3: {
            SLFaceDetectController * faceDetectController = [[SLFaceDetectController alloc] init];
            faceDetectController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:faceDetectController animated:YES completion:nil];
        }
            break;
        case 4: {
            SLFilterViewController * filterViewController = [[SLFilterViewController alloc] init];
            filterViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:filterViewController animated:YES completion:nil];
        }
            break;
        case 5: {
            SLGPUImageController * gpuImageController = [[SLGPUImageController alloc] init];
            gpuImageController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:gpuImageController animated:YES completion:nil];
        }
            break;
        case 6:
            [SLAlertView showAlertViewWithText:@"查看本仓库下的VideoEncoder&Decoder" delayHid:2];
            NSLog(@"查看本仓库下的VideoEncoder&Decoder");
            break;
        case 7: {
            SLOpenGLController * openGLController = [[SLOpenGLController alloc] init];
            [self.navigationController pushViewController:openGLController animated:YES];
        }
            break;
        case 8: {
            [SLAlertView showAlertViewWithText:@"LeetCode算法练习集合地址：https://github.com/wsl2ls/AlgorithmSet.git" delayHid:2];
            NSLog(@"LeetCode算法练习集合地址：https://github.com/wsl2ls/AlgorithmSet.git");
        }
            break;
        case 9: {
            SLMenuViewController *menuViewController = [[SLMenuViewController alloc] init];
            [self.navigationController pushViewController:menuViewController animated:YES];
        }
            break;
        case 10: {
            SLCrashViewController *crashViewController = [[SLCrashViewController alloc] init];
            [self.navigationController pushViewController:crashViewController animated:YES];
        }
            break;
        case 11: {
            SLWebViewController *webViewController = [[SLWebViewController alloc] init];
            [self.navigationController pushViewController:webViewController animated:YES];
        }
            break;
        default:
            break;
    }
}

@end
