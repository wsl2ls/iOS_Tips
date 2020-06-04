//
//  SLWebViewController.m
//  DarkMode
//
//  Created by wsl on 2020/5/21.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebViewController.h"
#import <WebKit/WebKit.h>
#import "WKWebView+SLExtension.h"

///关于WKWebView的其他更多使用可以看我之前的总结：  https://github.com/wsl2ls/WKWebView
@interface SLWebViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView * webView;
///网页加载进度视图
@property (nonatomic, strong) UIProgressView * progressView;
/// WKWebView 内容的高度
@property (nonatomic, assign) CGFloat webContentHeight;

@end

@implementation SLWebViewController

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
    NSLog(@"%@释放了",NSStringFromClass(self.class));
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"上一步" style:UIBarButtonItemStyleDone target:self action:@selector(goBackAction:)];
    UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleDone target:self action:@selector(goForwardAction:)];
    self.navigationItem.rightBarButtonItems = @[forwardItem,backItem];
    [self.view addSubview:self.webView];
    
    [self aboutUserAgent];
    [self aboutCookie];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jianshu.com/p/5cf0d241ae12"]];
    [_webView loadRequest:request];
    
}

#pragma mark - Getter
- (WKWebView *)webView {
    if(_webView == nil){
        //创建网页配置
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight) configuration:config];
        _webView.navigationDelegate = self;
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

#pragma mark -  Help Methods
///关于UserAgent
- (void)aboutUserAgent {
    [WKWebView sl_setCustomUserAgentWithType:SLSetUATypeAppend UAString:@"wsl2ls"];
    NSString *ua = [WKWebView sl_getUserAgent];
    NSLog(@" UserAgent: %@",ua);
}
///关于Cookie
- (void)aboutCookie {
    //设置自定义Cookie
    [self.webView sl_setCookieWithName:@"iOS_Tips" value:@"wsl" domain:@"www.jianshu.com" path:@"/" expiresDate:[NSDate dateWithTimeIntervalSince1970:1593863893]];
    NSSet *set = [self.webView sl_getAllCustomCookiesName];
    
    WKWebsiteDataStore *store = [WKWebsiteDataStore defaultDataStore];
    [store.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * cookies) {
        [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@" name:%@; value:%@ domain:%@ ", obj.name, obj.value, obj.domain);
            
        }];
    }];
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


#pragma mark - WKNavigationDelegate
// 根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[navigationAction.request allHTTPHeaderFields] forURL:navigationAction.request.URL];
    // 读取请求头中的cookie
    for (NSHTTPCookie *cookie in cookies) {
        NSLog(@" cookie:%@", cookie);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
