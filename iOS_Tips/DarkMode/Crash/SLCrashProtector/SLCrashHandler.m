//
//  SLCrashHandler.m
//  DarkMode
//
//  Created by wsl on 2020/4/15.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCrashHandler.h"

@implementation SLCrashError

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

/// 捕获崩溃异常

- (void)catchCrashException:(NSException *)exception type:(SLCrashErrorType)errorType errorDesc:(NSString *)errorDesc {
    SLCrashError *crashError = [SLCrashError new];
    crashError.errorDesc = errorDesc;
    crashError.errorType = SLCrashErrorTypeArray;
    crashError.exception = exception;
    NSLog(@"%@",errorDesc);
    if (self.crashHandlerBlock) {
        self.crashHandlerBlock(crashError);
    }
}


@end
