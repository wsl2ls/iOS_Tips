//
//  ViewController.m
//  DarkMode
//
//  Created by wsl on 2019/9/16.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "ViewController.h"
#import "SLDarkModeViewController.h"
#import "SLAVListViewController.h"
#import "SLOpenGLController.h"
#import "SLWorkIssuesViewController.h"
#import "SLCrashViewController.h"
#import "SLWebViewListController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableArray *classArray;
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
                                           @"AVFoundation音视频相关",
                                           @"OpenGL-ES学习",
                                           @"LeetCode算法练习集合",
                                           @"工作中踩过的坑",
                                           @"iOS Crash防护",
                                           @"WKWebView相关"]];
    [self.classArray addObjectsFromArray:@[[SLDarkModeViewController class],
                                           [UIViewController class],
                                           [SLAVListViewController class],
                                           [SLOpenGLController class],
                                           [UIViewController class],
                                           [SLWorkIssuesViewController class],
                                           [SLCrashViewController class],
                                           [SLWebViewListController class]]];
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
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row + 1,self.dataSource[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIViewController *nextVc = [[self.classArray[indexPath.row] alloc] init];
    switch (indexPath.row) {
        case 1: {
            [SLAlertView showAlertViewWithText:@"查看本仓库下的AddingTheSignInWithAppleFlowToYourApp" delayHid:2];
        }
            break;
        case 4: {
                [SLAlertView showAlertViewWithText:@"LeetCode算法练习集合: https://github.com/wsl2ls/AlgorithmSet.git" delayHid:2];
            }
            break;
        default:
            [self.navigationController pushViewController:nextVc animated:YES];
            break;
    }
}

@end
