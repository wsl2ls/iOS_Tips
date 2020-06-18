//
//  NSDictionary+SLExtension.m
//  
//
//  Created by wsl on 2020/6/18.
//  Copyright © 2020 wsl. All rights reserved.
//

#import "NSDictionary+SLExtension.h"

@implementation NSDictionary (SLExtension)

///value 为NSString
- (NSString *)sl_decodeStringFormDictWithKey:(NSString *)key {
    NSString *string = @"";
    if (self && [self isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)self;
        if ([dict[key] isKindOfClass:[NSString class]]) {
            string = dict[key];
        }
        else if ([dict[key] isKindOfClass:[NSNumber class]]) {
            string = [dict[key] stringValue];
        }
    }
    return string;
}
///value 为NSArray
- (NSArray *)sl_decodeArrayFormDictWithKey:(NSString *)key {
    
    NSArray *array = [NSArray array];
    if (self && [self isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)self;
        if ([dict[key] isKindOfClass:[NSArray class]]) {
            array = dict[key];
        }
    }
    return array;
}
///容错处理 value 为NSDictionary
- (NSDictionary *)sl_decodeDictionaryFormDictWithKey:(NSString *)key {
    NSDictionary *dictionary = [NSDictionary dictionary];
    if (self && [self isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)self;
        if ([dict[key] isKindOfClass:[NSDictionary class]]) {
            dictionary = dict[key];
        }
    }
    return dictionary;
}
@end
