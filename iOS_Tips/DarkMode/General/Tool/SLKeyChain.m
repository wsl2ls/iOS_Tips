//
//  SLKeyChain.m
//  DarkMode
//
//  Created by wsl on 2020/6/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLKeyChain.h"
#import <Security/SecItem.h>
#import <Security/SecBase.h>

NSString* const SLkeychainService = @"com.wsl.ios.keychain";
static NSString* const keychainErrorDomain = @"com.wsl.ios.keychain.errorDomain";
static NSInteger const kErrorCodeKeychainSomeArgumentsInvalid = 1000; //! 传入的部分参数无效

@implementation SLKeyChain

///更新钥匙串中的用户名和密码
+ (NSError *)updateKeychainWithService:(NSString *)service account:(NSString *)account password:(NSString *)password {
    
    if (!account || !password || !service) {
        NSError *error = [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
        return error;
    }
    NSDictionary *queryItems = @{(id)kSecClass: (id)kSecClassGenericPassword,
                                 (id)kSecAttrService: service,
                                 (id)kSecAttrAccount: account
    };
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *updatedItems = @{
        (id)kSecValueData: passwordData,
    };
    OSStatus updateStatus = SecItemUpdate((CFDictionaryRef)queryItems, (CFDictionaryRef)updatedItems);
    return [self errorWithErrorCode:updateStatus];
}
///删除用户信息
+ (NSError *)deleteWithService:(NSString *)service account:(NSString *)account {
    
    if (!service || !account) {
        return [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
    }
    NSDictionary *deleteSecItems = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: service,
        (id)kSecAttrAccount: account
    };
    OSStatus errorCode = SecItemDelete((CFDictionaryRef)deleteSecItems);
    return [self errorWithErrorCode:errorCode];
}
///查询用户信息 查到的结果存在NSError中
+ (NSError *)queryKeychainWithService:(NSString *)service account:(NSString *)account {
    
    if (!service || !account) {
        return [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
    }
    NSDictionary *matchSecItems = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: service,
        (id)kSecAttrAccount: account,
        (id)kSecMatchLimit: (id)kSecMatchLimitOne,
        (id)kSecReturnData: @(YES)
    };
    CFTypeRef dataRef = nil;
    OSStatus errorCode = SecItemCopyMatching((CFDictionaryRef)matchSecItems, (CFTypeRef *)&dataRef);
    if (errorCode == errSecSuccess) {
        NSString *password = [[NSString alloc] initWithData:CFBridgingRelease(dataRef) encoding:NSUTF8StringEncoding];
        return [self errorWithErrorCode:errSecSuccess errorMessage:password];
    }
    return [self errorWithErrorCode:errorCode];
}
///保存用户信息
+ (NSError *)saveKeychainWithService:(NSString *)service account:(NSString *)account password:(NSString *)password {
    
    if (!account || !password || !service) {
        NSError *error = [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
        return error;
    }
    
    NSError *queryError = [self queryKeychainWithService:service account:account];
    if (queryError.code == errSecSuccess) {
        // update
        return [self updateKeychainWithService:service account:account password:password];
    }
    
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    // save
    NSDictionary *saveSecItems = @{(id)kSecClass: (id)kSecClassGenericPassword,
                                   (id)kSecAttrService: service,
                                   (id)kSecAttrAccount: account,
                                   (id)kSecValueData: passwordData
    };
    OSStatus saveStatus = SecItemAdd((CFDictionaryRef)saveSecItems, NULL);
    return [self errorWithErrorCode:saveStatus];
}
///错误信息
+ (NSError *)errorWithErrorCode:(OSStatus)errorCode {
    
    NSString *errorMsg = nil;
    
    switch (errorCode) {
        case errSecSuccess: {
            NSLog(@"操作成功");
            return nil;
            break;
        }
        case kErrorCodeKeychainSomeArgumentsInvalid:
            errorMsg = NSLocalizedString(@"参数无效", nil);
            break;
        case errSecDuplicateItem: // -25299
            errorMsg = NSLocalizedString(@"The specified item already exists in the keychain. ", nil);
            break;
        case errSecItemNotFound: // -25300
            errorMsg = NSLocalizedString(@"The specified item could not be found in the keychain. ", nil);
            break;
        default: {
            if (@available(iOS 11.3, *)) {
                errorMsg = (__bridge_transfer NSString *)SecCopyErrorMessageString(errorCode, NULL);
            }
            break;
        }
    }
    NSDictionary *errorUserInfo = nil;
    if (errorMsg) {
        errorUserInfo = @{NSLocalizedDescriptionKey: errorMsg};
        NSLog(@"%s--Line:%d--错误码：%d--错误信息：%@", __FUNCTION__, __LINE__, errorCode, errorMsg);
    }
    return [NSError errorWithDomain:keychainErrorDomain code:kErrorCodeKeychainSomeArgumentsInvalid userInfo:errorUserInfo];
}

+ (NSError *)errorWithErrorCode:(OSStatus)errCode errorMessage:(NSString *)errorMsg {
    
    if (errCode == errSecSuccess && errorMsg) {
        NSLog(@"操作成功");
        return [NSError errorWithDomain:keychainErrorDomain code:errSecSuccess userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
    } else {
        return [self errorWithErrorCode:errCode];
    }
}

@end
