//
//  DarkModeTests.m
//  DarkModeTests
//
//  Created by wsl on 2019/9/16.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface DarkModeTests : XCTestCase

@end

@implementation DarkModeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureWithMetrics:@[[[XCTCPUMetric alloc] init]] block:^{
        // Put the code whose CPU performance you want to measure here.
    }];
}

@end
