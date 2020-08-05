//
//  UIViewController+SLAPMVCTime.m
//  DarkMode
//
//  Created by wsl on 2020/8/4.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "UIViewController+SLAPMVCTime.h"
#import <objc/runtime.h>

static char const kSLFakeKVORemoverKey;  //关联的对象Key
static char const kSLVCBeginDateKey; //vc开始加载时间的key

static NSString *const kSLFakeKeyPath = @"SL_FakeKeyPath";  //假冒的被观察属性key

///冒充KVO观察者，是为了生成观察目标的KVO子类
@interface SLFakeKVOObserver : NSObject
@end
@implementation SLFakeKVOObserver
+ (instancetype)shared {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
@end
///负责移除冒充的KVO观察者
@interface SLFakeKVORemover : NSObject
@property (nonatomic, weak) id target;  //被观察的目标
@end
@implementation SLFakeKVORemover
- (void)dealloc {
    [_target removeObserver:[SLFakeKVOObserver shared] forKeyPath:kSLFakeKeyPath];
}
@end

@implementation UIViewController (SLAPMVCTime)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [UIViewController class];
        if (![NSStringFromClass(class) hasPrefix:@"SL"]) {
            //仅仅测自己创建的VC
            return;
        }
        ///hook vc的初始化方法
        [self swizzleMethodInClass:class originalMethod:@selector(initWithNibName:bundle:) swizzledSelector:@selector(apm_initWithNibName:bundle:)];
        [self swizzleMethodInClass:class originalMethod:@selector(initWithCoder:) swizzledSelector:@selector(apm_initWithCoder:)];
    });
}
- (instancetype)apm_initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    [self createAndHookKVOClass];
    [self apm_initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
- (nullable instancetype)apm_initWithCoder:(NSCoder *)aDecoder {
    [self createAndHookKVOClass];
    [self apm_initWithCoder:aDecoder];
    return self;
}
///创建vc的KVO子类并hook子类的相关方法
- (void)createAndHookKVOClass {
    //设置KVO，会触发runtime来创建VC的KVO子类
    [self addObserver:[SLFakeKVOObserver shared] forKeyPath:kSLFakeKeyPath options:NSKeyValueObservingOptionNew context:nil];
    
    //保存观察目标VC，当VC实例释放时，移除KVO
    SLFakeKVORemover *remover = [[SLFakeKVORemover alloc] init];
    remover.target = self;
    objc_setAssociatedObject(self, &kSLFakeKVORemoverKey, remover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //获取VC的KVO子类 NSKVONotifying_ViewController
    Class kvoClass = object_getClass(self);
    
    //判断当前的IMP和我们的IMP在之前是否已hook
    IMP currentViewDidLoadImp = class_getMethodImplementation(kvoClass, @selector(viewDidLoad));
    if (currentViewDidLoadImp == (IMP)apm_viewDidLoad) {
        return;
    }
    
    //KVO子类的父类，即当前类，原来的类
    Class originCls = class_getSuperclass(kvoClass);
    
    // 获取原来实现的encoding
    const char *originLoadViewEncoding = method_getTypeEncoding(class_getInstanceMethod(originCls, @selector(loadView)));
    const char *originViewDidLoadEncoding = method_getTypeEncoding(class_getInstanceMethod(originCls, @selector(viewDidLoad)));
    const char *originViewWillAppearEncoding = method_getTypeEncoding(class_getInstanceMethod(originCls, @selector(viewWillAppear:)));
    const char *originViewDidAppearEncoding = method_getTypeEncoding(class_getInstanceMethod(originCls, @selector(viewDidAppear:)));
    
    // 添加方法，因为生成的KVO子类本身并没有实现loadView等方法，如果已实现了会添加失败。
    class_addMethod(kvoClass, @selector(loadView), (IMP)apm_loadView, originLoadViewEncoding);
    class_addMethod(kvoClass, @selector(viewDidLoad), (IMP)apm_viewDidLoad, originViewDidLoadEncoding);
    class_addMethod(kvoClass, @selector(viewWillAppear:), (IMP)apm_viewWillAppear, originViewWillAppearEncoding);
    class_addMethod(kvoClass, @selector(viewDidAppear:), (IMP)apm_viewDidAppear, originViewDidAppearEncoding);
}
///方法实现交换
+ (void)swizzleMethodInClass:(Class) class originalMethod:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#pragma mark - IMP of Hook
static void apm_loadView(UIViewController *kvo_self, SEL _sel) {
    IMP origin_imp = apm_originalMethodImplementation(kvo_self, _sel);
    void (*func)(UIViewController *, SEL) = (void (*)(UIViewController *, SEL))origin_imp;
    
    //记录开始加载的时间
    objc_setAssociatedObject(kvo_self, &kSLVCBeginDateKey, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //执行原来origin_cls的方法实现
    func(kvo_self, _sel);
}
static void apm_viewDidLoad(UIViewController *kvo_self, SEL _sel) {
    IMP origin_imp = apm_originalMethodImplementation(kvo_self, _sel);
    void (*func)(UIViewController *, SEL) = (void (*)(UIViewController *, SEL))origin_imp;
    func(kvo_self, _sel);
}
static void apm_viewWillAppear(UIViewController *kvo_self, SEL _sel, BOOL animated) {
    IMP origin_imp = apm_originalMethodImplementation(kvo_self, _sel);
    void (*func)(UIViewController *, SEL, BOOL) = (void (*)(UIViewController *, SEL, BOOL))origin_imp;
    func(kvo_self, _sel, animated);
}
static void apm_viewDidAppear(UIViewController *kvo_self, SEL _sel, BOOL animated) {
    IMP origin_imp = apm_originalMethodImplementation(kvo_self, _sel);
    void (*func)(UIViewController *, SEL, BOOL) = (void (*)(UIViewController *, SEL, BOOL))origin_imp;
    func(kvo_self, _sel, animated);
    
    NSDate *beginDate = objc_getAssociatedObject(kvo_self,  &kSLVCBeginDateKey);
    if (beginDate) {
        //计算方法耗时
        NSTimeInterval duration = -[beginDate timeIntervalSinceNow];
        NSLog(@"VC: %@ -loadView --> -viewDidAppear 用时: %f", [kvo_self class], duration);
    }
    //重置记录的开始时间
    objc_setAssociatedObject(kvo_self, &kSLVCBeginDateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

///返回原方法的IMP实现
static IMP apm_originalMethodImplementation(UIViewController *kvo_self, SEL _sel) {
    Class kvo_cls = object_getClass(kvo_self);
    Class origin_cls = class_getSuperclass(kvo_cls);
    IMP origin_imp = method_getImplementation(class_getInstanceMethod(origin_cls, _sel));
    assert(origin_imp != NULL);
    return origin_imp;
}

@end
