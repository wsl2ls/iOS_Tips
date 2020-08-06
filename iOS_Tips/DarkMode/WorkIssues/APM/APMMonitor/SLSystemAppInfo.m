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
#import <Photos/Photos.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import <CoreLocation/CLLocationManager.h>
#import <UserNotifications/UserNotifications.h>
#import <Contacts/Contacts.h>
#import <AddressBook/AddressBook.h>
#import <EventKit/EventKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <LocalAuthentication/LocalAuthentication.h>


#define SL_IOS_CELLULAR    @"pdp_ip0"
#define SL_IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define SL_IP_ADDR_IPv4    @"ipv4"
#define SL_IP_ADDR_IPv6    @"ipv6"

@interface SLSystemAppInfo ()<CBCentralManagerDelegate>
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
    [self getIPAddress:YES];
    
    [self appBundleId];
    [self appVersion];
    [self appBuild];
    [self appName];
    
    [self checkPushAuthorization];
    [self checkPhotoLibraryAuthorization];
    [self checkLocationAuthorization];
    [self checkCameraAuthorization];
    [self checkMicrophoneAuthorization];
    
}

#pragma mark - Override
/// 重写allocWithZone方法，保证alloc或者init创建的实例不会产生新实例，因为该类覆盖了allocWithZone方法，所以只能通过其父类分配内存，即[super allocWithZone]
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self manager];
}
/// 重写copyWithZone方法，保证复制返回的是同一份实例
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [SLSystemAppInfo manager];
}

#pragma mark - Public
+ (instancetype)manager {
    static SLSystemAppInfo *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:NULL] init];
    });
    return manager;
}

#pragma mark - System Info

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
                           @"iPhone12,1":@"iPhone 11",
                           @"iPhone12,3":@"iPhone 11 Pro",
                           @"iPhone12,5":@"iPhone 11 Pro Max",
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
///是否是iPhoneX系列/刘海屏
+ (BOOL)isIPhoneXSeries{
    BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneXSeries;
    }
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [self getKeyWindow];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    return iPhoneXSeries;
}
+ (UIWindow *)getKeyWindow{
    UIWindow *keyWindow = nil;
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        keyWindow = [[UIApplication sharedApplication].delegate window];
    }else{
        NSArray *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *window in windows) {
            if (!window.hidden) {
                keyWindow = window;
                break;
            }
        }
    }
    return keyWindow;
}
/// 获取电话运营商信息
+ (NSString *)telephonyInfo {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mCarrier = [NSString stringWithFormat:@"%@",[carrier carrierName]];
    return mCarrier;
}
/// 获取网络类型
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
///获取设备当前网络IP地址
+ (NSString *)getIPAddress:(BOOL)preferIPv4 {
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" SL_IP_ADDR_IPv4, IOS_VPN @"/" SL_IP_ADDR_IPv6,*/ SL_IOS_WIFI @"/" SL_IP_ADDR_IPv4, SL_IOS_WIFI @"/" SL_IP_ADDR_IPv6, SL_IOS_CELLULAR @"/" SL_IP_ADDR_IPv4, SL_IOS_CELLULAR @"/" SL_IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" SL_IP_ADDR_IPv6, IOS_VPN @"/" SL_IP_ADDR_IPv4,*/ SL_IOS_WIFI @"/" SL_IP_ADDR_IPv6, SL_IOS_WIFI @"/" SL_IP_ADDR_IPv4, SL_IOS_CELLULAR @"/" SL_IP_ADDR_IPv6, SL_IOS_CELLULAR @"/" SL_IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [[self class] getIPAddresses];
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
        address = addresses[key];
        if(address) *stop = YES;
    } ];
    return address ? address : @"0.0.0.0";
}
//获取所有相关IP信息
+ (NSDictionary *)getIPAddresses {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = SL_IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = SL_IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}



