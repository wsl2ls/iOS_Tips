//
//  NSString+SLCrashProtector.m
//  DarkMode
//
//  Created by wsl on 2020/4/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSString+SLCrashProtector.h"
#import "SLCrashProtector.h"

@implementation NSString (SLCrashProtector)

+ (void)load {
    [super load];
    //越界防护
    Class stringClass = NSClassFromString(@"__NSCFConstantString");
    SL_ExchangeInstanceMethod(stringClass, @selector(characterAtIndex:), stringClass, @selector(sl_characterAtIndex:));
    SL_ExchangeInstanceMethod(stringClass, @selector(substringFromIndex:), stringClass, @selector(sl_substringFromIndex:));
    SL_ExchangeInstanceMethod(stringClass, @selector(substringToIndex:), stringClass, @selector(sl_substringToIndex:));
    SL_ExchangeInstanceMethod(stringClass, @selector(substringWithRange:), stringClass, @selector(sl_substringWithRange:));
}

#pragma mark - NSString Safe Methods

- (unichar)sl_characterAtIndex:(NSUInteger)index{
    if (index>=self.length) {
        @try {
            [self sl_characterAtIndex:index];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:String越界 %@", exception.reason);
        }
        return 0;
    }
    return [self sl_characterAtIndex:index];
}

- (NSString *)sl_substringFromIndex:(NSUInteger)from{
    id instance = nil;
    @try {
        instance = [self sl_substringFromIndex:from];
    }
    @catch (NSException *exception) {
        NSLog(@"异常:String越界 %@", exception.reason);
    }
    @finally {
        return instance;
    }
}

- (NSString *)sl_substringToIndex:(NSUInteger)to{
    id instance = nil;
    @try {
        instance = [self sl_substringToIndex:to];
    }
    @catch (NSException *exception) {
        NSLog(@"异常:String越界 %@", exception.reason);
    }
    @finally {
        return instance;
    }
}

- (NSString *)sl_substringWithRange:(NSRange)range{
    id instance = nil;
    @try {
        instance = [self sl_substringWithRange:range];
    }
    @catch (NSException *exception) {
        NSLog(@"异常:String越界 %@", exception.reason);
    }
    @finally {
        return instance;
    }
}


@end
