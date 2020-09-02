//
//  SLScrollviewNesteVC.m
//  DarkMode
//
//  Created by wsl on 2020/9/2.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLScrollviewNesteVC.h"

///mainScrollView头部高度
static CGFloat  mainScrollViewHeadHeight = 300;

@interface SLScrollviewNesteVC ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *mainScrollView;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITableView *tableView1;
@property (nonatomic, strong) UITableView *tableView2;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation SLScrollviewNesteVC

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.mainScrollView];
    [self.mainScrollView addSubview:self.containerView];
    self.containerView.frame = CGRectMake(0, mainScrollViewHeadHeight, SL_kScreenWidth, SL_kScreenHeight-SL_TopNavigationBarHeight);
    self.mainScrollView.contentSize = CGSizeMake(SL_kScreenWidth, self.containerView.sl_y+self.containerView.sl_height);
    
    
    
//    self.containerView.contentSize = CGSizeMake(SL_kScreenWidth*2, self.containerView.sl_y+self.containerView.sl_height);
//    [self.containerView addSubview:self.tableView1];
//    [self.containerView addSubview:self.tableView2];
    
    
}

#pragma mark - Data

#pragma mark - Getter
- (UIScrollView *)mainScrollView {
    if (!_mainScrollView) {
        _mainScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _mainScrollView.backgroundColor = [UIColor orangeColor];
        if (@available(iOS 11.0, *)) {
            _mainScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
    return _mainScrollView;
}
- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor redColor];
    }
    return _containerView;
}
- (UITableView *)tableView1 {
    if (!_tableView1) {
        _tableView1 = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight) style:UITableViewStyleGrouped];
        _tableView1.delegate = self;
        _tableView1.dataSource = self;
        _tableView1.estimatedRowHeight = 0;
        if (@available(iOS 11.0, *)) {
            _tableView1.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
        [_tableView1 registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
    }
    return _tableView1;
}
- (UITableView *)tableView2 {
    if (!_tableView2) {
        _tableView2 = [[UITableView alloc] initWithFrame:CGRectMake(SL_kScreenWidth, 0, SL_kScreenWidth, SL_kScreenHeight) style:UITableViewStyleGrouped];
        _tableView2.delegate = self;
        _tableView2.dataSource = self;
        _tableView2.estimatedRowHeight = 0;
        if (@available(iOS 11.0, *)) {
            _tableView2.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
        [_tableView2 registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
    }
    return _tableView2;
}
- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

#pragma mark - Data

#pragma mark - EventsHandle

#pragma mark - HelpMethods

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellId" forIndexPath:indexPath];
    cell.textLabel.text = tableView == self.tableView1 ? @"tableView1" : @"tableView2";
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
