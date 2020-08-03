//
//  SLAPMURLProtocol.m
//  DarkMode
//
//  Created by wsl on 2020/8/3.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMURLProtocol.h"

@interface NSURLRequest (SLDataLength)
@end
@implementation NSURLRequest (SLDataLength)
- (NSUInteger)sl_getLineLength {
    NSString *lineStr = [NSString stringWithFormat:@"%@ %@ %@\n", self.HTTPMethod, self.URL.path, @"HTTP/1.1"];
    NSData *lineData = [lineStr dataUsingEncoding:NSUTF8StringEncoding];
    return lineData.length;
}
- (NSUInteger)sl_getHeadersLengthWithCookie {
    NSUInteger headersLength = 0;
    
    NSDictionary<NSString *, NSString *> *headerFields = self.allHTTPHeaderFields;
    NSDictionary<NSString *, NSString *> *cookiesHeader = [self sl_getCookies];
    
    // 添加 cookie 信息
    if (cookiesHeader.count) {
        NSMutableDictionary *headerFieldsWithCookies = [NSMutableDictionary dictionaryWithDictionary:headerFields];
        [headerFieldsWithCookies addEntriesFromDictionary:cookiesHeader];
        headerFields = [headerFieldsWithCookies copy];
    }
    //    NSLog(@"%@", headerFields);
    NSString *headerStr = @"";
    
    for (NSString *key in headerFields.allKeys) {
        headerStr = [headerStr stringByAppendingString:key];
        headerStr = [headerStr stringByAppendingString:@": "];
        if ([headerFields objectForKey:key]) {
            headerStr = [headerStr stringByAppendingString:headerFields[key]];
        }
        headerStr = [headerStr stringByAppendingString:@"\n"];
    }
    NSData *headerData = [headerStr dataUsingEncoding:NSUTF8StringEncoding];
    headersLength = headerData.length;
    return headersLength;
}
- (NSDictionary<NSString *, NSString *> *)sl_getCookies {
    NSDictionary<NSString *, NSString *> *cookiesHeader;
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:self.URL];
    if (cookies.count) {
        cookiesHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    }
    return cookiesHeader;
}
- (NSUInteger)sl_getBodyLength {
    NSDictionary<NSString *, NSString *> *headerFields = self.allHTTPHeaderFields;
    NSUInteger bodyLength = [self.HTTPBody length];
    if ([headerFields objectForKey:@"Content-Encoding"]) {
        NSData *bodyData;
        if (self.HTTPBody == nil) {
            uint8_t d[1024] = {0};
            NSInputStream *stream = self.HTTPBodyStream;
            NSMutableData *data = [[NSMutableData alloc] init];
            [stream open];
            while ([stream hasBytesAvailable]) {
                NSInteger len = [stream read:d maxLength:1024];
                if (len > 0 && stream.streamError == nil) {
                    [data appendBytes:(void *)d length:len];
                }
            }
            bodyData = [data copy];
            [stream close];
        } else {
            bodyData = self.HTTPBody;
        }
        bodyLength = bodyData.length;
    }
    return bodyLength;
}
@end


//为了避免 canInitWithRequest 和 canonicalRequestForRequest 出现死循环
static NSString * const SLHTTPHandledIdentifier = @"SLHTTPHandledIdentifier";
@interface SLAPMURLProtocol () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;   //会话
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSURLResponse *response;  //响应头
@property (nonatomic, strong) NSMutableData *data;  //返回的数据

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
    //拦截过的请求不再拦截
    if ([NSURLProtocol propertyForKey:SLHTTPHandledIdentifier inRequest:request] ) {
        return NO;
    }
    return YES;
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    //标示该request已经处理过了，防止无限循环
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES
                        forKey:SLHTTPHandledIdentifier
                     inRequest:mutableReqeust];
    return [mutableReqeust copy];
}
- (void)startLoading {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *sessionDelegateQueue = [[NSOperationQueue alloc] init];
    sessionDelegateQueue.maxConcurrentOperationCount = 1;
    sessionDelegateQueue.name = @"com.wsl2ls.APMURLProtocol.queue";
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:sessionDelegateQueue];
    _dataTask = [_session dataTaskWithRequest:self.request];
    [_dataTask resume];
}
- (void)stopLoading {
    [_dataTask cancel];
    _dataTask = nil;
    [_session invalidateAndCancel];
    _session = nil;
    
    //接收流量 不包括响应头NSURLResponse
    NSLog(@"接收流量大小：%.2fM",self.data.length/(1024.0*1024.0));
    
    NSUInteger sendLength = [self.request sl_getLineLength] + [self.request sl_getBodyLength] + [self.request sl_getHeadersLengthWithCookie];
    NSLog(@"发送流量大小：%ldB",sendLength);
}

#pragma mark - Getter
- (NSMutableData *)data {
    if (!_data) {
        _data = [NSMutableData data];
    }
    return _data;
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
    [self.data appendData:data];
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
}
//告诉代理，远程服务器请求了HTTP重定向
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if (response != nil){
        self.response = response;
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
}

@end
