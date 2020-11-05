// The MIT License (MIT)
//
// Copyright (c) 2020 Huimao Chen
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// GCC_C_LANGUAGE_STANDARD = gnu99

#ifndef HMLog_h
#define HMLog_h

#import <UIKit/UIKit.h>

#pragma mark - Parameters

// All optional parameters should be defined before import "HMLog.h", or you can modify the source code

#ifndef HMLogEnable
#define HMLogEnable 1
#endif  // HMLogEnable

#ifndef HMPrintEnable
#define HMPrintEnable 1
#endif  // HMPrintEnable

#ifndef HMLogPrefix
#define HMLogPrefix(index, valueString) [NSString stringWithFormat:@"%d: %s = ", index, valueString]
#endif  // HMLogPrefix

#ifndef HMLogHeaderFormatString
#define HMLogHeaderFormatString(FUNC, LINE) \
        [NSString stringWithFormat:@"================  %s [%d]  ================\n", FUNC, LINE]
#endif  // HMLogHeaderFormatString

#ifndef HMLogTypeExtension
#define HMLogTypeExtension
#endif  // HMLogTypeExtension

#pragma mark - Core

// format, private macro
#define _HMLogFormat(VAR) \
        , HMStringify(VAR), @encode(__typeof__(VAR)), (VAR)

// HMFormatString
#define HMFormatString(...) \
        HMExpand(_HMFormatString(__func__, __LINE__, HMArgCount(__VA_ARGS__) HMForeach(_HMLogFormat, __VA_ARGS__)))

// HMLog
#if HMLogEnable
    #define HMLog(...) \
            _HMLog(HMFormatString(__VA_ARGS__))
#else
    #define HMLog(...)
#endif  //  HMLogEnable

// HMPrint
#if HMPrintEnable
    #define HMPrint(...) \
            _HMPrint(HMFormatString(__VA_ARGS__))
#else
    #define HMPrint(...)
#endif  //  HMPrintEnable


static inline NSString * _HMFormatString(const char *func, int line, int count, ...) { //  func, line, count, [valueString, TypeEncode, value]
    NSMutableString *result = [[NSMutableString alloc] init];
    
    //  handle header
    [result appendString:HMLogHeaderFormatString(func, line)];
    
    // handle arguments
    va_list v;
    va_start(v, count);
    for (int i = 0; i < count; ++i) {
        char *valueString = va_arg(v, char *);
        char *type = va_arg(v, char *);
        
        id obj = nil;
        if (strcmp(type, @encode(id)) == 0) {   //  "@"   id
            id actual = va_arg(v, id);
            obj = actual;
            
        } else if (strcmp(type, @encode(CGPoint)) == 0) {           //  "{CGPoint=dd}"  CGPoint
            CGPoint actual = (CGPoint)va_arg(v, CGPoint);
            obj = [NSValue value:&actual withObjCType:type];
            
        } else if (strcmp(type, @encode(CGSize)) == 0) {            //  "{CGSize=dd}"   CGSize
            CGSize actual = (CGSize)va_arg(v, CGSize);
            obj = [NSValue value:&actual withObjCType:type];
            
        } else if (strcmp(type, @encode(CGRect)) == 0) {            //  "{CGRect={CGPoint=dd}{CGSize=dd}}"  CGRect
            CGRect actual = (CGRect)va_arg(v, CGRect);
            obj = [NSValue value:&actual withObjCType:type];
            
        } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {      //  "{UIEdgeInsets=dddd}"   UIEdgeInsets
            UIEdgeInsets actual = (UIEdgeInsets)va_arg(v, UIEdgeInsets);
            obj = NSStringFromUIEdgeInsets(actual);
            
        } else if (strcmp(type, @encode(NSRange)) == 0) {           //  "{_NSRange=QQ}" NSRange
            NSRange actual = (NSRange)va_arg(v, NSRange);
            obj = NSStringFromRange(actual);
            
        } else if (strcmp(type, @encode(SEL)) == 0) {               //  ":"     SEL
            SEL actual = (SEL)va_arg(v, SEL);
            obj = [NSString stringWithFormat:@"SEL: %@", NSStringFromSelector(actual)];
            
        } else if (strcmp(type, @encode(Class)) == 0) {             //  "#"     Class
            Class actual = (Class)va_arg(v, Class);
            obj = NSStringFromClass(actual);
            
        } else if (strcmp(type, @encode(char *)) == 0) {            //  "*"     char *
            char * actual = (char *)va_arg(v, char *);
            obj = [NSString stringWithFormat:@"%s", actual];
            
        } else if (strcmp(type, @encode(double)) == 0) {            //  "d"     double
            double actual = (double)va_arg(v, double);
            obj = [NSNumber numberWithDouble:actual];
            
        } else if (strcmp(type, @encode(float)) == 0) {             //  "f"     float
            float actual = (float)va_arg(v, double);
            obj = [NSNumber numberWithFloat:actual];
            
        } else if (strcmp(type, @encode(int)) == 0) {               //  "i"     int
            int actual = (int)va_arg(v, int);
            obj = [NSNumber numberWithInt:actual];
            
        } else if (strcmp(type, @encode(long)) == 0) {              //  "q"     long
            long actual = (long)va_arg(v, long);
            obj = [NSNumber numberWithLong:actual];
            
        } else if (strcmp(type, @encode(long long)) == 0) {         //  "q"     long long
            long long actual = (long long)va_arg(v, long long);
            obj = [NSNumber numberWithLongLong:actual];
            
        } else if (strcmp(type, @encode(short)) == 0) {             //  "s"     short
            short actual = (short)va_arg(v, int);
            obj = [NSNumber numberWithShort:actual];
            
        } else if (strcmp(type, @encode(char)) == 0) {              //  "c"     char & BOOL(32bit)
            char actual = (char)va_arg(v, int);
            obj = [NSString stringWithFormat:@"%d char:%c", actual, actual];
            
        } else if (strcmp(type, @encode(bool)) == 0) {              //  "B"     bool & BOOL(64bit)
            bool actual = (bool)va_arg(v, int);
            obj = actual ? @"YES" : @"NO";
            
        } else if (strcmp(type, @encode(unsigned char)) == 0) {             //  "C"     unsigned char
            unsigned char actual = (unsigned char)va_arg(v, unsigned int);
            obj = [NSString stringWithFormat:@"%d unsigned char:%c", actual, actual];
            
        } else if (strcmp(type, @encode(unsigned int)) == 0) {              //  "I"     unsigned int
            unsigned int actual = (unsigned int)va_arg(v, unsigned int);
            obj = [NSNumber numberWithUnsignedInt:actual];
            
        } else if (strcmp(type, @encode(unsigned long)) == 0) {             //  "Q"     unsigned long
            unsigned long actual = (unsigned long)va_arg(v, unsigned long);
            obj = [NSNumber numberWithUnsignedLong:actual];
            
        } else if (strcmp(type, @encode(unsigned long long)) == 0) {        //  "Q"     unsigned long long
            unsigned long long actual = (unsigned long long)va_arg(v, unsigned long long);
            obj = [NSNumber numberWithUnsignedLongLong:actual];
            
        } else if (strcmp(type, @encode(unsigned short)) == 0) {            //  "S"     unsigned short
            unsigned short actual = (unsigned short)va_arg(v, unsigned int);
            obj = [NSNumber numberWithUnsignedShort:actual];
            
        } HMLogTypeExtension else {
            [result appendString:@"Error: unknown type"];
            break;
        }
        
        [result appendFormat:@"%@%@\n", ((void)(valueString), HMLogPrefix(i, valueString)), obj];
    }
    va_end(v);
    
    return [result copy];
}

