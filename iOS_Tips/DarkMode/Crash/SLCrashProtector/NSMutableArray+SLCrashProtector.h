//
//  NSMutableArray+Crash.h
//  DarkMode
//
//  Created by wsl on 2020/4/12.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 可变数组 越界、nil值 Crash防护
@interface NSMutableArray (SLCrashProtector)

@end

NS_ASSUME_NONNULL_END
