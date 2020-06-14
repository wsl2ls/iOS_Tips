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

@interface SLWorkIssuesViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;
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
    [self.dataSource addObjectsFromArray:@[
        @"键盘和UIMenuController不能同时存在的问题",
        @"全屏侧滑手势/UIScrollView/UISlider间滑动手势冲突"]];
    [self.classArray addObjectsFromArray:@[[SLMenuViewController class],
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
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row + 1,self.dataSource[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIViewController *nextVc = [[self.classArray[indexPath.row] alloc] init];
    switch (indexPath.row) {
        case 1:
            ((SLWebViewController *)nextVc).urlString = @"https://juejin.im/post/5c0e1e73f265da616413d828";
        default:
            [self.navigationController pushViewController:nextVc animated:YES];
            break;
        }
    }
@end