static inline void _HMLog(NSString *str) {
    NSLog(@"\n%@", str);
}

static inline void _HMPrint(NSString *str) {
    printf("%s\n", str.UTF8String);
}

#pragma mark - Helper

#define HMStringify(VALUE) _HMStringify(VALUE)
#define _HMStringify(VALUE) # VALUE

#define HMConcat(A, B) _HMConcat(A, B)
#define _HMConcat(A, B) A ## B

// Return the number of arguments (up to twenty) provided to the macro.
#define HMArgCount(...) _HMArgCount(A, ##__VA_ARGS__, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define _HMArgCount(A, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, COUNT, ...) COUNT

// If the number of arguments is 0, return 0, otherwise return N.
#define HMArgCheck(...) _HMArgCheck(A, ##__VA_ARGS__, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, 0)
#define _HMArgCheck(A, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, OBJ, ...) OBJ

// Each argument will be passed to the MACRO, the MACRO must be this form: MACRO(arg). Inspired by https://stackoverflow.com/questions/3136686/is-the-c99-preprocessor-turing-complete/10526117#10526117
#define HMForeach(MACRO, ...) HMConcat(_HMForeach, HMArgCheck(__VA_ARGS__)) (MACRO, ##__VA_ARGS__)
#define _HMForeach() HMForeach
#define _HMForeach0(MACRO)
#define _HMForeachN(MACRO, A, ...) MACRO(A) HMDefer(_HMForeach)() (MACRO, ##__VA_ARGS__)

#define HMEmpty()
#define HMDefer(ID) ID HMEmpty()

// For more scans
#define HMExpand(...)   _HMExpand1(_HMExpand1(_HMExpand1(__VA_ARGS__)))
#define _HMExpand1(...) _HMExpand2(_HMExpand2(_HMExpand2(__VA_ARGS__)))
#define _HMExpand2(...) _HMExpand3(_HMExpand3(_HMExpand3(__VA_ARGS__)))
#define _HMExpand3(...) __VA_ARGS__


#endif // HMLog_h
