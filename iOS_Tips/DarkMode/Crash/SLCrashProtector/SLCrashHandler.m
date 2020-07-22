//
//  SLCrashHandler.m
//  DarkMode
//
//  Created by wsl on 2020/4/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCrashHandler.h"

@implementation SLCrashError
+ (instancetype)errorWithErrorType:(SLCrashErrorType)errorType errorDesc:(NSString *)errorDesc exception:(NSException *)exception callStack:(NSArray*)callStackSymbol {
    SLCrashError *crashError = [SLCrashError new];
    crashError.errorDesc = errorDesc;
    crashError.errorType = errorType;
    crashError.exception = exception;
    //获取当前线程的函数调用栈
    crashError.callStackSymbol = callStackSymbol;
    return crashError;
}
@end


@interface SLCrashHandler ()
@end

@implementation SLCrashHandler

+ (instancetype)defaultCrashHandler {
    static SLCrashHandler *crashHandler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crashHandler = [[SLCrashHandler alloc] init];
        [crashHandler setUncaughtExceptionHandler];
    });
    return crashHandler;
}

/// 其他三方注册的异常处理 handler
static NSUncaughtExceptionHandler *otherUncaughtExceptionHandler = NULL;
///设置异常捕获回调
- (void)setUncaughtExceptionHandler{
    ///先获取保留其他三方的异常Handler
    otherUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    ///注册自己的异常Handler
    NSSetUncaughtExceptionHandler (SL_UncaughtExceptionHandler);
    
    ///注册信号Handler
    signal(SIGABRT, SL_UncaughtSignalHandler);
    signal(SIGILL, SL_UncaughtSignalHandler);
    signal(SIGSEGV, SL_UncaughtSignalHandler);
    signal(SIGFPE, SL_UncaughtSignalHandler);
    signal(SIGBUS, SL_UncaughtSignalHandler);
    signal(SIGPIPE, SL_UncaughtSignalHandler);
    signal(SIGKILL, SL_UncaughtSignalHandler);
    signal(SIGTRAP, SL_UncaughtSignalHandler);
    
}
///异常捕获处理
void SL_UncaughtExceptionHandler(NSException *exception) {
    if (otherUncaughtExceptionHandler) {
        //如果其他三方也有注册，则也执行其他三方的Handle，然后在执行自己的
        otherUncaughtExceptionHandler(exception);
    }
    NSString *exceptionInfo = [NSString stringWithFormat:@"异常：%@, %@",exception.name, exception.reason];
    SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeUnknow errorDesc:exceptionInfo exception:exception callStack:exception.callStackSymbols];
    [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
}


///异常信号处理回调
void SL_UncaughtSignalHandler(int signal) {
    NSString *exceptionInfo = [NSString stringWithFormat:@"异常信号：%@ Crash",signalName(signal)];
       SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeUnknow errorDesc:exceptionInfo exception:nil callStack:[NSThread callStackSymbols]];
    [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
}
///信号名称   关于信号这部分可以看 https://mp.weixin.qq.com/s/hVj-j61Br3dox37SN79fDQ
NSString *signalName(int signal) {
    switch (signal) {
        case SIGABRT:
            /*
             abort() 发生的信号：
             典型的软件信号，通过 pthread_kill() 发送
             */
            return @"SIGABRT";
        case SIGILL:
            /*
             非法指令，即机器码指令不正确：
             1, iOS 上偶现的问题，遇到之后用户会连续闪退，直到应用二进制的缓存重新加载 或重启手机。此问题挺影响体验，但是报给苹果不认，因为苹果那边没有收集到，目前没有太好办法。因为 iOS 应用内无法对一片内存同时获取 w+x 权限的，因此应用无法造成此类问题，所以判断是苹果的问题。
            */
            return @"SIGILL";
        case SIGSEGV:
            /*段错误：
             1、访问未申请的虚拟内存地址
             2、没有写权限的内存写入
            */
            return @"SIGSEGV";
        case SIGFPE:
            /*
             算术运算出错，比如除0错误：
             iOS 默认是不启用的，所以我们一般不会遇到
             */
            return @"SIGFPE";
        case SIGBUS:
            /*总线错误
             1、内存地址对齐出错 2、试图执行没有执行权限的代码地址
             */
            return @"SIGBUS";
        case SIGPIPE:
            /*管道破裂
             1, Socket通信是可能遇到，如读进程以及终止时，写进程继续写入数据。
              */
            return @"SIGPIPE";
        case SIGKILL:
            /*
             进程内无法拦截:
             1, exit(), kill(9) 等函数调用 2, iOS系统杀进程用的，比如 watchDog 杀进程
             */
            return @"SIGKILL";
        case SIGTRAP:
            /*
             由断点指令或其它trap指令产生:
             部分系统框架里面会用 __builtin_trap() 来产生一个 SIGTRAP 类型的 Crash
             */
            return @"SIGTRAP";
        default:
            return @"UNKNOWN";
    }
}


@end
