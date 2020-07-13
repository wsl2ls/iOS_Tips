//
//  SLAPMGpu.h
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///GPU占有率监听
@interface SLAPMGpu : NSObject
///返回GPU使用情况 占有率
+ (double)getCpuUsage;
@end

NS_ASSUME_NONNULL_END
