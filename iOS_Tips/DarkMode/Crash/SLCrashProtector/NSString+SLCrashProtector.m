//
//  NSString+SLCrashProtector.m
//  DarkMode
//
//  Created by wsl on 2020/4/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSString+SLCrashProtector.h"
#import "SLCrashProtector.h"

@implementation NSString (SLCrashProtector)

+ (void)load {
    [super load];
    
    Class stringClass = NSClassFromString(@"__NSCFConstantString");
    SL_ExchangeInstanceMethod(stringClass, @selector(characterAtIndex:), stringClass, @selector(sl_characterAtIndex:));
    SL_ExchangeInstanceMethod(stringClass, @selector(substringFromIndex:), stringClass, @selector(sl_substringFromIndex:));
    SL_ExchangeInstanceMethod(stringClass, @selector(substringToIndex:), stringClass, @selector(sl_substringToIndex:));
    SL_ExchangeInstanceMethod(stringClass, @selector(substringWithRange:), stringClass, @selector(sl_substringWithRange:));
    
}

#pragma mark - NSString Safe Methods

- (unichar)sl_characterAtIndex:(NSUInteger)index{
    if (index>=self.length) {
        unichar characteristic = 0;
        NSString *errorInfo = @"*** -[__NSCFConstantString characterAtIndex:]: Range or index out of bounds";
        //        BMP_Container_ErrorHandler(BMPErrorString_Beyond, errorInfo);
        return characteristic;
    }
    return [self sl_characterAtIndex:index];
}

- (NSString *)sl_substringFromIndex:(NSUInteger)from{
    id instance = nil;
    @try {
        instance = [self sl_substringFromIndex:from];
    }
    @catch (NSException *exception) {
        NSString *errorInfo = [NSString stringWithFormat:@"*** -[__NSCFConstantString substringFromIndex:]: Index %ld out of bounds; string length %ld",(unsigned long)from,(unsigned long)self.length];
        //        BMP_Container_ErrorHandler(BMPErrorString_Beyond, errorInfo);
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
        NSString *errorInfo = [NSString stringWithFormat:@"*** -[__NSCFConstantString substringToIndex:]: Index %ld out of bounds; string length %ld",(unsigned long)to,(unsigned long)self.length];
        //        BMP_Container_ErrorHandler(BMPErrorString_Beyond, errorInfo);
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
        NSString *errorInfo = [NSString stringWithFormat:@"*** -[__NSCFConstantString BMP_substringWithRange:]: Range {%ld, %ld} out of bounds; string length %ld",(unsigned long)range.location,(unsigned long)range.length,(unsigned long)self.length];
        //        BMP_Container_ErrorHandler(BMPErrorString_Beyond, errorInfo);
    }
    @finally {
        return instance;
    }
}

@end
