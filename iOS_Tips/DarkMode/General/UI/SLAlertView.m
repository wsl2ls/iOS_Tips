//
//  SLAlertView.m
//  DarkMode
//
//  Created by wsl on 2020/3/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAlertView.h"

@interface SLAlertView ()
@end

@implementation SLAlertView
///  展示几秒后自动隐藏
/// @param text 文本
/// @param delay 展示时长
+ (void)showAlertViewWithText:(NSString *)text delayHid:(NSTimeInterval)delay {
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    progressHUD.animationType = MBProgressHUDAnimationFade;
    progressHUD.mode = MBProgressHUDModeText;
    progressHUD.label.text = text;
    progressHUD.label.numberOfLines = 0;
    [[UIApplication sharedApplication].keyWindow addSubview:progressHUD];
    [progressHUD showAnimated:YES];
    [progressHUD hideAnimated:YES afterDelay:delay];
}
@end
