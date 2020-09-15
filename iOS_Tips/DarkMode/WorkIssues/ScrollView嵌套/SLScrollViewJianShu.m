//
//  SLScrollViewJianShu.m
//  DarkMode
//
//  Created by wsl on 2020/9/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLScrollViewJianShu.h"
#import "SLMenuView.h"
#import <MJRefresh.h>
#import "SLPanTableView.h"

///mainScrollView头部高度
static CGFloat  mainScrollViewHeadHeight = 250;
///选项卡/菜单栏高度
static CGFloat tabHeight = 50;

@interface SLScrollViewJianShu ()
<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate, SLMenuViewDelegate>

@property (nonatomic, strong) UIView *navigationView;
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, assign) BOOL isTopHovering;  //正在顶部悬停

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) SLMenuView *menuView;
@property (nonatomic, strong) UIScrollView *tabScrollView;

//默认 20
@property (nonatomic, assign) NSInteger dataCount;
//滑动到当前子列表时的偏移量，主要处理顶部未悬停且子列表未置顶偏移量不为0时的情况
@property (nonatomic, assign) CGPoint lastContentOffset;
@end

@implementation SLScrollViewJianShu

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
    [self getData];
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
    self.headView.frame = CGRectMake(0, 0, 100, 100);
    self.headView.center = CGPointMake(SL_kScreenWidth/2.0, mainScrollViewHeadHeight/2.0);
    
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
        SLPanTableView *tableView = [self subTableView];
        tableView.tag = 10+i;
        tableView.frame = CGRectMake(i*self.tabScrollView.sl_width, 0,  self.tabScrollView.sl_width, self.tabScrollView.sl_height);
        [self.tabScrollView addSubview:tableView];
    }
    
    [self.view addSubview:self.navigationView];
}

#pragma mark - Data
- (void)getData {
    self.dataCount = 20;
    [[self currentSubListTabView].mj_header beginRefreshing];
}

#pragma mark - Getter
- (UIView *)navigationView {
    if (!_navigationView) {
        _navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,SL_kScreenWidth , SL_TopNavigationBarHeight)];
        _navigationView.backgroundColor = [UIColor clearColor];
        UIButton *nav_return_white = [[UIButton alloc] init];
        [nav_return_white setImage:[UIImage imageNamed:@"nav_return_white"] forState:UIControlStateNormal];
        [nav_return_white addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        [_navigationView addSubview:nav_return_white];
        [nav_return_white mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(10);
            make.size.mas_equalTo(CGSizeMake(15, 20));
            make.bottom.mas_equalTo(-10);
        }];
    }
    return _navigationView;
}
- (UIScrollView *)mainScrollView {
    if (!_mainScrollView) {
        _mainScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _mainScrollView.delegate = self;
        _mainScrollView.bounces = YES;
        _mainScrollView.showsVerticalScrollIndicator = NO;
        _mainScrollView.backgroundColor = [UIColor colorWithRed:11/255.0 green:112/255.0 blue:230/255.0 alpha:1.0];
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
        _headView.layer.cornerRadius = 50;
        _headView.clipsToBounds = YES;
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
        _menuView.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0];
        _menuView.delegate = self;
        _menuView.layer.borderWidth = 1.0;
        _menuView.layer.borderColor = [UIColor colorWithRed:228/255.0 green:228/255.0 blue:228/255.0 alpha:1.0].CGColor;
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
- (SLPanTableView *)subTableView {
    SLPanTableView *tableView = [[SLPanTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.estimatedRowHeight = 0;
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
    }
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
    SL_WeakSelf;
    tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.dataCount = 20;
            [tableView reloadData];
            [tableView.mj_header endRefreshing];
        });
    }];
    tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.dataCount += 20;
            [tableView reloadData];
            [tableView.mj_footer endRefreshing];
        });
    }];
    return tableView;
}

#pragma mark - EventsHandle
- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - HelpMethods
///当前子列表
- (SLPanTableView *)currentSubListTabView {
    return [self.tabScrollView viewWithTag:10+self.menuView.currentPage];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataCount;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
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
    
    if (scrollView == self.tabScrollView) return;
    
    if (scrollView == self.mainScrollView) {
        if (self.mainScrollView.contentOffset.y >= mainScrollViewHeadHeight-SL_TopNavigationBarHeight || _isTopHovering) {
            //滑到顶部悬停
            _isTopHovering = YES;
            self.mainScrollView.contentOffset = CGPointMake(0, mainScrollViewHeadHeight-SL_TopNavigationBarHeight);
        }
        if(_isTopHovering) {
            self.navigationController.navigationBar.hidden = NO;
        }else {
            self.navigationController.navigationBar.hidden = YES;
        }
        
        if (self.mainScrollView.contentOffset.y <= 0 ) {
            //头部放大
            self.headView.transform = CGAffineTransformMakeScale(fabs(self.mainScrollView.contentOffset.y)/self.headView.sl_height+1, fabs(self.mainScrollView.contentOffset.y)/self.headView.sl_height+1);
        }
    }
    
    //子列表
    if (scrollView.superview == self.tabScrollView) {
        if((!_isTopHovering && self.mainScrollView.contentOffset.y > 0) || (self.mainScrollView.contentOffset.y < 0 ) ) {
            //如果主mainScrollView还未到顶部悬停，则选项子列表subTableView偏移量保持不变
            if (scrollView.contentOffset.y < 0) {
                self.lastContentOffset = CGPointZero;
            }
            scrollView.contentOffset = self.lastContentOffset;
        }
        if(_isTopHovering && scrollView.contentOffset.y > 0) {
            //如果主mainScrollView在顶部悬停，而此时选项子列表subTableView还未到顶部，则保持mainScrollView继续悬停
            self.mainScrollView.contentOffset = CGPointMake(0, mainScrollViewHeadHeight-SL_TopNavigationBarHeight);
        }
        if (scrollView.contentOffset.y < 0) {
            //如果subTableView滑动到了顶部，即将取消顶部悬停
            _isTopHovering = NO;
        }
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.tabScrollView) {
        self.menuView.currentPage = roundf(self.tabScrollView.contentOffset.x/self.tabScrollView.sl_width);
        self.lastContentOffset = [self currentSubListTabView].contentOffset;
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.tabScrollView) {
        self.menuView.currentPage = roundf(self.tabScrollView.contentOffset.x/self.tabScrollView.sl_width);
        self.lastContentOffset = [self currentSubListTabView].contentOffset;
    }
}

@end
