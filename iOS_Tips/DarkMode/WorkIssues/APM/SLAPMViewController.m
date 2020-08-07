//
//  SLAPMViewController.m
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMViewController.h"
#import "SLAPMManager.h"

#import "SLSystemAppInfo.h"

/*
 参考资料：
 https://www.jianshu.com/p/95df83780c8f
 https://www.jianshu.com/p/8123fc17fe0e
 https://juejin.im/post/5e92a113e51d4547134bdadb
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
    [SLAPMManager manager].type = SLAPMTypeNetwork;
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - UI
- (void)setupNavigationBar {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:([SLAPMManager manager].isMonitoring ? @"停止监控":@"开始监控") style:UIBarButtonItemStyleDone target:self action:@selector(changeMonitorState)];
}

#pragma mark - Help Methods
///测试卡顿/流畅度
- (void)testFluency {
    //耗时任务
    //    sleep(1);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
    });
}
///测试网络监控
- (void)testNetworkMonitor {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.mas_equalTo(0);
    }];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://b-ssl.duitang.com/uploads/item/201507/13/20150713182820_5mHce.jpeg"]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = image;
        });
    });
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
