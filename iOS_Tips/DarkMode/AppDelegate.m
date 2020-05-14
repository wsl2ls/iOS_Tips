//
//  AppDelegate.m
//  DarkMode
//
//  Created by wsl on 2019/9/16.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "AppDelegate.h"
#import "Growing.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
    [Growing startWithAccountId:@"9d1cd7f1d044264a"];
    // 其他配置
    // 开启Growing调试日志 可以开启日志
    // [Growing setEnableLog:YES];
    
    return YES;
}

//内存警告
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    //    free_some_mem(1024*1024*10);
    NSLog(@"内存警告");
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
   if ([Growing handleUrl:url]){
        // 请务必确保该函数被调用
        NSLog(@"埋点SDK有效");
        return YES;
    }
     NSLog(@"埋点SDK失败");
    return NO;
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
