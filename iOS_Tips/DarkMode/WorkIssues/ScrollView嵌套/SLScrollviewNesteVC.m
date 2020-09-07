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
static CGFloat  mainScrollViewHeadHeight = 300;
///选项卡高度
static CGFloat tabHeight = 50;

@interface SLPanTableView : UITableView
@end
@implementation SLPanTableView
//是否允许多个手势识别器共同识别，一个控件的手势识别后是否阻断手势识别继续向下传播，默认返回NO，上层对象识别后则不再继续传播；如果为YES，响应者链上层对象触发手势识别后，如果下层对象也添加了手势并成功识别也会继续执行。
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}
@end

@interface SLScrollviewNesteVC ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate, SLMenuViewDelegate>
{
    UIImage *_backgroundImage;
    UIImage *_shadowImage;
}

@property (nonatomic, strong) UIView *navigationView;
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
        SLPanTableView *tableView = [self tableView];
        tableView.tag = i;
        tableView.frame = CGRectMake(i*self.tabScrollView.sl_width, 0,  self.tabScrollView.sl_width, self.tabScrollView.sl_height);
        [self.tabScrollView addSubview:tableView];
    }
    
    
    [self.view addSubview:self.navigationView];
}

#pragma mark - Data

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
        _mainScrollView.bounces = NO;
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
        _headView.backgroundColor = [UIColor colorWithRed:11/255.0 green:112/255.0 blue:230/255.0 alpha:1.0];;
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
- (SLPanTableView *)tableView {
    SLPanTableView *tableView = [[SLPanTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
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
- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

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
    if (scrollView == self.mainScrollView) {
        //根据偏移量操作导航栏
        if(self.mainScrollView.contentOffset.y == mainScrollViewHeadHeight-SL_TopNavigationBarHeight) {
            self.navigationController.navigationBar.hidden = NO;
        }else {
            self.navigationController.navigationBar.hidden = YES;
        }
        if (self.mainScrollView.contentOffset.y > mainScrollViewHeadHeight-SL_TopNavigationBarHeight) {
            //滑到了顶部，悬停，开启子列表滑动功能
            self.mainScrollView.contentOffset = CGPointMake(0, mainScrollViewHeadHeight-SL_TopNavigationBarHeight);
        }
    }
    
    //子列表
    if (scrollView.superview == self.tabScrollView) {
        if (self.mainScrollView.contentOffset.y < mainScrollViewHeadHeight-SL_TopNavigationBarHeight) {
            scrollView.contentOffset = CGPointMake(0, 0);
        }
    }
    
    
    
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
