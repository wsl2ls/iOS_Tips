//
//  SLMenuViewController.m
//  DarkMode
//
//  Created by wsl on 2020/3/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLMenuViewController.h"


@interface SLTextView : UITextView
@property (nonatomic, weak) UIResponder *overrideNextResponder;
@end
@implementation SLTextView

- (UIResponder *)nextResponder {
    if(_overrideNextResponder == nil){
        return [super nextResponder];
    } else {
        return _overrideNextResponder;
    }
}
// UIMenuController 菜单可以执行操作
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (_overrideNextResponder != nil) {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}
@end

@interface SLLable : UILabel
@end
@implementation SLLable
// UIMenuController 菜单可以执行操作
-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(save:) ||
        action == @selector(note:) ||
        action == @selector(copy:)) {
        return YES;
    }
    return NO;
}
// 能否成为第一响应者
- (BOOL)canBecomeFirstResponder {
    return YES;
}
- (void)note:(id)sender {
    
}
- (void)save:(id)sender {
    
}
- (void)copy:(id)sender {
    
}
@end


@interface SLMenuViewController ()
@property (weak, nonatomic) IBOutlet SLTextView *textView;
@property (weak, nonatomic) IBOutlet SLLable *titleLabel;
@end

@implementation SLMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"键盘和UIMenuController并存解决";
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressShowMenuView:)];
    [self.titleLabel addGestureRecognizer:longPressGestureRecognizer];
}

//长按显示菜单 UIMenuController
- (void)longPressShowMenuView:(UILongPressGestureRecognizer *)longPress {
    if(self.textView.isFirstResponder){
        //如果textView是第一响应者，则对titleLabel进行响应透传
        self.textView.overrideNextResponder = self.titleLabel;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuViewDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
    }else {
        [self.titleLabel becomeFirstResponder];
    }
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *saveItems = [[UIMenuItem alloc] initWithTitle:@"保存" action:@selector(save:)];
    UIMenuItem *noteItem = [[UIMenuItem alloc] initWithTitle:@"笔记" action:@selector(note:)];
    menuController.menuItems = @[noteItem, saveItems];
    if (@available(iOS 13.0, *)) {
        [menuController showMenuFromView:self.view rect:self.titleLabel.frame];
    } else {
        [menuController setTargetRect:self.titleLabel.frame inView:self.view];
        [menuController setMenuVisible:YES animated:YES];
    }
}

// 隐藏菜单UIMenuController
- (void)menuViewDidHide:(NSNotification*)notification {
    self.textView.overrideNextResponder = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

@end
