//
//  SLWebViewListController.m
//  DarkMode
//
//  Created by wsl on 2020/5/27.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebViewListController.h"
#import "SLWebViewController.h"
#import "SLWebTableViewController.h"
#import "SLWebTableViewController2.h"
#import "SLWebTableViewController3.h"
#import "SLWebTableViewController4.h"
#import "SLScrollViewController.h"
#import "SLWebCacheViewController.h"
#import "SLWebNativeViewController.h"
#import "SLTableViewController.h"

@interface SLWebViewListController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subTitles;
@property (nonatomic, strong) NSMutableArray *classArray;
@end

@implementation SLWebViewListController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getData];
    [self setupUI];
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
    self.navigationItem.title = @"WKWebView";
    [self.view addSubview:self.tableView];
}

#pragma mark - Data
- (void)getData {
    //tableView、UIAlertView等系统控件，在不自定义颜色的情况下，默认颜色都是动态的，支持暗黑模式
    [self.titles addObjectsFromArray:@[@" WKWebView的使用 ",
                                       @" WKWebView + UITableView（方案1 不推荐）",
                                       @" WKWebView + UITableView（方案2）",
                                       @" WKWebView + UITableView（方案3）(推荐)",
                                       @" WKWebView + UITableView（方案4）(推荐) ",
                                       @" WKWebView离线缓存",
                                       @" WKWebView渲染的部分HTML元素替换为用原生组件显示",
                                       @" UIScrollView的实现原理",
                                       @" UITableView的原理"]];
    [self.subTitles addObjectsFromArray:@[@" WKWebView的使用、JS和OC的交互、网页内容加载进度条的实现、NSNSURLProtocol拦截、Cookies丢失、设置UserAgent",
                                          @" tableView.tableHeaderView = webView 撑开webView ",
                                          @" [webView.scrollView addSubview:tableView] + 占位Div ",
                                          @" tableView.tableHeaderView = webView 不撑开webView ",
                                          @" [UIScrollView addSubView: WKWebView & UITableView]",
                                          @" NSURLProtocol 和 NSURLCache 两种缓存方案",
                                          @" 图片、视频、音频等元素用原生组件显示",
                                          @"SLScrollView继承于UIView，自定义实现UIScrollView的效果",@" 用UIScrollView实现 类似UITableView的复用功能"]];
    [self.classArray addObjectsFromArray:@[[SLWebViewController class],
                                           [SLWebTableViewController class],
                                           [SLWebTableViewController2 class],
                                           [SLWebTableViewController3 class],
                                           [SLWebTableViewController4 class],
                                           [SLWebCacheViewController class],
                                           [SLWebNativeViewController class],
                                           [SLScrollViewController class],
                                           [SLTableViewController class]]];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 1;
    }
    return _tableView;
}
- (NSMutableArray *)titles {
    if (_titles == nil) {
        _titles = [NSMutableArray array];
    }
    return _titles;
}
- (NSMutableArray *)subTitles {
    if (_subTitles == nil) {
        _subTitles = [NSMutableArray array];
    }
    return _subTitles;
}
- (NSMutableArray *)classArray {
    if (!_classArray) {
        _classArray = [NSMutableArray array];
    }
    return _classArray;
}

#pragma mark - UITableViewDelegate, UITableViewtitles
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titles.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cellId"];
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row,self.titles[indexPath.row]];
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = self.subTitles[indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIViewController *nextVc = [[self.classArray[indexPath.row] alloc] init];
    nextVc.title = self.titles[indexPath.row];
    [self.navigationController pushViewController:nextVc animated:YES];
}


@end
