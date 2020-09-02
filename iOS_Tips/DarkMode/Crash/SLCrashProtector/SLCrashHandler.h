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
    /*未知错误*/
    SLCrashErrorTypeUnknow = 0,
    /*Array*/
    SLCrashErrorTypeArray,
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
    /*异步线程更新UI*/
    SLCrashErrorTypeAsynUpdateUI,
    /*野指针*/
    SLCrashErrorTypeZombie,
    /*内存泄漏/循环引用*/
    SLCrashErrorTypeLeak
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
///初始化
+ (instancetype)errorWithErrorType:(SLCrashErrorType)errorType errorDesc:(NSString *)errorDesc exception:(nullable NSException *)exception callStack:(NSArray*)callStackSymbol;
@end


@class SLCrashHandler;
@protocol SLCrashHandlerDelegate <NSObject>
///捕获到错误信息，交给外界delegate处理
- (void)crashHandlerDidOutputCrashError:(SLCrashError *)crashError;
@end

/// 崩溃处理程序    注意：部分防护功能还不完善，比如野指针和内存泄漏/循环引用
@interface SLCrashHandler : NSObject

///异常捕获回调 提供给外界实现自定义处理 ，日志上报等（注意线程安全）
@property (nonatomic, weak) id<SLCrashHandlerDelegate>delegate;

/// 单例
+ (instancetype)defaultCrashHandler;

@end

NS_ASSUME_NONNULL_END
