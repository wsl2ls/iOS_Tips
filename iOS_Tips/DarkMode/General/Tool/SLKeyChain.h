//
//  SLKeyChain.h
//  DarkMode
//
//  Created by wsl on 2020/6/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString* const SLkeychainService;

///存储管理用户账号和密码到钥匙串
@interface SLKeyChain : NSObject

/// 保存用户信息到钥匙串中
/// @param service  存储服务的key，一个service可以存储多个account/password键值对
/// @param account    账号
/// @param password  密码
+ (NSError *)saveKeychainWithService:(NSString *)service
                             account:(NSString *)account
                            password:(NSString *)password;
///从钥匙串中删除这条用户信息
+ (NSError *)deleteWithService:(NSString *)service
                       account:(NSString *)account;

///查询用户信息 查到的结果存在NSError中
+ (NSError *)queryKeychainWithService:(NSString *)service
                              account:(NSString *)account;

///更新钥匙串中的用户名和密码
+ (NSError *)updateKeychainWithService:(NSString *)service
                               account:(NSString *)account
                              password:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
