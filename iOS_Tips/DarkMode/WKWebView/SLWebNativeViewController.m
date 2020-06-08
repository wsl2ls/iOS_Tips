//
//  SLWebNativeViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/8.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebNativeViewController.h"
#import <WebKit/WebKit.h>
#import <YYImage.h>
#import <YYWebImage.h>
#import "SLAvPlayer.h"

/*
 
 
 
 
 */
@interface SLWebNativeViewController ()<WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView * webView;
///网页加载进度视图
@property (nonatomic, strong) UIProgressView * progressView;
/// WKWebView 内容的高度
@property (nonatomic, assign) CGFloat webContentHeight;
/// 原生组件所需的HTML中元素的数据
@property (nonatomic, strong) NSMutableArray *dataSource;
///视频播放
@property (nonatomic, strong) SLAvPlayer *avPlayer;
@end

@implementation SLWebNativeViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self getData];
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
    self.navigationItem.title = @"Html非文本元素替换为native组件展示";
    [self.view addSubview:self.webView];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WebNative.html" ofType:nil];
    NSString *htmlString = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [_webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

#pragma mark - Data
/// 获取原生组件所需的HTML中元素的数据
- (void)getData {
    NSData *contentData = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle mainBundle] pathForResource:@"WebNativeJson" ofType:@"txt"]];
    NSDictionary * dataDict = [NSJSONSerialization JSONObjectWithData:contentData options:kNilOptions error:nil];
    [self.dataSource addObjectsFromArray:dataDict[@"dataList"]];
}

#pragma mark - Getter
- (WKWebView *)webView {
    if(_webView == nil){
        //创建网页配置
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight) configuration:config];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
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
- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}
- (SLAvPlayer *)avPlayer {
    if (!_avPlayer) {
        _avPlayer = [[SLAvPlayer alloc] init];
    }
    return _avPlayer;
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
              && object == _webView.scrollView) {
        if (_webContentHeight == _webView.scrollView.contentSize.height) {
        }else {
            _webContentHeight = _webView.scrollView.contentSize.height;
        }
    }
}

#pragma mark - Events Handle
- (void)playVideoAction:(UIButton *)btn {
    self.avPlayer.monitor = btn.superview;
    [self.avPlayer play];
    [btn removeFromSuperview];
}

#pragma mark - WKNavigationDelegate
// 根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}
// 根据客户端收到的服务器响应头以及response相关信息来决定是否可以继续响应
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //根据服务器下发的标签相关的数据，用原生组件展示
    for (NSDictionary *dataDict in self.dataSource) {
        NSString *jsString = [NSString stringWithFormat:@"getElementFrame('%@')",dataDict[@"tagID"]];
        [_webView evaluateJavaScript:jsString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
            //获取标签位置坐标
            NSDictionary *frameDict = (NSDictionary *)data;
            CGRect frame = CGRectMake(
                                      [frameDict[@"x"] floatValue], [frameDict[@"y"] floatValue], [frameDict[@"width"] floatValue], [frameDict[@"height"] floatValue]);
            if ([dataDict[@"type"] isEqualToString:@"image"]) {
                //图片
                YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] init];
                imageView.frame = frame;
                [imageView yy_setImageWithURL:[NSURL URLWithString:dataDict[@"imgUrl"] ] placeholder:nil];
                [self.webView.scrollView addSubview:imageView];
            }else if ([dataDict[@"type"] isEqualToString:@"video"]) {
                //视频
                YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] init];
                imageView.frame = frame;
                imageView.backgroundColor = [UIColor orangeColor];
                [imageView yy_setImageWithURL:[NSURL URLWithString:dataDict[@"imgUrl"] ] placeholder:nil];
                [self.webView.scrollView addSubview:imageView];
                UIButton *playBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
                playBtn.center = CGPointMake(frame.size.width/2.0, frame.size.height/2.0);
                [playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
                [playBtn addTarget:self action:@selector(playVideoAction:) forControlEvents:UIControlEventTouchUpInside];
                imageView.userInteractionEnabled = YES;
                [imageView addSubview:playBtn];
                self.avPlayer.url = [NSURL URLWithString:dataDict[@"videoUrl"]];
            }else if ([dataDict[@"type"] isEqualToString:@"audio"]) {
                //音频
                
            }
            //            NSLog(@" %@",data)
        }];
    }
    
}
//进程被终止时调用
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    
}

#pragma mark - WKUIDelegate
/**
 *  web界面中有弹出警告框时调用
 *
 *  @param webView           实现该代理的webview
 *  @param message           警告框中的内容
 *  @param completionHandler 警告框消失调用
 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"HTML的弹出框" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
