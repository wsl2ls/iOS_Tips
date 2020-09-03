//
//  SLScrollviewNesteVC.m
//  DarkMode
//
//  Created by wsl on 2020/9/2.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLScrollviewNesteVC.h"
#import "SLMenuView.h"

///mainScrollView头部高度
static CGFloat  mainScrollViewHeadHeight = 250;
///选项卡高度
static CGFloat tabHeight = 50;

@interface SLTableView : UITableView
@end



@interface SLScrollviewNesteVC ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate, SLMenuViewDelegate>

@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UIImageView *headView;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) SLMenuView *menuView;
@property (nonatomic, strong) UIScrollView *tabScrollView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation SLScrollviewNesteVC

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

#pragma mark - UI
- (void)setupUI {
    
    [self.view addSubview:self.mainScrollView];
    
    [self.mainScrollView addSubview:self.headView];
    self.headView.frame = CGRectMake(0, 0, self.mainScrollView.sl_width, mainScrollViewHeadHeight);
    
    self.containerView.frame = CGRectMake(0, mainScrollViewHeadHeight, SL_kScreenWidth, SL_kScreenHeight-SL_TopNavigationBarHeight);
    [self.mainScrollView addSubview:self.containerView];
    self.mainScrollView.contentSize = CGSizeMake(SL_kScreenWidth, mainScrollViewHeadHeight+self.containerView.sl_height);
    
    [self.containerView addSubview:self.menuView];
    [self.menuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(0);
        make.height.mas_equalTo(tabHeight);
    }];
    self.menuView.titles = @[@"你好",@"我好",@"大家好"];
    self.menuView.currentPage = 0;
    
    [self.containerView addSubview:self.tabScrollView];
    [self.tabScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.containerView);
        make.top.mas_equalTo(tabHeight);
    }];
    [self.containerView layoutIfNeeded];
    self.tabScrollView.contentSize = CGSizeMake(SL_kScreenWidth*self.menuView.titles.count,self.tabScrollView.frame.size.height);
    
    for (int i = 0; i < self.menuView.titles.count; i++) {
        UITableView *tableView = [self tableView];
        tableView.tag = i;
        tableView.scrollEnabled = NO;
        tableView.frame = CGRectMake(i*self.tabScrollView.sl_width, 0,  self.tabScrollView.sl_width, self.tabScrollView.sl_height);
        [self.tabScrollView addSubview:tableView];
    }
}

#pragma mark - Data

#pragma mark - Getter
- (UIScrollView *)mainScrollView {
    if (!_mainScrollView) {
        _mainScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _mainScrollView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _mainScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
        }
    }
    return _mainScrollView;
}
- (UIImageView *)headView {
    if (!_headView) {
        _headView = [[UIImageView alloc] init];
        _headView.image = [UIImage imageNamed:@"wsl"];
        _headView.contentMode = UIViewContentModeScaleAspectFit;
        _headView.backgroundColor = [UIColor orangeColor];
    }
    return _headView;
}
- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor redColor];
    }
    return _containerView;
}
- (SLMenuView *)menuView {
    if (!_menuView) {
        _menuView = [[SLMenuView alloc] init];
        _menuView.backgroundColor = [UIColor orangeColor];
        _menuView.delegate = self;
    }
    return _menuView;
}
- (UIScrollView *)tabScrollView {
    if (!_tabScrollView) {
        _tabScrollView = [[UIScrollView alloc] init];
        _tabScrollView.backgroundColor = [UIColor blueColor];
        _tabScrollView.pagingEnabled = YES;
        _tabScrollView.delegate = self;
        _tabScrollView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            _tabScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
        }
    }
    return _tabScrollView;
}
- (UITableView *)tableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.estimatedRowHeight = 0;
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
    }
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
    return tableView;
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
    cell.textLabel.text = [NSString stringWithFormat:@"%ld",indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SLMenuViewDelegate
- (void)menuView:(SLMenuView *)menuView didSelectItemAtIndex:(NSInteger)index {
    [self.tabScrollView setContentOffset:CGPointMake(index* self.tabScrollView.sl_width, 0) animated:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.tabScrollView) {
        self.menuView.currentPage = roundf(self.tabScrollView.contentOffset.x/self.tabScrollView.sl_width);
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.tabScrollView) {
        self.menuView.currentPage = roundf(self.tabScrollView.contentOffset.x/self.tabScrollView.sl_width);
    }
}


@end
