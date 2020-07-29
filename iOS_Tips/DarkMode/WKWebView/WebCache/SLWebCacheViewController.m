//
//  SLWebCacheViewController.m
//  DarkMode
//
//  Created by wsl on 2020/5/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebCacheViewController.h"
#import <WebKit/WebKit.h>
#import "SLWebCacheManager.h"

/*
  https://zhuanlan.zhihu.com/p/148931732  WKWebView离线化方案——实现Service Worker API
  https://github.com/ming1016/STMURLCache   戴明大神
 */
@interface SLWebCacheViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView * webView;
///网页加载进度视图
@property (nonatomic, strong) UIProgressView * progressView;
/// WKWebView 内容的高度
@property (nonatomic, assign) CGFloat webContentHeight;

@end

@implementation SLWebCacheViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self addKVO];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.progressView removeFromSuperview];
}
- (void)dealloc {
    [self removeKVO];
    //关闭缓存
    [[SLWebCacheManager shareInstance] closeCache];
}

#pragma mark - UI
- (void)setupUI {
    self.navigationItem.title = @"WK缓存方案";
    self.view.backgroundColor = UIColor.whiteColor;
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"上一步" style:UIBarButtonItemStyleDone target:self action:@selector(goBackAction:)];
    UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleDone target:self action:@selector(goForwardAction:)];
    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:@"清理缓存" style:UIBarButtonItemStyleDone target:self action:@selector(clearCacheAction:)];
    self.navigationItem.rightBarButtonItems = @[forwardItem,backItem,clearItem];
    
    SLWebCacheManager *cacheManager = [SLWebCacheManager shareInstance];
    cacheManager.whiteListsHost = @[@"www.baidu.com", @"github.com", @"www.jianshu.com", @"juejin.im"];
    //选择缓存方案
    cacheManager.isUsingURLProtocol = YES;
    //开启缓存功能
    [cacheManager openCache];
    
    [self.view addSubview:self.webView];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SL_GithubUrl]];
    [self.webView loadRequest:request];
}

#pragma mark - Getter
- (WKWebView *)webView {
    if(_webView == nil){
        //创建网页配置
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight) configuration:config];
        _webView.navigationDelegate = self;
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return _webView;
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
///添加键值对监听
- (void)addKVO {
    //监听网页加载进度
    [self.webView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    //监听网页内容高度
    [self.webView.scrollView addObserver:self
                              forKeyPath:@"contentSize"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
}
///移除监听
- (void)removeKVO {
    //移除观察者
    [_webView removeObserver:self
                  forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [_webView.scrollView removeObserver:self
                             forKeyPath:NSStringFromSelector(@selector(contentSize))];
}
//kvo监听 必须实现此方法
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                      context:(void *)context{
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]
        && object == _webView) {
        //        NSLog(@"网页加载进度 = %f",_webView.estimatedProgress);
        self.progressView.progress = _webView.estimatedProgress;
        if (_webView.estimatedProgress >= 1.0f) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.progress = 0;
            });
        }
    }else if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]
              && object == _webView.scrollView && _webContentHeight != _webView.scrollView.contentSize.height) {
        _webContentHeight = _webView.scrollView.contentSize.height;
    }
}

#pragma mark - Events Handle
//返回上一步
- (void)goBackAction:(id)sender{
    [_webView goBack];
}
//前往下一步
- (void)goForwardAction:(id)sender{
    [_webView goForward];
}
//清理缓存
- (void)clearCacheAction:(id)sender {
    [[SLWebCacheManager shareInstance] clearCache];
}

#pragma mark - WKNavigationDelegate
// 根据客户端受到的服务器响应头以及response相关信息来决定是否可以跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
}

@end
