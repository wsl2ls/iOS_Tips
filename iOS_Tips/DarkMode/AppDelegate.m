//
//  AppDelegate.m
//  DarkMode
//
//  Created by wsl on 2019/9/16.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    SLSetUncaughtExceptionHandler();
    return YES;
}

///系统异常捕获处理
void HandleException(NSException *exception) {
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"程序异常：%@ \nException reason：%@ \nException stack：%@",name, reason, stackArray];
    NSLog(@"%@", exceptionInfo);
}
//设置异常捕获处理方法
void SLSetUncaughtExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(&HandleException);
}
//内存警告
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    //    free_some_mem(1024*1024*10);
    NSLog(@"内存警告");
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    
    NSLog(@"configurationForConnectingSceneSession ");
    
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    
    NSLog(@"didDiscardSceneSessions ");
    
}


@end
