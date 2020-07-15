//
//  SLCrashHandler.h
//  DarkMode
//
//  Created by wsl on 2020/4/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SLCrashErrorType) {
    /*Array*/
    SLCrashErrorTypeArray = 0,
    /*NSMutableArray*/
    SLCrashErrorTypeMArray,
    /*NSDictionary*/
    SLCrashErrorTypeDictionary,
    /*NSMutableDictionary*/
    SLCrashErrorTypeMDictionary,
    /*NSString*/
    SLCrashErrorTypeString,
    /*NSMutableString*/
    SLCrashErrorTypeMString,
    /*UnrecognizedSelector异常*/
    SLCrashErrorTypeUnrecognizedSelector,
    /*KVO异常*/
    SLCrashErrorTypeKVO,
    /*KVC异常*/
    SLCrashErrorTypeKVC,
    /*野指针*/
     SLCrashErrorTypeZombie,
};

/// 崩溃信息
@interface SLCrashError : NSObject
/// 错误类型
@property (nonatomic, assign) SLCrashErrorType errorType;
/// 错误描述
@property (nonatomic, copy) NSString *errorDesc;
/// 异常对象
@property (nonatomic, strong) NSException *exception;
/// 当前线程的函数调用栈
@property (nonatomic, copy) NSArray<NSString *> *callStackSymbol;

@end

/// 崩溃处理程序
@interface SLCrashHandler : NSObject
/// 异常捕获回调 提供给外界初始化实现自定义处理 ，日志上报等（注意线程安全和循环引用）
@property (nonatomic, copy) void(^crashHandlerBlock)(SLCrashError *crashError);

/// 单例
+ (instancetype)defaultCrashHandler;

/// 捕获崩溃异常信息 Private
- (void)catchCrashException:(NSException * _Nullable )exception type:(SLCrashErrorType)errorType errorDesc:(NSString *)errorDesc;

@end

NS_ASSUME_NONNULL_END
