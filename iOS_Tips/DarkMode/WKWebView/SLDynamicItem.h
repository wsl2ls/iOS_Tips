//
//  SLDynamicItem.h
//  DarkMode
//
//  Created by wsl on 2020/5/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///动力元素  力的作用对象
@interface SLDynamicItem : NSObject <UIDynamicItem>
@property (nonatomic, readwrite) CGPoint center;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readwrite) CGAffineTransform transform;
@end

NS_ASSUME_NONNULL_END
