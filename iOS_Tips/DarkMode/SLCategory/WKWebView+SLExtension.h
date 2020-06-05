//
//  WKWebView+SLExtension.h
//  DarkMode
//
//  Created by wsl on 2020/5/30.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

///设置UserAgent的方式
typedef NS_ENUM (NSInteger, SLSetUAType){
    ///替换默认UA
    SLSetUATypeReplace,
    ///拼接默认UA
    SLSetUATypeAppend,
};

@interface WKWebView (SLExtension)

///注册http/https  以支持NSURLProtocol拦截WKWebView的网络请求
+ (void)sl_registerSchemeForSupportHttpProtocol;
///取消注册http/https
+ (void)sl_unregisterSchemeForSupportHttpProtocol;

/// 获取UA
+ (NSString *)sl_getUserAgent;
/// 设置UA  在WKWebView初始化之前设置，才能实时生效
+ (void)sl_setCustomUserAgentWithType:(SLSetUAType)type UAString:(NSString *)customUserAgent;

///设置自定义Cookie
+ (void)sl_setCustomCookieWithName:(NSString *)name
                    value:(NSString *)value
                   domain:(NSString *)domain
                     path:(NSString *)path
                 expiresDate:(NSDate *)expiresDate;
///查询获取所有Cookies
+ (void)sl_getAllCookies;

@end

NS_ASSUME_NONNULL_END
