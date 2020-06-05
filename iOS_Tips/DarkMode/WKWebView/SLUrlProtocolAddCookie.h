//
//  SLUrlProtocolAddCookie.h
//  DarkMode
//
//  Created by wsl on 2020/6/5.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///解决WKWebView上请求不会自动携带Cookie的问题：通过NSURLProtocol，拦截request，然后在请求头里添加Cookie的方式
@interface SLUrlProtocolAddCookie : NSURLProtocol

@end

NS_ASSUME_NONNULL_END
