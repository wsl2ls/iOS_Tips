//
//  SLAPMViewController.m
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMViewController.h"
#import "SLAPMManager.h"


/*
 参考资料：https://www.jianshu.com/p/95df83780c8f
 */

@interface SLAPMViewController ()

@end

@implementation SLAPMViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"APM监控";
    [self setupNavigationBar];
}

#pragma mark - UI
- (void)setupNavigationBar {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:([SLAPMManager manager].isMonitoring ? @"停止":@"开始") style:UIBarButtonItemStyleDone target:self action:@selector(changeMonitorState)];
}

#pragma mark - Events Handle
///改变监听状态
- (void)changeMonitorState{
    if ([SLAPMManager manager].isMonitoring) {
        [[SLAPMManager manager] stopMonitoring];
    }else {
        [[SLAPMManager manager] startMonitoring];
    }
    [self setupNavigationBar];
}

@end
