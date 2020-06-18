//
//  NSDictionary+SLExtension.h
//
//
//  Created by wsl on 2020/6/18.
//  Copyright © 2020 wsl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (SLExtension)

///容错处理 value 应为NSString
- (NSString *)decodeStringFormDictWithKey:(NSString *)key;
///容错处理 value 为NSArray
- (NSArray *)decodeArrayFormDictWithKey:(NSString *)key;
///容错处理 value 为NSDictionary
- (NSDictionary *)decodeDictionaryFormDictWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
