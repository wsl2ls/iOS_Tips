//
//  SLWebCacheManager.h
//  DarkMode
//
//  Created by wsl on 2020/5/31.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///缓存管理者
@interface SLWebCacheManager : NSObject

/// 缓存方案：SLUrlCache 和 SLUrlProtocol，默认NO 即使用SLUrlCache进行缓存
@property (nonatomic, assign) BOOL isUsingURLProtocol;
/// 内存缓存容量 默认20M   注意0表示无限制
@property (nonatomic, assign) NSUInteger memoryCapacity;
/// 磁盘缓存容量 默认50M
@property (nonatomic, assign) NSUInteger diskCapacity;
/// 缓存的有效时长(s)  默认 24 * 60 * 60 一天 ，如果为0，表示永久有效，除非手动强制删除，否则有缓存之后，只从缓存读取
@property (nonatomic, assign) NSUInteger cacheTime;
/// 磁盘路径 默认 NSCachesDirectory
@property (nonatomic, copy) NSString *diskPath;
/// 缓存文件夹 默认 @"Url"
@property (nonatomic, copy) NSString *cacheFolder;
/// 子路径 默认 @"UrlCacheDownload"
@property (nonatomic, copy) NSString *subDirectory;

/// 以下3类都可以作为过滤不必要请求缓存的接口：若都为空，表示不设置过滤，所有的请求都缓存，设置了之后，仅对在白名单里或符合UA的请求进行缓存
@property (nonatomic, strong) NSArray *whiteListsHost;       //域名白名单
@property (nonatomic, strong) NSArray *whiteListsRequestUrl; //请求地址白名单
@property (nonatomic, strong) NSString *whiteUserAgent;     //WebView的user-agent白名单

+ (SLWebCacheManager *)shareInstance;

///启用缓存功能
- (void)openCache;
///关闭缓存功能
- (void)closeCache;
///是否可以缓存该请求，该请求是否在白名单里或合法
- (BOOL)canCacheRequest:(NSURLRequest *)request;

///对应请求的缓存文件/信息路径
- (NSString *)filePathFromRequest:(NSURLRequest *)request isInfo:(BOOL)info;
///写入缓存数据
- (BOOL)writeCacheData:(NSCachedURLResponse *)cachedURLResponse withRequest:(NSURLRequest *)request;
///加载请求的缓存数据，如果没有缓存就返回nil
- (NSCachedURLResponse *)loadCachedResponeWithRequest:(NSURLRequest *)request;
///请求网络数据并写入本地
- (NSCachedURLResponse *)requestNetworkData:(NSURLRequest *)request;

///清除对应请求的缓存
- (void)removeCacheFileWithRequest:(NSURLRequest *)request;
/// 检测缓存容量，超出限制就清除
- (void)checkCapacity;
///强制清除缓存
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
