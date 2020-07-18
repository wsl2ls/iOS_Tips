//
//  SLZombieFinder.m
//  DarkMode
//
//  Created by wsl on 2020/5/8.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLZombieFinder.h"
#import "SLZombieCatcher.h"
#import <objc/runtime.h>
#import "SLCrashProtector.h"

typedef void (*SLDeallocPointer) (id obj);  ///指向Dealloc实现IMP的指针
static BOOL _enabled = NO;     //嗅探器是否已开启
static NSArray *_rootClasses = nil;   //根/基类
static NSDictionary<id, NSValue *> *_rootClassDeallocImps = nil;  //存储根类Dealloc的方法实现IMP
static BOOL isOnlySnifferMyClass = NO;  ///是否仅嗅探自己创建的类  默认NO

/// 嗅探/延迟释放实例的白名单类，不对在此名单中的类进行僵尸对象嗅探/延迟释放
static inline NSMutableSet *sl_sniff_white_list() {
    static NSMutableSet *lxd_sniff_white_list;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lxd_sniff_white_list = [[NSMutableSet alloc] init];
        
        [lxd_sniff_white_list addObject:@"_UITextSizeCache"];
        [lxd_sniff_white_list addObject:@"NSConcreteValue"];
        [lxd_sniff_white_list addObject:@"SLZombieCatcher"];
        [lxd_sniff_white_list addObject:@"OS_dispatch_data"];
        
        [lxd_sniff_white_list addObject:@"__NSGlobalBlock__"];
        [lxd_sniff_white_list addObject:@"__NSStackBlock__ "];
        [lxd_sniff_white_list addObject:@"__NSMallocBlock__"];
        [lxd_sniff_white_list addObject:@"NSBlock"];
        [lxd_sniff_white_list addObject:@"NSValue"];
        
    });
    return lxd_sniff_white_list;
}
///释放实例
static inline void sl_dealloc(__unsafe_unretained id obj) {
    Class currentCls = [obj class];
    Class rootCls = currentCls;
    
    while (rootCls != [NSObject class] && rootCls != [NSProxy class]) {
        rootCls = class_getSuperclass(rootCls);
    }
    NSString *clsName = NSStringFromClass(rootCls);
    SLDeallocPointer deallocImp = NULL;
    [[_rootClassDeallocImps objectForKey: clsName] getValue: &deallocImp];
    
    if (deallocImp != NULL) {
        deallocImp(obj);
    }
}
///交换IMP，并返回method的原始IMP
static inline IMP sl_swizzleMethodWithBlock(Method method, void *block) {
    IMP blockImplementation = imp_implementationWithBlock(block);
    return method_setImplementation(method, blockImplementation);
}


@implementation SLZombieFinder

+ (void)initialize {
    _rootClasses = [@[[NSObject class], [NSProxy class]] retain];
}

#pragma mark - Public
+ (void)startSniffer {
    @synchronized(self) {
        if (!_enabled) {
            [self _swizzleDealloc];
            _enabled = YES;
        }
    }
}
+ (void)closeSniffer {
    @synchronized(self) {
        if (_enabled) {
            [self _unswizzleDealloc];
            _enabled = NO;
        }
    }
}
+ (void)appendIgnoreClass: (Class)cls {
    @synchronized(self) {
        NSMutableSet *whiteList = sl_sniff_white_list();
        NSString *clsName = NSStringFromClass(cls);
        [clsName retain];
        [whiteList addObject: clsName];
    }
}

#pragma mark - Private
///hook基类NSObject/NSProxy的dealloc方法，并指向swizzledDeallocBlock对应的IMP
+ (void)_swizzleDealloc {
    static void *swizzledDeallocBlock = NULL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ///NSObject/NSProxy的dealloc交换后的方法实现
        swizzledDeallocBlock = [^void(id obj) {
            Class currentClass = [obj class];
            NSString *clsName = NSStringFromClass(currentClass);
            //_UITextSizeCache 这个私有类的实例对象在dispatch_after里释放会崩溃，故排除
            if ([sl_sniff_white_list() containsObject:clsName] || [clsName hasPrefix:@"OS_xpc"] ||  [clsName hasPrefix:@"WK"]) {
                sl_dealloc(obj);
            } else {
                NSValue *objVal = [NSValue valueWithBytes: &obj objCType: @encode(typeof(obj))];
                ///动态转换obj对象的isa类对象为SLZombieCatcher，让SLZombieCatcher去捕获异常的消息并抛出异常
                object_setClass(obj, [SLZombieCatcher class]);
                ///保存原来的类
                ((SLZombieCatcher *)obj).originClass = currentClass;
                
                ///延迟5秒释放此obj对象内存空间，如果释放前，有新消息发送给此地址的对象(SLZombieCatcher)，就说明出现了野指针/坏内存访问
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    __unsafe_unretained id deallocObj = nil;
                    [objVal getValue: &deallocObj];
                    object_setClass(deallocObj, currentClass);
                    sl_dealloc(deallocObj);
                });
            }
        } copy];
    });
    
    NSMutableDictionary *deallocImps = [NSMutableDictionary dictionary];
    for (Class rootClass in _rootClasses) {
        //设置方法dealloc的实现IMP为swizzledDeallocBlock的方法实现IMP，并存储原有的dealloc的IMP，适当时机去执行
        IMP originalDeallocImp = sl_swizzleMethodWithBlock(class_getInstanceMethod(rootClass, @selector(dealloc)), swizzledDeallocBlock);
        [deallocImps setObject: [NSValue valueWithBytes: &originalDeallocImp objCType: @encode(typeof(IMP))] forKey: NSStringFromClass(rootClass)];
    }
    _rootClassDeallocImps = [deallocImps copy];
}

///恢复原来的IMP指向
+ (void)_unswizzleDealloc {
    [_rootClasses enumerateObjectsUsingBlock:^(Class rootClass, NSUInteger idx, BOOL *stop) {
        IMP originalDeallocImp = NULL;
        NSString *clsName = NSStringFromClass(rootClass);
        [[_rootClassDeallocImps objectForKey: clsName] getValue: &originalDeallocImp];
        
        NSParameterAssert(originalDeallocImp);
        method_setImplementation(class_getInstanceMethod(rootClass, @selector(dealloc)), originalDeallocImp);
    }];
    [_rootClassDeallocImps release];
    _rootClassDeallocImps = nil;
}

@end
