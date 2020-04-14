//
//  NSMutableString+SLCrashProtector.m
//  DarkMode
//
//  Created by wsl on 2020/4/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSMutableString+SLCrashProtector.h"
#import "SLCrashProtector.h"

@implementation NSMutableString (SLCrashProtector)

+ (void)load {
    [super load];
    //越界防护
    Class stringClass = NSClassFromString(@"__NSCFString");
    SL_ExchangeInstanceMethod(stringClass, @selector(insertString:atIndex:), stringClass, @selector(sl_insertString:atIndex:));
    SL_ExchangeInstanceMethod(stringClass, @selector(deleteCharactersInRange:), stringClass, @selector(sl_deleteCharactersInRange:));
}

#pragma mark - NSMutableString Safe Methods

- (void)sl_insertString:(NSString *)aString atIndex:(NSUInteger)loc{
    if (loc > self.length) {
        @try {
            [self sl_insertString:aString atIndex:loc];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:MutableString越界 %@", exception.reason);
        }
    }else{
        [self sl_insertString:aString atIndex:loc];
    }
}

- (void)sl_deleteCharactersInRange:(NSRange)range{
    if (range.location+range.length > self.length) {
        @try {
            [self sl_deleteCharactersInRange:range];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:MutableString越界 %@", exception.reason);
        }
        if (range.location < self.length) {
            [self sl_deleteCharactersInRange:NSMakeRange(range.location, self.length-range.location)];
        }
    }else{
        [self sl_deleteCharactersInRange:range];
    }
}

@end
