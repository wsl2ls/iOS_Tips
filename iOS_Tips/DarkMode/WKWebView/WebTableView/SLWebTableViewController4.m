//
//  SLWebTableViewController4.m
//  DarkMode
//
//  Created by wsl on 2020/5/28.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebTableViewController4.h"
#import <WebKit/WebKit.h>

@interface SLWebTableViewController4 ()<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate,
WKNavigationDelegate>
{
    CGFloat _webViewContentHeight;
    CGFloat _tableViewContentHeight;
    int _dataCount;  //tableView的数据个数
}

///网页加载进度视图
@property (nonatomic, strong) UIProgressView * progressView;

@property (nonatomic, strong) WKWebView  *webView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIScrollView *containerScrollView;
@property (nonatomic, strong) UIView *contentView;

@end

@implementation SLWebTableViewController4

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self seupUI];
    [self addKVO];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.progressView removeFromSuperview];
}
- (void)dealloc {
    [self removeKVO];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UI
- (void)seupUI{
    _webViewContentHeight = 0;
    _tableViewContentHeight = 0;
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"WKWebView+UITableView（方案4）";
    
    [self.view addSubview:self.containerScrollView];
    [self.containerScrollView addSubview:self.contentView];
    [self.contentView addSubview:self.webView];
    [self.contentView addSubview:self.tableView];
}

#pragma mark - Getter
- (WKWebView *)webView{
    if (_webView == nil) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _webView.scrollView.scrollEnabled = NO;
        _webView.navigationDelegate = self;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"WebTableView.html" ofType:nil];
        NSString *htmlString = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        [_webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }
    return _webView;
}
- (UITableView *)tableView{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.view.sl_height, self.view.sl_width, self.view.sl_height) style:UITableViewStylePlain];
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.scrollEnabled = NO;
    }
    return _tableView;
}
- (UIScrollView *)containerScrollView{
    if (_containerScrollView == nil) {
        _containerScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _containerScrollView.delegate = self;
        _containerScrollView.alwaysBounceVertical = YES;
    }
    return _containerScrollView;
}
- (UIView *)contentView{
    if (_contentView == nil) {
        _contentView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.view.sl_width, self.view.sl_height * 2)];
    }
    return _contentView;
}
- (UIProgressView *)progressView {
    if (!_progressView){
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, 2)];
        _progressView.tintColor = [UIColor blueColor];
        _progressView.trackTintColor = [UIColor clearColor];
    }
    if (_progressView.superview == nil) {
        [self.navigationController.navigationBar addSubview:_progressView];
    }
    return _progressView;
}

#pragma mark - KVO
- (void)addKVO{
    [self.webView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self.webView addObserver:self forKeyPath:@"scrollView.contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)removeKVO{
    [_webView removeObserver:self
                  forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [self.webView removeObserver:self forKeyPath:@"scrollView.contentSize"];
    [self.tableView removeObserver:self forKeyPath:@"contentSize"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]
        && object == _webView) {
        self.progressView.progress = _webView.estimatedProgress;
        if (_webView.estimatedProgress >= 1.0f) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.progress = 0;
            });
        }
    }else if (object == _webView && [keyPath isEqualToString:@"scrollView.contentSize"] && _webViewContentHeight != _webView.scrollView.contentSize.height) {
        _webViewContentHeight = _webView.scrollView.contentSize.height;
        [self updateContainerScrollViewContentSize];
    }else if(object == _tableView && [keyPath isEqualToString:@"contentSize"] && _tableViewContentHeight != _tableView.contentSize.height ) {
        _tableViewContentHeight = _tableView.contentSize.height;
        [self updateContainerScrollViewContentSize];
    }
}

#pragma mark - Help Methods
/// 根据WebView和tableView的ContentSize变化，调整父scrollView.contentSize、WebView和tableView的高度位置、展示区域
- (void)updateContainerScrollViewContentSize{
    
    self.containerScrollView.contentSize = CGSizeMake(self.view.sl_width, _webViewContentHeight + _tableViewContentHeight);
    
    //如果内容不满一屏，则webView、tableView高度为内容高，超过一屏则最大高为一屏高
    CGFloat webViewHeight = (_webViewContentHeight < self.view.sl_height) ? _webViewContentHeight : self.view.sl_height ;
    CGFloat tableViewHeight = _tableViewContentHeight < self.view.sl_height ? _tableViewContentHeight : self.view.sl_height;
    
    self.contentView.sl_height = webViewHeight + tableViewHeight;
    self.webView.sl_height = webViewHeight <= 0.1 ?0.1 :webViewHeight;
    self.tableView.sl_height = tableViewHeight;
    self.tableView.sl_y = self.webView.sl_height;
    
    //更新展示区域
    [self scrollViewDidScroll:self.containerScrollView];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (_containerScrollView != scrollView) {
        return;
    }
    
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat webViewHeight = self.webView.sl_height;
    CGFloat tableViewHeight = self.tableView.sl_height;
    
    if (offsetY <= 0) {
        //顶部下拉
        self.contentView.sl_y = 0;
        self.webView.scrollView.contentOffset = CGPointZero;
        self.tableView.contentOffset = CGPointZero;
    }else if(offsetY < _webViewContentHeight - webViewHeight){
        //父scrollView偏移量的展示范围在webView的最大偏移量内容区域
        //contentView相对位置保持不动，调整webView的contentOffset
        self.contentView.sl_y = offsetY;
        self.webView.scrollView.contentOffset = CGPointMake(0, offsetY);
        self.tableView.contentOffset = CGPointZero;
    }else if(offsetY < _webViewContentHeight){
        //webView滑到了底部
        self.contentView.sl_y = _webViewContentHeight - webViewHeight;
        self.webView.scrollView.contentOffset = CGPointMake(0, _webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointZero;
    }else if(offsetY < _webViewContentHeight + _tableViewContentHeight - tableViewHeight){
        //父scrollView偏移量的展示范围到达tableView的最大偏移量内容区域
        //调整tableView的contentOffset
        self.contentView.sl_y = offsetY - webViewHeight;
        self.tableView.contentOffset = CGPointMake(0, offsetY - _webViewContentHeight);
        self.webView.scrollView.contentOffset = CGPointMake(0, _webViewContentHeight - webViewHeight);
    }else if(offsetY <= _webViewContentHeight + _tableViewContentHeight ){
        //tableView滑到了底部
        self.contentView.sl_y = self.containerScrollView.contentSize.height - self.contentView.sl_height;
        self.webView.scrollView.contentOffset = CGPointMake(0, _webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointMake(0, _tableViewContentHeight - tableViewHeight);
    }else {
       
    }
}
#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //这里可以在webView加载完成之后，再刷新显示tableView的数据
    _dataCount = 15;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataCount == 0 ? 0 : 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataCount;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [UILabel new];
    label.text = @"评论";
    label.textColor = UIColor.whiteColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor orangeColor];
    return label;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cellId"];
    }
    cell.detailTextLabel.numberOfLines = 0;
    cell.textLabel.text = [NSString stringWithFormat:@"第%ld条评论",(long)indexPath.row];
    cell.detailTextLabel.text = @" 方案4：(推荐) \n [UIScrollView addSubView: WKWebView & UITableView]; \n UIScrollView.contenSize = WKWebView.contenSize + UITableView.contenSize; \n WKWebView和UITableView的最大高度为一屏高，并禁用scrollEnabled=NO，然后根据UIScrollView的滑动偏移量调整WKWebView和UITableView的展示区域contenOffset。";
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
