//
//  WKWebView+SLExtension.h
//  DarkMode
//
//  Created by wsl on 2020/5/30.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (SLExtension)

///注册http/https  以支持NSURLProtocol拦截WKWebView的网络请求
+ (void)sl_registerSchemeForSupportHttpProtocol;
///取消注册http/https
+ (void)sl_unregisterSchemeForSupportHttpProtocol;

@end

NS_ASSUME_NONNULL_END
