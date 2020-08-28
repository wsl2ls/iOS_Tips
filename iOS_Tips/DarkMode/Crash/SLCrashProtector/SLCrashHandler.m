//
//  SLCrashHandler.m
//  DarkMode
//
//  Created by wsl on 2020/4/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCrashHandler.h"
#import "BSBacktraceLogger.h"

#import <mach/mach.h>
#import <mach/exc.h>

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
        [crashHandler setCaughtCrashHandler];
    });
    return crashHandler;
}

/// 捕获Mach、Signal、NSException 异常Crash
- (void)setCaughtCrashHandler {
    [self setMachHandler];
    [self setSignalHandler];
    [self setExceptionHandler];
}

#pragma mark - Mach异常捕获
// 创建Mach Port并监听消息
- (void)setMachHandler {
    mach_port_t server_port;
    ///创建异常端口
    kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &server_port);
    assert(kr == KERN_SUCCESS);
    NSLog(@"创建异常消息监听端口: %d", server_port);
    
    ///申请set_exception_ports 的权限
    kr = mach_port_insert_right(mach_task_self(), server_port, server_port, MACH_MSG_TYPE_MAKE_SEND);
    assert(kr == KERN_SUCCESS);
    
    ///设置异常端口  EXC_MASK_CRASH   捕获Mach_CRASH时会导致死锁
    kr = task_set_exception_ports(mach_task_self(), EXC_MASK_BAD_ACCESS, server_port, EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES, THREAD_STATE_NONE);
    
    ///循环等待异常消息
    [self setMachPortListener:server_port];
}

- (void)setMachPortListener:(mach_port_t)mach_port {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __Request__exception_raise_state_identity_t mach_message;
        
        mach_message.Head.msgh_size = 1024;
        mach_message.Head.msgh_local_port = mach_port;
        
        mach_msg_return_t mr;
        
        while (true) {
            mr = mach_msg(&mach_message.Head,
                          MACH_RCV_MSG | MACH_RCV_LARGE,
                          0,
                          mach_message.Head.msgh_size,
                          mach_message.Head.msgh_local_port,
                          MACH_MSG_TIMEOUT_NONE,
                          MACH_PORT_NULL);
            
            if (mr != MACH_MSG_SUCCESS && mr != MACH_RCV_TOO_LARGE) {
                NSLog(@"error!");
            }
            
            mach_msg_id_t msg_id = mach_message.Head.msgh_id;
            mach_port_t remote_port = mach_message.Head.msgh_remote_port;
            mach_port_t local_port = mach_message.Head.msgh_local_port;
            
            NSLog(@"Receive a mach message:[%d], remote_port: %d, local_port: %d, exception code: %d",
                  msg_id,
                  remote_port,
                  local_port,
                  mach_message.exception);
            
            NSString * callStack = [BSBacktraceLogger bs_backtraceOfAllThread];
            NSString *exceptionInfo = [NSString stringWithFormat:@"mach异常：%@",callStack];
            SLCrashError *crashError = [SLCrashError errorWithErrorType:SLCrashErrorTypeUnknow errorDesc:exceptionInfo exception:nil callStack:@[callStack]];
            [[SLCrashHandler defaultCrashHandler].delegate crashHandlerDidOutputCrashError:crashError];
            //mach异常就终止当前程序
//            abort();
        }
    });
}

#pragma mark - Unix signal信号捕获
- (void)setSignalHandler {
    ///注册信号Handler，Unix 信号捕获
    signal(SIGABRT, SL_UncaughtSignalHandler);
    signal(SIGILL, SL_UncaughtSignalHandler);
    signal(SIGSEGV, SL_UncaughtSignalHandler);
    signal(SIGFPE, SL_UncaughtSignalHandler);
    signal(SIGBUS, SL_UncaughtSignalHandler);
    signal(SIGPIPE, SL_UncaughtSignalHandler);
    signal(SIGKILL, SL_UncaughtSignalHandler);
    signal(SIGTRAP, SL_UncaughtSignalHandler);
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
#pragma mark - NSException捕获
/// 其他三方注册的异常处理 handler
static NSUncaughtExceptionHandler *otherUncaughtExceptionHandler = NULL;
- (void)setExceptionHandler {
    ///先获取保留其他三方的异常Handler
    otherUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    ///注册自己的异常Handler
    NSSetUncaughtExceptionHandler (SL_UncaughtExceptionHandler);
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

@end
