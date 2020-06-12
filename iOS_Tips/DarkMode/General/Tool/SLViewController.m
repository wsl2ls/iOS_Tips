//
//  SLViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/12.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLViewController.h"

@interface SLViewController ()

@end

@implementation SLViewController
- (void)dealloc {
    NSLog(@"%@释放了",NSStringFromClass(self.class));
}
@end
