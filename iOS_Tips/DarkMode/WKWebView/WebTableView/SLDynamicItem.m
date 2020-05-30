//
//  SLDynamicItem.m
//  DarkMode
//
//  Created by wsl on 2020/5/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLDynamicItem.h"

@implementation SLDynamicItem
- (instancetype)init {
    self = [super init];
    if (self) {
        _bounds = CGRectMake(0, 0, 1, 1);
    }
    return self;
}
@end
