//
//  SLSystemAppInfo.h
//  DarkMode
//
//  Created by wsl on 2020/8/4.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SLAuthorizationStatus) {
    SLAuthorizationStatusUnknow = -1, //未知的
    SLAuthorizationStatusNotDetermined = 0, //用户还没有选择过(第一次) 这时会自动出现系统询问授权弹窗，之后不会
    SLAuthorizationStatusRestricted,  //家长控制，限制用户授权的权限
    SLAuthorizationStatusDenied,    //用户拒绝授权
    SLAuthorizationStatusAuthorized,  //已授权
    SLAuthorizationStatusAuthorizedAlways,  //始终都授权，比如定位，蓝牙
    SLAuthorizationStatusAuthorizedWhenInUse,  //仅当应用使用时授权 比如定位
    SLAuthorizationStatusProvisional,   //临时授权，用完一次即权利解除，下次再申请
    SLAuthorizationStatusUnsupported,   //该硬件不支持授权的功能，比如蓝牙、FaceID、摄像头，设备可能不支持
    SLAuthorizationStatusOff          //请求授权的功能处于关闭状态，比如蓝牙
};

NS_ASSUME_NONNULL_BEGIN

///包含系统、应用、隐私权限的信息
@interface SLSystemAppInfo : NSObject

+ (instancetype)manager;


+ (void)test;

@end

NS_ASSUME_NONNULL_END
