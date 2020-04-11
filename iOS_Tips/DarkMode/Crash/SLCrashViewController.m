//
//  SLCrashViewController.m
//  DarkMode
//
//  Created by wsl on 2020/4/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCrashViewController.h"
#import "NSArray+Crash.h"

@interface SLCrashViewController ()

@end

@implementation SLCrashViewController


#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    self.navigationItem.title = @"iOS Crash防护";
    
    [self testArray];
}

#pragma mark - HelpMethods
//数组防护
- (void)testArray {
    NSArray *array = @[@"哈哈", @"hh"];
//    id elem1 = array.lastObject;
//    id elem2 = array[2];
    id elem3 = [array objectAtIndex:2];
}

#pragma mark - EventsHandle



@end
