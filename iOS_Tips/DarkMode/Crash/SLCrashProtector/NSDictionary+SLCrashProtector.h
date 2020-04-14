//
//  NSDictionary+SLCrash.h
//  DarkMode
//
//  Created by wsl on 2020/4/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 不可变字典 越界、nil值 Crash防护
@interface NSDictionary (SLCrashProtector)

@end

NS_ASSUME_NONNULL_END
