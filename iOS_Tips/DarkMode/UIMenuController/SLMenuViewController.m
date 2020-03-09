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
-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(save:) ||
        action == @selector(note:) ||
        action == @selector(copy:)) {
        return YES;
    }
    return NO;
}
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
    self.title = @"键盘和UIMenuController的冲突问题";
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapShowMenuView:)];
    [self.titleLabel addGestureRecognizer:tapGestureRecognizer];
}

//点击显示菜单
- (void)tapShowMenuView:(UITapGestureRecognizer *)tap {
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    BOOL isFirstResponder = NO;
    if(self.textView.isFirstResponder){
        self.textView.overrideNextResponder = self.titleLabel;
        isFirstResponder = YES;
    }
    if(isFirstResponder){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuViewDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
    } else {
        [self.titleLabel becomeFirstResponder];
    }
    
    if (!menuController.menuVisible) {
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
}

- (void)menuViewDidHide:(NSNotification*)notification {
    self.textView.overrideNextResponder = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

@end
