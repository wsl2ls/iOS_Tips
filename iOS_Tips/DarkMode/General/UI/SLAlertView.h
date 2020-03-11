//
//  SLAlertView.h
//  DarkMode
//
//  Created by wsl on 2020/3/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MBProgressHUD.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLAlertView : NSObject
///  展示几秒后自动隐藏
/// @param text 文本
/// @param delay 展示时长
+ (void)showAlertViewWithText:(NSString *)text delayHid:(NSTimeInterval)delay;
@end

NS_ASSUME_NONNULL_END
