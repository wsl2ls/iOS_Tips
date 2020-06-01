//
//  SLWebCacheManager.h
//  DarkMode
//
//  Created by wsl on 2020/5/31.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLWebCacheManager : NSObject

@property (nonatomic, assign) NSUInteger memoryCapacity;  //内存缓存容量 默认20M
@property (nonatomic, assign) NSUInteger diskCapacity; //磁盘缓存容量 默认50M
@property (nonatomic, assign) NSUInteger cacheTime;   //缓存使用的有效时长 默认0，即永久有效，除非手动删除，否则有缓存之后，只从缓存读取
@property (nonatomic, copy) NSString *diskPath;   //磁盘路径
@property (nonatomic, copy) NSString *cacheFolder;   //缓存文件夹
@property (nonatomic, copy) NSString *subDirectory;   //子路径

@property (nonatomic) BOOL isDownloadMode; //是否为下载模式
@property (nonatomic) BOOL isSavedOnDisk;  //是否存磁盘

@property (nonatomic, strong) NSMutableDictionary *responseDic; //防止下载请求的循环调用

@property (nonatomic, strong) NSMutableDictionary *whiteListsHost;       //域名白名单
@property (nonatomic, strong) NSMutableDictionary *whiteListsRequestUrl; //请求地址白名单
@property (nonatomic, strong) NSString *whiteUserAgent;             //WebView的user-agent白名单

@property (nonatomic, strong) NSString *replaceUrl;
@property (nonatomic, strong) NSData *replaceData;


@property (nonatomic) BOOL isUsingURLProtocol; //缓存方案 默认是SLUrlCache

+ (SLWebCacheManager *)shareInstance;

///启用缓存功能
- (void)openCache;
///关闭缓存功能
- (void)closeCache;

///查找请求对应的文件/信息路径
- (NSString *)filePathFromRequest:(NSURLRequest *)request isInfo:(BOOL)info;
///加载本地请求的缓存数据，如果没有返回nil
- (NSCachedURLResponse *)localCacheResponeWithRequest:(NSURLRequest *)request;
///请求网络数据
- (NSCachedURLResponse *)requestNetworkData:(NSURLRequest *)request;

///清除对应请求的缓存
- (void)removeCacheFileWithRequest:(NSURLRequest *)request;
/// 检测缓存容量，超出限制就清除
- (void)checkCapacity;
///强制清除缓存
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
