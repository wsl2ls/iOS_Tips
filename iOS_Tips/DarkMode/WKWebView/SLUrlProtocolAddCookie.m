//
//  SLUrlProtocolAddCookie.m
//  DarkMode
//
//  Created by wsl on 2020/6/5.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLUrlProtocolAddCookie.h"

@interface SLUrlProtocolAddCookie () <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *session;   //会话
@end

@implementation SLUrlProtocolAddCookie

//所有注册此Protocol的请求都会经过这个方法，根据request判断是否进行需要拦截
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    //只允许GET方法通过，因为post请求body数据被清空
    if ([request.HTTPMethod compare:@"GET"] != NSOrderedSame) {
        return NO;
    }
    //判断该request是否已经处理过了，防止无限循环
    if ([NSURLProtocol propertyForKey:@"SLUrlProtocolHandled" inRequest:request]) {
        return NO;
    }
    return YES;
}
//可选方法，这个方法用来统一处理请求的request对象，可以修改头信息，或者重定向。没有特殊需要，则直接return request。
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}
//主要判断两个request是否相同，如果相同的话可以使用缓存数据，通常只需要调用父类的实现
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}
//初始化protocol实例，所有来源的请求都以NSURLRequest形式接收
- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client {
    return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}
/**
 开始请求：
 在这里需要我们手动的把请求发出去，可以使用原生的NSURLSessionDataTask，也可以使用的第三方网络库
 同时设置"NSURLSessionDataDelegate"协议，接收Server端的响应
 */
- (void)startLoading {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //标示该request已经处理过了，防止无限循环
    [NSURLProtocol setProperty:@(YES) forKey:@"SLUrlProtocolHandled" inRequest:mutableReqeust];
    
    NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
    NSDictionary *requestHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    mutableReqeust.allHTTPHeaderFields = requestHeaderFields;
    
    //使用NSURLSession继续把request发送出去
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:mainQueue];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:mutableReqeust];
    [task resume];
    
}
//停止请求加载
- (void)stopLoading {
    [self.session invalidateAndCancel];
    self.session = nil;
}
#pragma mark - NSURLSessionDelegate
//接收到返回的响应信息时(还未开始下载), 执行的代理方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
    //请求头信息
    NSDictionary *allHTTPHeaderFields =  [dataTask.currentRequest allHTTPHeaderFields];
    NSLog(@" Cookie: %@",allHTTPHeaderFields[@"Cookie"]);
}
//接收到服务器返回的数据 调用多次，数据是分批返回的
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}
//请求结束或者是失败的时候调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

@end
