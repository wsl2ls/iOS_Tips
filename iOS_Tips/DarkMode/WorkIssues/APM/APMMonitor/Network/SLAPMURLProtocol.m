//
//  SLAPMURLProtocol.m
//  DarkMode
//
//  Created by wsl on 2020/8/3.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMURLProtocol.h"

//为了避免 canInitWithRequest 和 canonicalRequestForRequest 出现死循环
static NSString * const SLHTTPHandledIdentifier = @"SLHTTPHandledIdentifier";

@interface SLAPMURLProtocol () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSOperationQueue     *sessionDelegateQueue;
@property (nonatomic, strong) NSURLResponse        *response;
@property (nonatomic, strong) NSMutableData        *data;
@property (nonatomic, strong) NSDate               *startDate;
//@property (nonatomic, strong) HJHTTPModel          *httpModel;

@end

@implementation SLAPMURLProtocol

#pragma mark - Public
///开始监听网络
+ (void)startMonitorNetwork {
    [NSURLProtocol registerClass:[SLAPMURLProtocol class]];
}
///结束监听网络
+ (void)stopMonitorNetwork {
    [NSURLProtocol unregisterClass:[SLAPMURLProtocol class]];
}

#pragma mark - Override
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    if ([NSURLProtocol propertyForKey:SLHTTPHandledIdentifier inRequest:request] ) {
        return NO;
    }
    return YES;
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}
- (void)startLoading {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //标示该request已经处理过了，防止无限循环
    [NSURLProtocol setProperty:@(YES) forKey:SLHTTPHandledIdentifier inRequest:mutableReqeust];
    
    self.startDate = [NSDate date];
    self.data = [NSMutableData data];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.sessionDelegateQueue = [[NSOperationQueue alloc] init];
    self.sessionDelegateQueue.maxConcurrentOperationCount = 1;
    self.sessionDelegateQueue.name                        = @"com.wsl2ls.APMURLProtocol.queue";
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.sessionDelegateQueue];
    self.dataTask = [session dataTaskWithRequest:self.request];
    [self.dataTask resume];
    
    //    httpModel                                             = [[NEHTTPModel alloc] init];
    //    httpModel.request                                     = self.request;
    //    httpModel.startDateString                             = [self stringWithDate:[NSDate date]];
    //
    //    NSTimeInterval myID                                   = [[NSDate date] timeIntervalSince1970];
    //    double randomNum                                      = ((double)(arc4random() % 100))/10000;
    //    httpModel.myID                                        = myID+randomNum;
}
- (void)stopLoading {
    [self.dataTask cancel];
    self.dataTask = nil;
    //    httpModel.response      = (NSHTTPURLResponse *)self.response;
    //    httpModel.endDateString = [self stringWithDate:[NSDate date]];
    NSString *mimeType = self.response.MIMEType;
    
    // 解析 response，流量统计等
}

#pragma mark - NSURLSessionDataDelegate
//接收到返回的响应信息时(还未开始下载), 执行的代理方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
    self.response = response;
}
//接收到服务器返回的数据 调用多次，数据是分批返回的
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

#pragma mark - NSURLSessionTaskDelegate
//请求结束或者是失败的时候调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
    } else if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
    self.dataTask = nil;
}
//告诉代理，远程服务器请求了HTTP重定向
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if (response != nil){
        self.response = response;
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
}

@end
