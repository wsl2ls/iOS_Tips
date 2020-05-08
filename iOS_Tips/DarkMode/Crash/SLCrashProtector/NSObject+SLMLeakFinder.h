//
//  NSObject+SLMLeakFinder.h
//  DarkMode
//
//  Created by wsl on 2020/5/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SLMLeakFinder)
///对象即将释放时调用此方法
- (BOOL)willDealloc;
@end

NS_ASSUME_NONNULL_END
