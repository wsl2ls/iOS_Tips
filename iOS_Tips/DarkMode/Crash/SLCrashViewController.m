//
//  SLCrashViewController.m
//  DarkMode
//
//  Created by wsl on 2020/4/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCrashViewController.h"
#import "SLCrashProtector.h"
#import "BSBacktraceLogger.h"

/*
 参考资料：
 https://www.jianshu.com/p/29051908c74b  iOS Crash分析
 https://juejin.im/post/5d81fac66fb9a06af7126a44  iOS获取任意线程调用栈
 https://blog.csdn.net/jasonblog/article/details/49909209  iOS中线程Call Stack的捕获和解析（二）
 https://www.jianshu.com/p/b5304d3412e4  iOS app崩溃捕获
 https://www.jianshu.com/p/8d43b4b47913  Crash产生原因
 https://developer.aliyun.com/article/499180 iOS Mach异常和signal信号
 */
@interface SLCrashViewController ()<SLCrashHandlerDelegate>

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, copy) void(^testBlock)(void); //测试循环引用
@property (nonatomic, strong) NSMutableArray *testMArray; //测试循环引用

//未实现的实例方法
- (id)undefineInstanceMethodTest:(id)sender;
//未实现的类方法
+ (id)undefineClassMethodTest:(id)sender;

@end

@implementation SLCrashViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    self.navigationItem.title = @"iOS Crash防护";
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSArray *methods = @[@"testArray",
                         @"testMutableArray",
                         @"testDictionary",
                         @"testMutableDictionary",
                         @"testString",
                         @"testMutableString",
                         @"testUnrecognizedSelector",
                         @"testKVO",
                         @"testKVC",
                         @"testAsynUpdateUI",
                         @"testWildPointer",
                         @"testMemoryLeak"];
    NSArray *titles = @[@"数组越界、空值",
                        @"可变数组越界、空值",
                        @"字典越界、空值",
                        @"可变字典越界、空值",
                        @"字符串越界、空值",
                        @"可变字符串越界、空值",
                        @"未实现方法",
                        @"KVO",
                        @"KVC",
                        @"异步刷新UI",
                        @"野指针",
                        @"内存泄漏/循环引用"];
    CGSize size = CGSizeMake(self.view.sl_width/4.0, 66);
    int i = 0;
    for (NSString *method in methods) {
        UIButton *testBtn = [[UIButton alloc] initWithFrame:CGRectMake(i%4*size.width, SL_TopNavigationBarHeight+ i/4*size.height, size.width, size.height)];
        [testBtn setTitle:titles[i] forState:UIControlStateNormal];
        testBtn.backgroundColor = UIColor.orangeColor;
        testBtn.titleLabel.numberOfLines = 0;
        testBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        testBtn.layer.borderColor = [UIColor blackColor].CGColor;
        testBtn.layer.borderWidth = 1.0;
        [testBtn addTarget:self action:NSSelectorFromString(method) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:testBtn];
        i++;
    }
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, SL_TopNavigationBarHeight+ i/4*size.height, self.view.sl_width, self.view.sl_height - (SL_TopNavigationBarHeight+ i/4*size.height))];
    self.textView.editable = NO;
    self.textView.text = @"点击上方测试内容按钮，在此输出异常捕获结果...";
    [self.view addSubview:self.textView];
    
    [SLCrashHandler defaultCrashHandler].delegate = self;
    
}

