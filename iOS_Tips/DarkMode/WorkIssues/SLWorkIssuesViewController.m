//
//  SLWorkIssuesViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWorkIssuesViewController.h"
#import "SLMenuViewController.h"
#import "SLWebViewController.h"
#import "SLBinaryResetViewController.h"
#import "SLAPMViewController.h"
#import "SLUnusedResourceViewController.h"
#import "SLScrollviewNesteVC.h"

@interface SLWorkIssuesViewController ()
@property (nonatomic, strong) NSMutableArray *titlesArray;
@property (nonatomic, strong) NSMutableArray *urlArray;
@property (nonatomic, strong) NSMutableArray *classArray;
@end

@implementation SLWorkIssuesViewController

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
    self.navigationItem.title = @"工作中踩过的坑";
    self.navigationController.navigationBar.translucent = YES;
    self.tableView.estimatedRowHeight = 1;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
}

#pragma mark - Data
- (void)getData {
    [self.titlesArray addObjectsFromArray:@[
        @"键盘和UIMenuController不能同时存在的问题",
        @"全屏侧滑手势/UIScrollView/UISlider间滑动手势冲突",
        @"UITableView/UICollectionView获取特定位置的cell",
        @"UIScrollView视觉差动画",
        @"iOS 传感器集锦",
        @"iOS 自定义转场动画",
        @"二进制重排优化启动时间",
        @"iOS APM应用性能监控管理(doing)",
        @"ipa瘦身之扫描无用资源",
        @"多个UIScrollView嵌套"]];
    [self.urlArray addObjectsFromArray:@[@"",
                                         @"https://juejin.im/post/5c0e1e73f265da616413d828",
                                         @"https://juejin.im/post/5c0e1df95188250d2722a3bc",
                                         @"https://juejin.im/post/5c088b45f265da610e7fe156",
                                         @"https://juejin.im/post/5c088a1051882517165dd15d",
                                         @"https://juejin.im/post/5c088ba36fb9a049fb43737b",
                                         @"二进制重排",
                                         @"APM",
                                         @"ipa瘦身",
                                         @"UIScrollView嵌套"]];
    [self.classArray addObjectsFromArray:@[[SLMenuViewController class],
                                           [SLWebViewController class],
                                           [SLWebViewController class],
                                           [SLWebViewController class],
                                           [SLWebViewController class],
                                           [SLWebViewController class],
                                           [SLBinaryResetViewController class],
                                           [SLAPMViewController class],
                                           [SLUnusedResourceViewController class],
                                           [SLScrollviewNesteVC class]]];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (NSMutableArray *)titlesArray {
    if (_titlesArray == nil) {
        _titlesArray = [NSMutableArray array];
    }
    return _titlesArray;
}
- (NSMutableArray *)urlArray {
    if (!_urlArray) {
        _urlArray = [NSMutableArray array];
    }
    return _urlArray;;
}
- (NSMutableArray *)classArray {
    if (_classArray == nil) {
        _classArray = [NSMutableArray array];
    }
    return _classArray;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titlesArray.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row,self.titlesArray[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIViewController *nextVc = [[self.classArray[indexPath.row] alloc] init];
    NSString *urlString = self.urlArray[indexPath.row];
    nextVc.navigationItem.title = self.titlesArray[indexPath.row];
    switch (indexPath.row) {
        default:
            if (urlString.length > 0 && [urlString hasPrefix:@"http"]) {
                ((SLWebViewController *)nextVc).urlString = urlString;
            }
            [self.navigationController pushViewController:nextVc animated:YES];
            break;
    }
}
@end
