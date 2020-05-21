//
//  SLWebViewController.m
//  DarkMode
//
//  Created by wsl on 2020/5/21.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebViewController.h"
#import <WebKit/WebKit.h>

@interface SLWebViewController ()

@property (nonatomic, strong) WKWebView * webView;

@end

@implementation SLWebViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.webView];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"上一步" style:UIBarButtonItemStyleDone target:self action:@selector(goBackAction:)];
    UIBarButtonItem *forwardItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleDone target:self action:@selector(goForwardAction:)];
    self.navigationItem.rightBarButtonItems = @[forwardItem,backItem];
    
}
- (void)dealloc {
    NSLog(@"%@释放了",NSStringFromClass(self.class));
}

#pragma mark - Getter
- (WKWebView *)webView {
    if(_webView == nil){
        
        //创建网页配置
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight) configuration:config];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com/wsl2ls"]];
        [_webView loadRequest:request];
    }
    return _webView;
}

#pragma mark - Help Methods

#pragma mark - Events Handle
//返回上一步
- (void)goBackAction:(id)sender{
    [_webView goBack];
}
//前往下一步
- (void)goForwardAction:(id)sender{
    [_webView goForward];
}

@end
