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
#import "SLUrlProtocolAddCookie.h"

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
    [WKWebView sl_unregisterSchemeForSupportHttpProtocol];
    [NSURLProtocol registerClass:[NSURLProtocol class]];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"上一步" style:UIBarButtonItemStyleDone target:self action:@selector(goBackAction:)];
    UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleDone target:self action:@selector(goForwardAction:)];
    self.navigationItem.rightBarButtonItems = @[forwardItem,backItem];
    
    //UA 设置在WKWebView初始化之前
    [self aboutUserAgent];
    //设置自定义Cookie在WKWebView初始化之前
    [self aboutCookie];
    
    [self.view addSubview:self.webView];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
    //设置上一次的请求时间
    [request setValue:[SLMethod userDefaultsObjectForKey:@"localLastModified"] forHTTPHeaderField:@"If-Modified-Since"];
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
- (NSString *)urlString {
    if (!_urlString) {
        _urlString = @"https://www.jianshu.com/p/5cf0d241ae12";
    }
    return _urlString;
}

#pragma mark -  Look Here
///关于WKWebView的那些坑：  https://mp.weixin.qq.com/s/rhYKLIbXOsUJC_n6dt9UfA?
- (void)aboutJsToOC {
    ///关于JS和OC的交互以及API基本的使用可以看我之前的总结：  https://github.com/wsl2ls/WKWebView
}
///关于UserAgent
- (void)aboutUserAgent {
    //设置UA  在WKWebView初始化之前设置，才能实时生效
    [WKWebView sl_setCustomUserAgentWithType:SLSetUATypeAppend UAString:@"wsl2ls"];
}
///关于Cookie   https://www.jianshu.com/p/cd0d819b9851
- (void)aboutCookie {
    ///添加自定义Cookie到WebView的Cookie管理器
    [WKWebView sl_setCustomCookieWithName:@" 且行且珍惜_iOS " value:@" wsl❤ls " domain:@".jianshu.com" path:@"/" expiresDate:[NSDate dateWithTimeIntervalSince1970:1591440726]];
    
    //解决WKWebView上请求不会自动携带Cookie的问题
    /*
     方案1、①. [webView loadRequest]前，在request header中设置Cookie, 手动设置cookies，可以解决首个请求Cookie带不上的问题；
     NSArray *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
     NSDictionary *requestHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieJar];
     request.allHTTPHeaderFields = requestHeaderFields;
     ②. 通过注入JS方法，document.cookie设置Cookie 解决后续页面(同域)Ajax、iframe 请求的 Cookie 问题；
     WKUserContentController* userContentController = [WKUserContentController new];
     WKUserScript * cookieScript = [[WKUserScript alloc] initWithSource: @"document.cookie = ' 且行且珍惜_iOS = wsl❤ls ';" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
     [userContentController addUserScript:cookieScript];
     config.userContentController = userContentController;
     方案2、通过NSURLProtocol，拦截request，然后在请求头里添加Cookie的方式
     */
    
    //这里采用方案2
    //用完记得取消注册sl_unregisterSchemeForSupportHttpProtocol
    [WKWebView sl_registerSchemeForSupportHttpProtocol];
    [NSURLProtocol registerClass:[SLUrlProtocolAddCookie class]];
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
    //请求头信息
    NSDictionary *allHTTPHeaderFields =  [navigationAction.request allHTTPHeaderFields];
    NSLog(@" UserAgent: %@",allHTTPHeaderFields[@"User-Agent"]);
    decisionHandler(WKNavigationActionPolicyAllow);
}
// 根据客户端受到的服务器响应头以及response相关信息来决定是否可以跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]] && [navigationResponse.response.URL.absoluteString isEqualToString:self.urlString]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)navigationResponse.response;
        if (httpResponse.statusCode == 304) {
            //自上次请求后，文件还没有修改变化
            //可以加载本地缓存
        }else if (httpResponse.statusCode == 200){
            [SLMethod userDefaultsSetObject:httpResponse.allHeaderFields[@"Last-Modified"] forKey:@"localLastModified"];
            NSLog(@" httpResponse：%@",httpResponse);
        }
    }
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
}
//进程被终止时调用
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    //当 WKWebView 总体内存占用过大，页面即将白屏的时候，系统会调用此7u776回调函数，我们在该函数里执行[webView reload](这个时候 webView.URL 取值尚不为 nil）解决白屏问题。在一些高内存消耗的页面可能会频繁刷新当前页面，H5侧也要做相应的适配操作。
    [webView reload];
}
@end

