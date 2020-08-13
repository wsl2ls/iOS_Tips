//
//  SLToolMacro.h
//  DarkMode
//
//  Created by wsl on 2020/8/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#ifndef SLToolMacro_h
#define SLToolMacro_h

#pragma mark - Call Me
///我的联系方式
#define SL_JianShuUrl @"https://www.jianshu.com/u/e15d1f644bea"
#define SL_GithubUrl @"https://github.com/wsl2ls/iOS_Tips.git"
#define SL_WeChat @"iOS2679114653"
#define SL_QQGroup @"835303405"
#define SL_WeiBo @"https://weibo.com/5732733120/profile?rightmod=1&wvr=6&mod=personinfo&is_all=1"
#define SL_CSDN  @"https://blog.csdn.net/wsl2ls"
#define SL_JueJin @"https://juejin.im/user/5c00d97b6fb9a049fb436288"
#define SL_Blog @"https://wsl2ls.github.io"
//【腾讯文档】2020_慕课网/极客/腾讯课堂等课程资源：https://docs.qq.com/doc/DS1lhWkhPc2xEamx5

#pragma mark - About UI/Device
//---------------------- About UI/Device  ----------------------------
#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6Plus ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6PlusScale ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2001), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhoneXR ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhoneXM ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)

#define SL_SafeAreaEnable ((iPhoneX || iPhoneXR || iPhoneXM) ? YES : NO)

#define SL_TopSafeAreaHeight (SL_SafeAreaEnable ? 44.f : 20.f)
#define SL_TopNavigationBarHeight (SL_SafeAreaEnable ? 88.f : 64.f)
#define SL_BottomTabbarHeight (SL_SafeAreaEnable ? (49.f + 34.f) : (49.f))
#define SL_BottomSafeAreaHeight (SL_SafeAreaEnable ? (34.f) : (0.f))

/// 屏幕宽高
#define SL_kScreenWidth [UIScreen mainScreen].bounds.size.width
#define SL_kScreenHeight [UIScreen mainScreen].bounds.size.height

/** 判断是否为iPhone */
#define isiPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
/** 判断是否是iPad */
#define isiPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
/** 判断是否为iPod */
#define isiPod ([[[UIDevice currentDevice] model] isEqualToString:@"iPod touch"])

//Get the OS version.       判断操作系统版本
#define SL_IOSVERSION [[[UIDevice currentDevice] systemVersion] floatValue]
#define SL_CurrentSystemVersion ([[UIDevice currentDevice] systemVersion])
#define SL_CurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])

//judge the simulator or hardware device        判断是真机还是模拟器
#if TARGET_OS_IPHONE
//iPhone Device
#endif
#if TARGET_IPHONE_SIMULATOR
//iPhone Simulator
#endif

#pragma mark - About Helper 辅助方法
//---------------------- About Helper 辅助方法 ----------------------------
/// 弱引用对象
#define SL_WeakSelf __weak typeof(self) weakSelf = self;

///主线程操作
#define SL_DISPATCH_ON_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(),mainQueueBlock);
#define SL_GCDWithGlobal(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
#define sl_GCDWithMain(block) dispatch_async(dispatch_get_main_queue(),block)

///NSUserDefaults 存储
#define SL_UserDefaultSetObjectForKey(__VALUE__,__KEY__) \
{\
[[NSUserDefaults standardUserDefaults] setObject:__VALUE__ forKey:__KEY__];\
[[NSUserDefaults standardUserDefaults] synchronize];\
}
///NSUserDefaults     获得存储的对象
#define SL_UserDefaultObjectForKey(__KEY__)  [[NSUserDefaults standardUserDefaults] objectForKey:__KEY__]
///NSUserDefaults      删除对象
#define SL_UserDefaultRemoveObjectForKey(__KEY__) \
{\
[[NSUserDefaults standardUserDefaults] removeObjectForKey:__KEY__];\
[[NSUserDefaults standardUserDefaults] synchronize];\
}

/** 快速查询一段代码的执行时间 */
/** 用法
 SL_StartTime
 do your work here
 SL_EndDuration
 */
#define SL_StartTime NSDate *startTime = [NSDate date]
#define SL_EndDuration -[startTime timeIntervalSinceNow]

// STRING容错机制
#define SL_IS_NULL(x)                    (!x || [x isKindOfClass:[NSNull class]])
#define SL_IS_EMPTY_STRING(x)            (SL_IS_NULL(x) || [x isEqual:@""] || [x isEqual:@"(null)"])
#define SL_DEFUSE_EMPTY_STRING(x)        (!SL_IS_EMPTY_STRING(x) ? x : @"")


//沙河目录
///获取沙盒主目录路径
#define SL_HomeDir  NSHomeDirectory();
/// 获取Documents目录路径
#define SL_DocumentDir  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
/// 获取Library的目录路径
#define SL_LibraryDir  [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
/// 获取Caches目录路径
#define SL_CachesDir  [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]
/// 获取tmp目录路径
#define SL_TmpDir  NSTemporaryDirectory()

#pragma mark - About Color 颜色
//---------------------- About Color 颜色 ----------------------------
/// 随机颜色
#define SL_UIColorFromRandomColor [UIColor colorWithRed:arc4random()%255/255.0 green:arc4random()%255/255.0 blue:arc4random()%255/255.0 alpha:1.0]
/// rgb颜色
#define SL_UIColorFromRGB(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
/// 16进制 颜色
#define SL_UIColorFromHex(rgbValue, a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]

#pragma mark - About Log 打印日志
//---------------------- About Log 打印日志 ----------------------------
/// 打印
#ifdef DEBUG
#   define NSLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#   define SL_Log(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#define SL_NSLog(...) printf("%f %s %ld :%s\n",[[NSDate date]timeIntervalSince1970],strrchr(__FILE__,'/'),[[NSNumber numberWithInt:__LINE__] integerValue],[[NSString stringWithFormat:__VA_ARGS__]UTF8String]);
#else
#   define NSLog(fmt, ...)
#   define SL_Log(...)
#   define SL_NSLog(...)
#endif

//---------------------- About Shader 着色器 ----------------------------
//#x 将参数x字符串化
#define STRINGIZE(x)    #x
#define STRINGIZE2(x)    STRINGIZE(x)
#define Shader_String(text) @ STRINGIZE2(text)




#endif /* SLToolMacro_h */
