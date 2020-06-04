//
//  WKWebView+SLExtension.m
//  DarkMode
//
//  Created by wsl on 2020/5/30.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "WKWebView+SLExtension.h"
#import <objc/runtime.h>

///该部分代码来源： https://github.com/dequan1331/WKWebViewExtension
@interface WKWebView()
@property(nonatomic,strong,readwrite)NSMutableDictionary<NSString *, NSString *> *HPKCookieDic;
@end

@implementation WKWebView (SLExtension)

#pragma mark - NSURLProtocol
///注册http/https  以支持NSURLProtocol对WKWebView的网络请求
+ (void)sl_registerSchemeForSupportHttpProtocol{
    Class cls = NSClassFromString([NSString stringWithFormat:@"%@%@%@%@%@", @"W", @"K", @"Browsing", @"Context", @"Controller"]);
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@%@", @"register", @"SchemeFor", @"Custom", @"Protocol", @":"]);
    if ([cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        [cls performSelector:sel withObject:@"http"];
        [cls performSelector:sel withObject:@"https"];
#pragma clang diagnostic pop
    }
}
///取消注册http/https
+ (void)sl_unregisterSchemeForSupportHttpProtocol{
    Class cls = NSClassFromString([NSString stringWithFormat:@"%@%@%@%@%@", @"W", @"K", @"Browsing", @"Context", @"Controller"]);
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@%@", @"unregister", @"SchemeFor", @"Custom", @"Protocol", @":"]);
    if ([cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        [cls performSelector:sel withObject:@"http"];
        [cls performSelector:sel withObject:@"https"];
#pragma clang diagnostic pop
    }
}

#pragma mark - UserAgent
/// 获取UA
+ (NSString *)sl_getUserAgent {
    //获取UserAgent 这个是异步的
    //    [self evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
    //        NSString *userAgent = response;
    //    }];
    UIWebView *webView = [[UIWebView alloc] init];
    NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    return userAgent;
}
/// 设置UA
+ (void)sl_setCustomUserAgentWithType:(SLSetUAType)type UAString:(NSString *)customUserAgent {
    if (!customUserAgent || customUserAgent.length <= 0) {
        return;
    }
    // 这种设置方式仅对当前webView对象有效
    //  self.customUserAgent = customUserAgent;
    if (type == SLSetUATypeReplace) {
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:customUserAgent, @"UserAgent", nil];
        //iOS8.0之前 是通过这种方式设置的，设置之后是全局
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    }else {
        NSString *originalUserAgent = [WKWebView sl_getUserAgent];
        NSString *appUserAgent = [NSString stringWithFormat:@"%@-%@", originalUserAgent, customUserAgent];
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:appUserAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    }
}

#pragma mark - Cookie
- (void)setHPKCookieDic:(NSMutableDictionary *)HPKCookieDic{
    objc_setAssociatedObject(self, @"HPKCookieDic", HPKCookieDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableDictionary *)HPKCookieDic{
    NSMutableDictionary *HPKCookieDic = objc_getAssociatedObject(self, @"HPKCookieDic");
    if (!HPKCookieDic) {
        HPKCookieDic = @{}.mutableCopy;
    }
    return HPKCookieDic;
}
///设置自定义Cookie
- (void)sl_setCookieWithName:(NSString *)name
                    value:(NSString *)value
                   domain:(NSString *)domain
                     path:(NSString *)path
              expiresDate:(NSDate *)expiresDate{
    if(!name || name.length <=0){
        return;
    }
    
    NSMutableString *cookieScript = [[NSMutableString alloc] init];
    [cookieScript appendFormat:@"document.cookie='%@=%@;",name,value];
    if(domain || domain.length > 0){
        [cookieScript appendFormat:@"domain=%@;",domain];
    }
    if(path || path.length > 0){
        [cookieScript appendFormat:@"path=%@;",path];
    }
    
    [[self HPKCookieDic] setValue:cookieScript.copy forKey:name];
    
    if([expiresDate timeIntervalSince1970] != 0){
        [cookieScript appendFormat:@"expires='+(new Date(%@).toUTCString());", @(([expiresDate timeIntervalSince1970]) * 1000)];
    }
    [cookieScript appendFormat:@"\n"];
    
    [self evaluateJavaScript:cookieScript.copy completionHandler:^(id _Nullable response, NSError * _Nullable error) {
    }];
}
///删除Cookie
- (void)sl_deleteCookiesWithName:(NSString *)name{
    if(!name || name.length <=0){
        return;
    }
    
    if (![[[self HPKCookieDic] allKeys] containsObject:name]) {
        return;
    }
    
    NSMutableString *cookieScript = [[NSMutableString alloc] init];
    
    [cookieScript appendString:[[self HPKCookieDic] objectForKey:name]];
    [cookieScript appendFormat:@"expires='+(new Date(%@).toUTCString());\n",@(0)];
    
    [[self HPKCookieDic] removeObjectForKey:name];
    [self evaluateJavaScript:cookieScript.copy completionHandler:^(id _Nullable response, NSError * _Nullable error) {
    }];
}
///获取所有的自定义Cookie
- (NSSet<NSString *> *)sl_getAllCustomCookiesName{
    return [[self HPKCookieDic] allKeys].copy;
}
///移除自定义的所有Cookies
- (void)sl_deleteAllCustomCookies{
    for (NSString *cookieName in [[self HPKCookieDic] allKeys]) {
        [self sl_deleteCookiesWithName:cookieName];
    }
}


@end