#pragma mark - App Info
///获取APP名字  SLTips
+ (NSString *)appName {
    NSString *appCurName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (!appCurName) {
        appCurName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    return appCurName;
}
///获取APP bundle id    com.wsl2ls.tips
+ (NSString *)appBundleId {
    NSString *appBundleId = [[NSBundle mainBundle] bundleIdentifier];
    return appBundleId;
}
///获取当前App版本号 1.1.0
+ (NSString *)appVersion {
    NSString *appCurVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return appCurVersion;
}
///获取当前App编译版本号 1
+ (NSString *)appBuild {
    NSString *appBuildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return appBuildVersion;
}

#pragma mark - 隐私权限

///检测推送通知权限
+ (SLAuthorizationStatus)checkPushAuthorization{
    __block SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types  == UIUserNotificationTypeNone) {
        authorizationStatus = SLAuthorizationStatusDenied;
        return authorizationStatus;
    }else {
        authorizationStatus = SLAuthorizationStatusAuthorized;
        return authorizationStatus;
    }
#else
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        UNAuthorizationStatus pushAuthorizationStatus = settings.authorizationStatus;
        switch (pushAuthorizationStatus) {
            case UNAuthorizationStatusNotDetermined:
                authorizationStatus = SLAuthorizationStatusNotDetermined;
                break;
            case UNAuthorizationStatusDenied:
                authorizationStatus = SLAuthorizationStatusDenied;
                break;
            case UNAuthorizationStatusAuthorized:
                authorizationStatus = SLAuthorizationStatusAuthorized;
                break;
            case UNAuthorizationStatusProvisional:
                ///临时授权，用完权利解除，下次再申请
                authorizationStatus = SLAuthorizationStatusProvisional;
                break;
            default:
                authorizationStatus = SLAuthorizationStatusUnknow;
                break;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
#endif
    return authorizationStatus;
}

///检查相册访问权限
+ (SLAuthorizationStatus)checkPhotoLibraryAuthorization {
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0 //iOS 8.0以下使用AssetsLibrary.framework
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    authorizationStatus = (SLAuthorizationStatus)status;
#else   //iOS 8.0以上使用Photos.framework
    PHAuthorizationStatus current = [PHPhotoLibrary authorizationStatus];
    authorizationStatus = (SLAuthorizationStatus)current;
#endif
    return authorizationStatus;
}

///检查定位权限
+ (SLAuthorizationStatus)checkLocationAuthorization  {
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    //定位服务是否可用
    if ([CLLocationManager locationServicesEnabled]) {
        CLAuthorizationStatus state = [CLLocationManager authorizationStatus];
        if (state == kCLAuthorizationStatusNotDetermined) {
            authorizationStatus = SLAuthorizationStatusNotDetermined;
        }else if(state == kCLAuthorizationStatusRestricted){
            authorizationStatus = SLAuthorizationStatusRestricted;
        }else if(state == kCLAuthorizationStatusDenied){
            authorizationStatus = SLAuthorizationStatusDenied;
        }else if(state == kCLAuthorizationStatusAuthorizedAlways){
            authorizationStatus = SLAuthorizationStatusAuthorizedAlways;
        }else if(state == kCLAuthorizationStatusAuthorizedWhenInUse){
            authorizationStatus = SLAuthorizationStatusAuthorizedWhenInUse;
        }
    }else{
        //定位服务不可用
        authorizationStatus = SLAuthorizationStatusUnsupported;
    }
    return authorizationStatus;
}

///检查相机/摄像头权限
+ (SLAuthorizationStatus)checkCameraAuthorization  {
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    NSString *mediaType = AVMediaTypeVideo;//读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];//读取设备授权状态
    authorizationStatus = (SLAuthorizationStatus)authStatus;
    return authorizationStatus;
}

///检查话筒/麦克风权限
+ (SLAuthorizationStatus)checkMicrophoneAuthorization {
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    NSString *mediaType = AVMediaTypeAudio;//读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];//读取设备授权状态
    authorizationStatus = (SLAuthorizationStatus)authStatus;
    return authorizationStatus;
}

///检测通讯录权限
+ (SLAuthorizationStatus)checkContactsAuthorization{
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    if (@available(iOS 9.0, *)) {//iOS9.0之后
        CNAuthorizationStatus authStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        authorizationStatus = (SLAuthorizationStatus)authStatus;
    }else{//iOS9.0之前
        ABAuthorizationStatus authorStatus = ABAddressBookGetAuthorizationStatus();
        authorizationStatus = (SLAuthorizationStatus)authorStatus;
    }
    return authorizationStatus;
}

///检测日历权限
+ (SLAuthorizationStatus)checkCalendarAuthorization {
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    authorizationStatus = (SLAuthorizationStatus)status;
    return authorizationStatus;
}

///检测提醒事项权限
+ (SLAuthorizationStatus)checkRemindAuthorization {
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
    authorizationStatus = (SLAuthorizationStatus)status;
    return authorizationStatus;
}

///检测蓝牙权限
- (void)checkBluetoothAuthorization {
    if (@available(iOS 13.1, *)) {
        CBManagerAuthorization authorization = [CBManager authorization];
        SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
        if (authorization == CBManagerAuthorizationAllowedAlways) {
            authorizationStatus = SLAuthorizationStatusAuthorizedAlways;
        }else {
            authorizationStatus = (SLAuthorizationStatus)authorization;
        }
    } else {
        CBCentralManager *bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}
///CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    CBManagerState state = central.state;
    if (state == CBManagerStateResetting) {
        //重置或重新连接
        authorizationStatus = SLAuthorizationStatusUnknow;
    } else if (state == CBManagerStateUnsupported) {
        //不支持蓝牙功能
        authorizationStatus = SLAuthorizationStatusUnsupported;
    } else if (state == CBManagerStateUnauthorized) {
        //拒绝授权
        authorizationStatus = SLAuthorizationStatusDenied;
    } else if (state == CBManagerStatePoweredOff) {
        //蓝牙处于关闭状态
        authorizationStatus = SLAuthorizationStatusOff;
    } else if (state == CBManagerStatePoweredOn) {
        //已授权
        authorizationStatus = SLAuthorizationStatusAuthorized;
    }
}

///请求FaceID权限
+ (void)checkFaceIDAuthorization {
    __block SLAuthorizationStatus authorizationStatus = SLAuthorizationStatusUnknow;
    if (@available(iOS 11.0, *)) {
        LAContext *authenticationContext = [[LAContext alloc]init];
        NSError *error = nil;
        ///是否能验证人脸数据
        BOOL canEvaluatePolicy = [authenticationContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
        if (canEvaluatePolicy) {
            if (authenticationContext.biometryType == LABiometryTypeFaceID) {
                //验证当前人脸数据
                [authenticationContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"开始验证" reply:^(BOOL success, NSError * _Nullable error) {
                    if (error) {
                    } else {
                        if (success) {
                            
                        }
                    }
                }];
            } else {
                
            }
        }else {
            if (error.code == -8) {
                NSLog(@"错误次数太多，被锁定");
            }else{
                NSLog(@"没有设置人脸数据,请前往设置");
            }
        }
    }else {
        authorizationStatus = SLAuthorizationStatusUnsupported;
    }
    
}



///请求相册权限
+ (void)requestAuthorizationLibrary {
    ///相册授权状态
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        // 用户还没有做出过是否授权的选择
        // 只有第一次请求授权时才会自动出现系统弹窗，之后再请求授权时也不会弹出系统询问弹窗
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    // 用户第一次同意了访问相册权限
                    NSLog(@"用户同意授权");
                }else if (status == PHAuthorizationStatusDenied){
                    NSLog(@"用户拒绝授权");
                }
            });
        }];
        NSLog(@"用户还没有过选择");
    }else if (status == PHAuthorizationStatusRestricted) {
        NSLog(@"用户无法授予此类权限,比如家长控制");
    }else if (status == PHAuthorizationStatusDenied) {
        NSLog(@"用户已拒绝授权");
    }else if (status == PHAuthorizationStatusAuthorized) {
        NSLog(@"用户已同意授权");
    }
}


@end