#pragma mark - SLCrashHandlerDelegate
///异常捕获回调 提供给外界实现自定义处理 ，日志上报等（注意线程安全）
- (void)crashHandlerDidOutputCrashError:(SLCrashError *)crashError {
    NSString *errorInfo = [NSString stringWithFormat:@" 错误描述：%@ \n 调用栈：%@" ,crashError.errorDesc, crashError.callStackSymbol];
    
    SL_DISPATCH_ON_MAIN_THREAD((^{
        [self.textView scrollsToTop];
        self.textView.text = errorInfo;
    }));
    ///日志写入缓存，适当时机上传后台
    NSString *logPath = [SL_CachesDir stringByAppendingFormat:@"/com.wsl2ls.CrashLog"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:[logPath stringByAppendingFormat:@"/log"]]) {
        NSError *error;
        [errorInfo writeToFile:[logPath stringByAppendingFormat:@"/log"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }else {
        NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:[logPath stringByAppendingFormat:@"/log"]];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[errorInfo dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
    
    //调试模式时，强制抛出异常，提醒开发者代码有问题
    #if DEBUG
//        @throw crashError.exception;
    #endif
    
}

#pragma mark - Container Crash
///思路来源： https://xiaozhuanlan.com/topic/6280793154
///不可变数组防护 越界和nil值
- (void)testArray {
    //越界
    NSArray *array = @[@"且行且珍惜"];
    id elem1 = array[3];
    id elem2 = [array objectAtIndex:2];
    //nil值
    NSString *nilStr = nil;
    NSArray *array1 = @[nilStr];
    NSString *strings[2];
    strings[0] = @"wsl";
    strings[1] = nilStr;
    NSArray *array2 = [NSArray arrayWithObjects:strings count:2];
    NSArray *array3 = [NSArray arrayWithObject:nil];
}
///可变数组防护 越界和nil值
- (void)testMutableArray {
    //越界
    NSMutableArray *mArray = [NSMutableArray array];
    [mArray objectAtIndex:2];
    id nilObj = mArray[2];
    [mArray insertObject:@"wsl" atIndex:1];
    [mArray removeObjectAtIndex:3];
    [mArray insertObjects:@[@"w",@"s",@"l"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(5, 3)]];
    [mArray replaceObjectAtIndex:5 withObject:@"wsl"];
    [mArray replaceObjectAtIndex:5 withObject:nil];
    [mArray replaceObjectsInRange:NSMakeRange(5, 3) withObjectsFromArray:@[@"w",@"s",@"l"]];
    //nil值
    [mArray insertObject:nil atIndex:3];
    NSMutableArray *mArray1 = [NSMutableArray arrayWithObject:nil];
    NSMutableArray *mArray2 = [NSMutableArray arrayWithObject:@[nilObj]];
    [mArray addObject:nilObj];
    
}

///不可变字典防护 nil值
- (void)testDictionary {
    NSString *nilValue = nil;
    NSString *nilKey = nil;
    NSDictionary *dic = @{@"key":nilValue};
    dic = @{nilKey:@"value"};
    [NSDictionary dictionaryWithObject:@"value" forKey:nilKey];
    [NSDictionary dictionaryWithObject:nilValue forKey:@"key"];
    [NSDictionary dictionaryWithObjects:@[@"w",@"s",@"l"] forKeys:@[@"1",@"2",nilKey]];
}
///可变字典防护 nil值
- (void)testMutableDictionary {
    NSString *nilValue = nil;
    NSString *nilKey = nil;
    NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
    [mDict setValue:nilValue forKey:@"key"];
    [mDict setValue:@"value" forKey:nilKey];
    [mDict setValue:nilValue forKey:nilKey];
    [mDict removeObjectForKey:nilKey];
    mDict[nilKey] = nilValue;
    NSMutableDictionary *mDict1 = [NSMutableDictionary dictionaryWithDictionary:@{nilKey:nilValue}];
}

///不可变字符串防护
- (void)testString {
    NSString *string = @"wsl2ls";
    [string characterAtIndex:10];
    [string substringFromIndex:20];
    [string substringToIndex:20];
    [string substringWithRange:NSMakeRange(10, 10)];
    [string substringWithRange:NSMakeRange(2, 10)];
}
///可变字符串防护
- (void)testMutableString {
    NSMutableString *stringM = [NSMutableString stringWithFormat:@"wsl2ls"];
    stringM = [NSMutableString stringWithFormat:@"wsl"];
    [stringM insertString:@"😍" atIndex:10];
    
    stringM = [NSMutableString stringWithFormat:@"2"];
    [stringM deleteCharactersInRange:NSMakeRange(2, 20)];
    
    stringM = [NSMutableString stringWithFormat:@"ls"];
    [stringM deleteCharactersInRange:NSMakeRange(10, 10)];
}

#pragma mark - Unrecognized Selector
/// 测试未识别方法 crash防护
- (void)testUnrecognizedSelector {
    //未定义、未实现的实例方法
    [self performSelector:@selector(undefineInstanceMethodTest:)];
    //未定义、未实现的类方法
    [[self class] performSelector:@selector(undefineClassMethodTest:)];
}

#pragma mark - KVO
/// 测试KVO防护
- (void)testKVO {
    //被观察对象提前释放 导致Crash
    UILabel *label = [[UILabel alloc] init];
    [label addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
    //没有移除观察者
    [self addObserver:self forKeyPath:@"view" options:NSKeyValueObservingOptionNew context:nil];
    
    [self addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    //重复移除 导致Crash
    [self removeObserver:self forKeyPath:@"title"];
    [self removeObserver:self forKeyPath:@"title" context:nil];
    //移除未注册的观察者
    [self removeObserver:self forKeyPath:@"modalTransitionStyle"];
}

#pragma mark - KVC
/// 测试KVC防护
- (void)testKVC {
    NSString *nilKey = nil;
    NSString *nilValue = nil;
    //    key 为nil
    [self setValue:@"wsl" forKey:nilKey];
    //    Value 为nil
    [self setValue:nilValue forKey:@"name"];
    //     key 不是对象的属性
    [self setValue:@"wsl" forKey:@"noProperty"];
    [self setValue:@"wsl" forKeyPath:@"self.noProperty"];
}

#pragma mark - 异步刷新UI
///异步刷新UI
- (void)testAsynUpdateUI {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UILabel* newView = [[UILabel alloc] initWithFrame:CGRectMake(0,0,150, 88)];
        newView.center = CGPointMake(self.view.sl_width/2.0, self.view.sl_height/2.0);
        newView.backgroundColor = [UIColor greenColor];
        newView.text = @"异步刷新UI";
        [self.view addSubview:newView];
        [SLDelayPerform sl_startDelayPerform:^{
            [newView removeFromSuperview];
        } afterDelay:2.0];
    });
}

#pragma mark - 野指针
///野指针  随机性太强，不方便复现和定位问题，我们需要做的就是把随机变为必现，并且定位到对应的代码，方便查找解决
///思路来源： https://www.jianshu.com/p/9fd4dc046046?utm_source=oschina-app
- (void)testWildPointer {
    //开启僵尸对象嗅探定位 可以打开或关闭此开关看看效果就知道了
    // 目前还不完善，不推荐使用 ，仅做交流学习
    [SLZombieFinder startSniffer];
    
    
    UILabel *label = [[UILabel alloc] init];
    //-fno-objc-arc 记得设置此类编译方式支持MRC
    //testObj对象所在的内存空间已释放
    [label release];
    
    //这时新建一个示例对象，覆盖掉了野指针label所指向的内存空间，如果此时没有创建此同类，就会崩溃
    UILabel* newView = [[UILabel alloc] initWithFrame:CGRectMake(0,SL_kScreenHeight- 60,SL_kScreenWidth, 60)];
    newView.backgroundColor = [UIColor greenColor];
    newView.text = @"startSniffer开启 显示正常";
    [self.view addSubview:newView];
    
    //向野指针label指向的内存对象发送修改颜色的消息，结果是newView接收到了，因为newView和label是同类，可以处理此消息,所以没有崩溃； 在不开启startSniffer时，就把newView的backgroundColor修改了，开启startSniffer后，阻断了向野指针发消息的过程
    label.backgroundColor = [UIColor orangeColor];
    label.text = @"startSniffer关闭 我是野指针，显示错误";
    
    
    [SLDelayPerform sl_startDelayPerform:^{
        [newView removeFromSuperview];
    } afterDelay:2.0];
    
}

#pragma mark - 内存泄漏/循环引用
///测试是否内存泄漏/循环引用
//思路来源：https://github.com/Tencent/MLeaksFinder.git
//查找循引用连 FBRetainCycleDetector  https://yq.aliyun.com/articles/66857  、 https://blog.csdn.net/majiakun1/article/details/78747226
- (void)testMemoryLeak {
    
    //执行此方法后，返回上一级界面，发现SLCrashViewController对象没释放
    self.testBlock = ^{
        self;
    };
    //        self.testMArray = [[NSMutableArray alloc] initWithObjects:self, nil];
}

#pragma mark - 获取函数调用栈
///获取任意线程的函数调用栈  https://toutiao.io/posts/aveig6/preview
- (void)testCallStack {
    //打印当前线程调用栈
    BSLOG;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //在子线程中 打印主线程调用栈，会发现栈基本是空的，因为都已释放了
        //           BSLOG_MAIN
        //        BSLOG;
    });
    //    BSLOG_MAIN
}

@end
