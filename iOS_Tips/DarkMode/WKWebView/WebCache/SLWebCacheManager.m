//
//  SLWebCacheManager.m
//  DarkMode
//
//  Created by wsl on 2020/5/31.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebCacheManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "SLUrlCache.h"
#import "SLUrlProtocol.h"
#import "WKWebView+SLExtension.h"

@implementation SLWebCacheManager

#pragma mark - Public
+ (SLWebCacheManager *)shareInstance {
    static SLWebCacheManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SLWebCacheManager alloc] init];
    });
    return instance;
}
///启用缓存功能
- (void)openCache {
    //注册协议类, 然后URL加载系统就会在请求发出时使用我们创建的协议对象对该请求进行拦截处理，不需要拦截的时候，要进行注销unregisterClass
    [WKWebView sl_registerSchemeForSupportHttpProtocol];
    if (self.isUsingURLProtocol) {
        [NSURLProtocol registerClass:[SLUrlProtocol class]];
    }else {
        SLUrlCache * urlCache = [[SLUrlCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:0];
        [NSURLCache setSharedURLCache:urlCache];
    }
}
///关闭缓存功能
- (void)closeCache {
    [WKWebView sl_unregisterSchemeForSupportHttpProtocol];
    if (self.isUsingURLProtocol) {
    }else {
        NSURLCache* urlCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:0];
        [NSURLCache setSharedURLCache:urlCache];
    }
}
///加载本地缓存数据
- (NSCachedURLResponse *)localCacheResponeWithRequest:(NSURLRequest *)request {
    NSString *filePath = [self filePathFromRequest:request isInfo:NO];
    NSString *otherInfoPath = [self filePathFromRequest:request isInfo:YES];
    NSDate *date = [NSDate date];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        //有缓存
        //缓存是否过期
        BOOL expire = false;
        NSDictionary *otherInfo = [NSDictionary dictionaryWithContentsOfFile:otherInfoPath];
        if (self.cacheTime > 0) {
            NSInteger createTime = [[otherInfo objectForKey:@"time"] integerValue];
            if (createTime + self.cacheTime < [date timeIntervalSince1970]) {
                expire = true;
            }
        }
        if (expire == false) {
            //从缓存里读取数据
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:[otherInfo objectForKey:@"MIMEType"] expectedContentLength:data.length textEncodingName:[otherInfo objectForKey:@"textEncodingName"]];
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
            return cachedResponse;
        } else {
            //cache失效了
            [fm removeItemAtPath:filePath error:nil];      //清除缓存data
            [fm removeItemAtPath:otherInfoPath error:nil]; //清除缓存其它信息
            return nil;
        }
    }
    return nil;
}
///请求网络数据
- (NSCachedURLResponse *)requestNetworkData:(NSURLRequest *)request{
    //从网络读取
    __block NSCachedURLResponse *cachedResponse = nil;
    NSString *filePath = [self filePathFromRequest:request isInfo:NO];
    NSString *otherInfoPath = [self filePathFromRequest:request isInfo:YES];
    NSDate *date = [NSDate date];
    id isExist = [self.responseDic objectForKey:request.URL.absoluteString];
    if (isExist == nil) {
        [self.responseDic setValue:[NSNumber numberWithBool:TRUE] forKey:request.URL.absoluteString];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                cachedResponse = nil;
            } else {
                NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f",[date timeIntervalSince1970]],@"time",response.MIMEType,@"MIMEType",response.textEncodingName,@"textEncodingName", nil];
                BOOL resultO = [dic writeToFile:otherInfoPath atomically:YES];
                BOOL result = [data writeToFile:filePath atomically:YES];
                if (resultO == NO || result == NO) {
                } else {
                }
                cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
            }
        }];
        [task resume];
        return cachedResponse;
    }
    return nil;
}
/// 缓存文件/信息路径
- (NSString *)filePathFromRequest:(NSURLRequest *)request isInfo:(BOOL)info {
    NSString *url = request.URL.absoluteString;
    NSString *fileName = [self cacheRequestFileName:url];
    NSString *otherInfoFileName = [self cacheRequestOtherInfoFileName:url];
    NSString *filePath = [self cacheFilePath:fileName];
    NSString *fileInfoPath = [self cacheFilePath:otherInfoFileName];
    if (info) {
        return fileInfoPath;
    }
    return filePath;
}

