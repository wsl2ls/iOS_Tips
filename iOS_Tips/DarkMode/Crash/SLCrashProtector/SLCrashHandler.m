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

@implementation SLCrashHandler

+ (instancetype)defaultCrashHandler {
    static SLCrashHandler *crashHandler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crashHandler = [[SLCrashHandler alloc] init];
    });
    return crashHandler;
}

@end
