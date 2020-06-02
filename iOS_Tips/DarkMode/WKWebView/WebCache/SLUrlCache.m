//
//  SLUrlCache.m
//  DarkMode
//
//  Created by wsl on 2020/6/1.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLUrlCache.h"
#import "SLWebCacheManager.h"

@interface SLUrlCache ()

@end

@implementation SLUrlCache

#pragma mark - Override
///开始缓存
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    if (![[SLWebCacheManager shareInstance] canCacheRequest:request]) {
        return nil;
    }
    ///本地缓存的数据
    NSCachedURLResponse *cachedResponse =  [[SLWebCacheManager shareInstance] loadCachedResponeWithRequest:request];
    if(!cachedResponse) {
        //没有缓存，请求网络数据
        cachedResponse = [[SLWebCacheManager shareInstance] requestNetworkData:request];
    }
    //调用系统的缓存方法，当然这里也可以不用调
    [self storeCachedResponse:cachedResponse forRequest:request];
    return cachedResponse;;
}
///移除缓存
- (void)removeCachedResponseForRequest:(NSURLRequest *)request {
    [super removeCachedResponseForRequest:request];
    [[SLWebCacheManager shareInstance] removeCacheFileWithRequest:request];
}
///移除所有缓存
- (void)removeAllCachedResponses {
    [super removeAllCachedResponses];
}

@end
