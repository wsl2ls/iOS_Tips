//
//  SLDarkModeViewController.m
//  DarkMode
//
//  Created by wsl on 2019/9/17.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLDarkModeViewController.h"

//tableView、UIAlertView等系统控件，在不自定义颜色的情况下，默认颜色都是动态的，支持暗黑模式
@interface SLDarkModeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *systemColorLabel;  //系统提供的动态颜色，比较多，可以自己查看官网文档
@property (weak, nonatomic) IBOutlet UILabel *customColorLabel; //自定义动态颜色
@property (weak, nonatomic) IBOutlet UIImageView *dyImageView; //动态图片
@property (weak, nonatomic) IBOutlet UIButton *userInterfaceStyleBtn;  //手动强制设置模式

@end

@implementation SLDarkModeViewController

#pragma mark - OverWrite

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

/// 重写以下方法来监听模式的变化，变化时才执行，如果强制手动设置overrideUserInterfaceStyle后，即使系统样式变化，此方法也不再执行
/// @param previousTraitCollection  变化前的模式
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([previousTraitCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
        self.navigationItem.title = @"暗黑模式";
        NSLog(@"切换到了暗黑模式");
    } else {
        self.navigationItem.title = @"光亮模式";
        NSLog(@"切换到了光亮模式");
    }
    
    self.customColorLabel.layer.borderColor = self.customColorLabel.textColor.CGColor;
}
////当前状态栏的样式
//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

#pragma mark - UI
- (void)setupUI {
    
    //获取手机系统用户界面样式
    if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.navigationItem.title = @"暗黑模式";
    } else {
        self.navigationItem.title = @"光亮模式";
    }
    
    // 系统动态颜色
    self.systemColorLabel.textColor = [UIColor labelColor];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    //自定义动态颜色
    UIColor *dyBackgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
        if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
            //如果是光模式，返回的背景颜色
            return [UIColor orangeColor];
        } else {
            //如果是暗黑模式，返回的颜色
            return [UIColor greenColor];
        }
    }];
    self.customColorLabel.backgroundColor = dyBackgroundColor;
    UIColor *dyTextColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
        if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
            //如果当前是光模式，返回的字体颜色
            return [UIColor blueColor];
        } else {
            //如果是暗黑模式，返回的颜色
            return [UIColor purpleColor];
        }
    }];
    self.customColorLabel.textColor = dyTextColor;
    
    // 动态CGColor的颜色变化设置要放在监听模式变化的方法traitCollectionDidChange里，同时要设置默认值
    self.customColorLabel.layer.borderColor = dyTextColor.CGColor;
    self.customColorLabel.layer.borderWidth = 3;
    
    //动态模式图片
    self.dyImageView.image = [UIImage imageNamed:@"apple"];
}

#pragma mark - Data

#pragma mark - Getter

#pragma mark - EventsHandle
- (IBAction)setUserInterfaceStyle:(id)sender {
    
    //判断当前视图样式 是否跟系统当前样式不同
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:UITraitCollection.currentTraitCollection]) {
        NSLog(@"当前视图样式和系统样式不同");
    }
    
    //手动强制设置当前视图的模式
//    self.navigationController.navigationBar.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    //    [self setNeedsStatusBarAppearanceUpdate];
}
#pragma mark - HelpMethods




/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
