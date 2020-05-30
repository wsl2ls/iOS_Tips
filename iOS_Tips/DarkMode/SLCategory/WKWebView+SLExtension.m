//
//  WKWebView+SLExtension.m
//  DarkMode
//
//  Created by wsl on 2020/5/30.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "WKWebView+SLExtension.h"

@implementation WKWebView (SLExtension)

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


@end
