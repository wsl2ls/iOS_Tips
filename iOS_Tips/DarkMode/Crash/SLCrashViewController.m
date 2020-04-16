//
//  SLCrashViewController.m
//  DarkMode
//
//  Created by wsl on 2020/4/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCrashViewController.h"

@interface SLCrashViewController ()

//未实现的实例方法
- (id)undefineInstanceMethodTest:(id)sender;
//未实现的类方法
+ (id)undefineClassMethodTest:(id)sender;

@end

@implementation SLCrashViewController


#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)dealloc {
     NSLog(@"SLCrashViewController 释放");
}

#pragma mark - UI
- (void)setupUI {
    self.navigationItem.title = @"iOS Crash防护";
    
    [self testKVO];
}

#pragma mark - Container Crash

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
    NSString *nilValue = nil;
    NSString *nilKey = nil;
    NSDictionary *dic = @{@"key":nilValue};
    dic = @{nilKey:@"value"};
    [NSDictionary dictionaryWithObject:@"value" forKey:nilKey];
    [NSDictionary dictionaryWithObject:nilValue forKey:@"key"];
    [NSDictionary dictionaryWithObjects:@[@"w",@"s",@"l"] forKeys:@[@"1",@"2",nilKey]];
}
//可变字典防护 nil值
- (void)testMutableDictionary {
    NSString *nilValue = nil;
    NSString *nilKey = nil;
    NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
    [mDict setValue:nilValue forKey:@"key"];
    [mDict setValue:@"value" forKey:nilKey];
    [mDict setValue:nilValue forKey:nilKey];
    [mDict removeObjectForKey:nilKey];
    mDict[nilKey] = nilValue;
    NSMutableDictionary *mDict1 = [NSMutableDictionary dictionaryWithDictionary:@{nilKey:nilValue}];
}

//不可变字符串防护
- (void)testString {
    NSString *string = @"wsl2ls";
    [string characterAtIndex:10];
    [string substringFromIndex:20];
    [string substringToIndex:20];
    [string substringWithRange:NSMakeRange(10, 10)];
    [string substringWithRange:NSMakeRange(2, 10)];
}
//可变字符串防护
- (void)testMutableString {
    NSMutableString *stringM = [NSMutableString stringWithFormat:@"wsl2ls"];
    stringM = [NSMutableString stringWithFormat:@"wsl"];
    [stringM insertString:@"😍" atIndex:10];
    
    stringM = [NSMutableString stringWithFormat:@"2"];
    [stringM deleteCharactersInRange:NSMakeRange(2, 20)];
    
    stringM = [NSMutableString stringWithFormat:@"ls"];
    [stringM deleteCharactersInRange:NSMakeRange(10, 10)];
}

#pragma mark - Unrecognized Selector
// 测试未识别方法 crash防护
- (void)testUnrecognizedSelector {
    UIButton *testButton = [[UIButton alloc] init];
    [testButton performSelector:@selector(undefineButtonMethodTest:)];
    //未定义、未实现的实例方法
    [self performSelector:@selector(undefineInstanceMethodTest:)];
    //未定义、未实现的类方法
    [[self class] performSelector:@selector(undefineClassMethodTest:)];
}

#pragma mark - KVO
// 测试KVO防护
- (void)testKVO {
    
//    [self addObserver:self forKeyPath:@"title1" options:NSKeyValueObservingOptionNew context:nil];
    
    [self removeObserver:self forKeyPath:@"title"];
    
}

#pragma mark - KVC
// 测试KVC防护
- (void)testKVC {
    
    
    
    
    
    
}

#pragma mark - NSNotification
// 测试NSNotification防护
- (void)testNotification {
    
    
    
    
    
    
}

@end