#pragma mark - Cache Path
- (NSString *)cacheRequestFileName:(NSString *)requestUrl {
    return [SLWebCacheManager md5Hash:[NSString stringWithFormat:@"%@",requestUrl]];
}
- (NSString *)cacheRequestOtherInfoFileName:(NSString *)requestUrl {
    return [SLWebCacheManager md5Hash:[NSString stringWithFormat:@"%@-otherInfo",requestUrl]];
}
- (NSString *)cacheFilePath:(NSString *)file {
    NSString *path = [NSString stringWithFormat:@"%@/%@",self.diskPath,self.cacheFolder];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        //
    } else {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *subDirPath = [NSString stringWithFormat:@"%@/%@/%@",self.diskPath,self.cacheFolder,self.subDirectory];
    if ([fm fileExistsAtPath:subDirPath isDirectory:&isDir] && isDir) {
        //
    } else {
        [fm createDirectoryAtPath:subDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *cFilePath = [NSString stringWithFormat:@"%@/%@",subDirPath,file];
    //    NSLog(@"%@",cFilePath);
    return cFilePath;
}

#pragma mark - Cache Manage
//移除缓存文件
- (void)removeCacheFileWithRequest:(NSURLRequest *)request {
    NSString *filePath = [self filePathFromRequest:request isInfo:NO];
    NSString *otherInfoFilePath = [self filePathFromRequest:request isInfo:YES];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:filePath error:nil];
    [fm removeItemAtPath:otherInfoFilePath error:nil];
}
/// 检测缓存容量，超出限制就清除
- (void)checkCapacity {
    if ([self folderSize] > self.diskCapacity) {
        [self clearCache];
    }
}
///强制清除缓存
- (void)clearCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self deleteCacheFolder];
    });
}
- (void)deleteCacheFolder {
    [[NSFileManager defaultManager] removeItemAtPath:[self cacheFolderPath] error:nil];
}
///缓存文件大小
- (NSUInteger)folderSize {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:[self cacheFolderPath] error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self cacheFolderPath] stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDic fileSize];
    }
    return (NSUInteger)fileSize;
}

#pragma mark - Function Helper
+ (NSString *)md5Hash:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    NSString *md5Result = [NSString stringWithFormat:
                           @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    return md5Result;
}
- (NSString *)cacheFolderPath {
    return [NSString stringWithFormat:@"%@/%@/%@",self.diskPath,self.cacheFolder,self.subDirectory];
}

#pragma mark - Getter
- (NSString *)diskPath {
    if (!_diskPath) {
        _diskPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    }
    return _diskPath;
}
- (NSMutableDictionary *)responseDic {
    if (!_responseDic) {
        _responseDic = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return _responseDic;
}
- (NSString *)cacheFolder {
    if (!_cacheFolder) {
        _cacheFolder = @"Url";
    }
    return _cacheFolder;
}
- (NSString *)subDirectory {
    if (!_subDirectory) {
        _subDirectory = @"UrlCacheDownload";
    }
    return _subDirectory;
}
- (NSUInteger)memoryCapacity {
    if (!_memoryCapacity) {
        _memoryCapacity = 20 * 1024 * 1024;
    }
    return _memoryCapacity;
}
- (NSUInteger)diskCapacity {
    if (!_diskCapacity) {
        _diskCapacity = 50 * 1024 * 1024;
    }
    return _diskCapacity;
}
- (NSUInteger)cacheTime {
    if (!_cacheTime) {
        _cacheTime = 0;
    }
    return _cacheTime;
}
- (NSMutableDictionary *)whiteListsHost {
    if (!_whiteListsHost) {
        _whiteListsHost = [NSMutableDictionary dictionary];
    }
    return _whiteListsHost;
}
- (NSMutableDictionary *)whiteListsRequestUrl {
    if (!_whiteListsRequestUrl) {
        _whiteListsRequestUrl = [NSMutableDictionary dictionary];
    }
    return _whiteListsRequestUrl;
}
- (NSString *)whiteUserAgent {
    if (!_whiteUserAgent) {
        _whiteUserAgent = @"";
    }
    return _whiteUserAgent;
}
- (NSString *)replaceUrl {
    if (!_replaceUrl) {
        _replaceUrl = @"";
    }
    return _replaceUrl;
}

@end
