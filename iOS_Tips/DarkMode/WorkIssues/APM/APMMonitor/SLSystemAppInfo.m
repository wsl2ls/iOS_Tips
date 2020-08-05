//
//  SLSystemAppInfo.m
//  DarkMode
//
//  Created by wsl on 2020/8/4.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLSystemAppInfo.h"
#import "sys/utsname.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>


@interface SLSystemAppInfo ()

@end

@implementation SLSystemAppInfo


+ (void)test {
    [self iphoneType];
    
    [self systemVersion];
    [self deviceModel];
    [self userPhoneName];
    [self systemName];
    [self uuidString];
    [self localDeviceModel];
    [self telephonyInfo];
    [self networkType];
    
    
    [self appBundleId];
    [self appVersion];
    [self appBuild];
    [self appName];
    
}

///获取手机型号 iPhone 8...
+ (NSString *)iphoneType{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSDictionary *dict = @{@"iPhone1,1":@"iPhone 1G",
                           @"iPhone1,2":@"iPhone 3G",
                           @"iPhone2,1":@"iPhone 3GS",
                           @"iPhone3,1":@"iPhone 4",
                           @"iPhone3,2":@"iPhone 4",
                           @"iPhone4,1":@"iPhone 4S",
                           @"iPhone5,1":@"iPhone 5",
                           @"iPhone5,2":@"iPhone 5",
                           @"iPhone5,3":@"iPhone 5C",
                           @"iPhone5,4":@"iPhone 5C",
                           @"iPhone6,1":@"iPhone 5S",
                           @"iPhone6,2":@"iPhone 5S",
                           @"iPhone7,1":@"iPhone 6 Plus",
                           @"iPhone7,2":@"iPhone 6",
                           @"iPhone8,1":@"iPhone 6S",
                           @"iPhone8,2":@"iPhone 6S Plus",
                           @"iPhone8,4":@"iPhone SE",
                           @"iPhone9,1":@"iPhone 7",
                           @"iPhone9,3":@"iPhone 7",
                           @"iPhone9,2":@"iPhone 7 Plus",
                           @"iPhone9,4":@"iPhone 7 Plus",
                           @"iPhone10,1":@"iPhone 8",
                           @"iPhone10.4":@"iPhone 8",
                           @"iPhone10,2":@"iPhone 8 Plus",
                           @"iPhone10,5":@"iPhone 8 Plus",
                           @"iPhone10,3":@"iPhone X",
                           @"iPhone10,6":@"iPhone X",
                           @"iPhone11,8":@"iPhone XR",
                           @"iPhone11,2":@"iPhone XS",
                           @"iPhone11,4":@"iPhone XS Max",
                           @"iPhone11,6":@"iPhone XS Max",
                           @"i386":@"Simulator",
                           @"x86_64":@"Simulator"
    };
    return dict[deviceString] == nil ? deviceString : dict[deviceString];
}
///获取手机系统版本 13.4
+ (NSString *)systemVersion {
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    return systemVersion;
}
///获取设备类型  iPhone/iPad/iPod touch
+ (NSString *)deviceModel {
    NSString* deviceModel = [[UIDevice currentDevice] model];
    return deviceModel;
}
///根据地区语言返回设备类型字符串 （国际化区域名称）
+(NSString *)localDeviceModel {
    NSString* localizedModel = [[UIDevice currentDevice] localizedModel];
    return localizedModel;;
}
///操作系统名称 iOS
+ (NSString *)systemName {
    NSString* systemName = [[UIDevice currentDevice] systemName];
    return systemName;
}
///获取用户手机别名  用户定义的名称 通用-关于本机-名称  wsl的iphone
+ (NSString *)userPhoneName {
    NSString* userPhoneName = [[UIDevice currentDevice] name];
    return userPhoneName;
}
///设备唯一标识的字母数字字符串  C5668446-C443-4898-A213-209AECE3626C
+ (NSString *)uuidString {
    NSString *UUIDString = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    return UUIDString;
}
/// 获取电话运营商信息
+ (NSString *)telephonyInfo {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mCarrier = [NSString stringWithFormat:@"%@",[carrier carrierName]];
    return mCarrier;
}
// 获取网络类型
+(NSString*)networkType {
    /**
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyGPRS          __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyEdge          __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyWCDMA         __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyHSDPA         __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyHSUPA         __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyCDMA1x        __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyCDMAEVDORev0  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyCDMAEVDORevA  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyCDMAEVDORevB  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyeHRPD         __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     CORETELEPHONY_EXTERN NSString * const CTRadioAccessTechnologyLTE           __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);
     **/
    //
    CTTelephonyNetworkInfo* info=[[CTTelephonyNetworkInfo alloc] init];
    if (@available(iOS 12.0, *)) {
        NSDictionary *dict= info.serviceCurrentRadioAccessTechnology;
        //        NSLog(@"%@",dict);
    } else {
    }
    NSString *networkType = info.currentRadioAccessTechnology;
    return networkType;
}

///获取APP名字
+ (NSString *)appName {
    NSString *appCurName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    return appCurName;
}
///获取APP bundle id
+ (NSString *)appBundleId {
    NSString *appBundleId = [[NSBundle mainBundle] bundleIdentifier];
    return appBundleId;
}
///获取当前App版本号
+ (NSString *)appVersion {
    NSString *appCurVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return appCurVersion;
}
///获取当前App编译版本号
+ (NSString *)appBuild {
    NSString *appBuildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return appBuildVersion;
}




@end
