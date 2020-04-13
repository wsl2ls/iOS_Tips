//
//  SLCrashViewController.m
//  DarkMode
//
//  Created by wsl on 2020/4/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCrashViewController.h"
#import "NSArray+SLCrash.h"

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
    
    [self testDictionary];
}

#pragma mark - HelpMethods
//不可变数组防护 越界和nil值
- (void)testArray {
    //越界
    NSArray *array = @[@"且行且珍惜"];
    id elem1 = array[3];
    id elem2 = [array objectAtIndex:2];
    //nil值
    NSString *nilStr = nil;
    NSArray *array1 = @[nilStr];
    NSString *strings[2];
    strings[0] = @"wsl";
    strings[1] = nilStr;
    NSArray *array2 = [NSArray arrayWithObjects:strings count:2];
    NSArray *array3 = [NSArray arrayWithObject:nil];
}
//可变数组防护 越界和nil值
- (void)testMutableArray {
    //越界
    NSMutableArray *mArray = [NSMutableArray array];
    [mArray objectAtIndex:2];
    id nilObj = mArray[2];
    [mArray insertObject:@"wsl" atIndex:1];
    [mArray removeObjectAtIndex:3];
    [mArray insertObjects:@[@"w",@"s",@"l"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(5, 3)]];
    [mArray replaceObjectAtIndex:5 withObject:@"wsl"];
    [mArray replaceObjectAtIndex:5 withObject:nil];
    [mArray replaceObjectsInRange:NSMakeRange(5, 3) withObjectsFromArray:@[@"w",@"s",@"l"]];
    //nil值
    [mArray insertObject:nil atIndex:3];
    NSMutableArray *mArray1 = [NSMutableArray arrayWithObject:nil];
    NSMutableArray *mArray2 = [NSMutableArray arrayWithObject:@[nilObj]];
    [mArray addObject:nilObj];
}

//不可变字典防护 nil值
- (void)testDictionary {
    NSString *value = nil;
    NSString *key = nil;
    NSDictionary *dic = @{@"key":value};
    dic = @{key:@"value"};
    [NSDictionary dictionaryWithObject:@"value" forKey:key];
    [NSDictionary dictionaryWithObject:value forKey:@"key"];
    [NSDictionary dictionaryWithObjects:@[@"w",@"s",@"l"] forKeys:@[@"1",@"2",key]];
}

#pragma mark - EventsHandle



@end
