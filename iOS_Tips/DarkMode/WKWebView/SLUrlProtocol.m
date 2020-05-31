//
//  SLUrlProtocol.m
//  DarkMode
//
//  Created by wsl on 2020/5/30.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLUrlProtocol.h"
#import "SLUrlCacheModel.h"

static NSString *SLUrlProtocolHandled = @"SLUrlProtocolHandled";

@interface SLUrlProtocol ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, readwrite, strong) NSMutableData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *otherInfoPath;

@end

@implementation SLUrlProtocol

//所有注册此Protocol的请求都会经过这个方法，根据request判断是否进行需要拦截
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    //判断该request是否已经处理过了，防止无限循环
    if ([NSURLProtocol propertyForKey:SLUrlProtocolHandled inRequest:request]) {
        return NO;
    }
    return YES;
}
//可选方法，这个方法用来统一处理请求的request对象，可以修改头信息，或者重定向。没有特殊需要，则直接return request。
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    //    NSURLRequest *re = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:SL_WeiBo]];
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
    
    SLUrlCacheModel *sModel = [SLUrlCacheModel shareInstance];
    
    self.filePath = [sModel filePathFromRequest:self.request isInfo:NO];
    self.otherInfoPath = [sModel filePathFromRequest:self.request isInfo:YES];
    
    NSDate *date = [NSDate date];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL expire = false;
    
    if ([fm fileExistsAtPath:self.filePath]) {
        //有缓存文件的情况
        NSDictionary *otherInfo = [NSDictionary dictionaryWithContentsOfFile:self.otherInfoPath];
        NSInteger createTime = [[otherInfo objectForKey:@"time"] integerValue];
        if (sModel.cacheTime > 0) {
            if (createTime + sModel.cacheTime < [date timeIntervalSince1970]) {
                expire = true;
            }
        }
        if (expire == false) {
            //从缓存里读取数据
            NSData *data = [NSData dataWithContentsOfFile:self.filePath];
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:[otherInfo objectForKey:@"MIMEType"] expectedContentLength:data.length textEncodingName:[otherInfo objectForKey:@"textEncodingName"]];
            
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [self.client URLProtocol:self didLoadData:data];
            [self.client URLProtocolDidFinishLoading:self];
        } else {
            //cache失效了
            [fm removeItemAtPath:self.filePath error:nil];      //清除缓存data
            [fm removeItemAtPath:self.otherInfoPath error:nil]; //清除缓存其它信息
        }
    } else {
        expire = true;
    }
    
    if (expire) {
        NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
        //标示该request已经处理过了，防止无限循环
        [NSURLProtocol setProperty:@(YES) forKey:SLUrlProtocolHandled inRequest:mutableReqeust];
        //使用NSURLSession继续把request发送出去
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:mainQueue];
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:self.request];
        [task resume];
    }
    
}
//停止请求加载
- (void)stopLoading {
    [self.session invalidateAndCancel];
    self.session = nil;
}

#pragma mark - Helper
- (void)clear {
    [self setData:nil];
    [self setSession:nil];
    [self setResponse:nil];
}
- (void)appendData:(NSData *)newData {
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    } else {
        [[self data] appendData:newData];
    }
}

#pragma mark - NSURLSessionDelegate
//接收到返回信息时(还未开始下载), 执行的代理方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
    self.response = response;
}
//接收到服务器返回的数据 调用多次，数据是分批返回的
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    // 打印返回的数据
    //    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //    if (dataStr) {
    //        NSLog(@"收到数据: %@", dataStr);
    //    }
    [self appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}
//请求结束或者是失败的时候调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
        //开始缓存
        NSDate *date = [NSDate date];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f",[date timeIntervalSince1970]],@"time",self.response.MIMEType,@"MIMEType",self.response.textEncodingName,@"textEncodingName", nil];
        [dic writeToFile:self.otherInfoPath atomically:YES];
        [self.data writeToFile:self.filePath atomically:YES];
    }
    
    [self clear];
}

@end
