//
//  SLBinaryResetViewController.m
//  DarkMode
//
//  Created by wsl on 2020/7/6.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLBinaryResetViewController.h"
#import <dlfcn.h>
#import <libkern/OSAtomic.h>

static BOOL isBecomeActive = NO;  //是否启动完成，即首页渲染完毕
@interface SLBinaryResetViewController ()
@property (nonatomic, strong) UITextView *textView;
@end

@implementation SLBinaryResetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.title = @"二进制重排优化启动时间";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"生成Order文件" style:UIBarButtonItemStyleDone target:self action:@selector(getOrderFile)];
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.editable = NO;
    [self.view addSubview:self.textView];
}
///获取启动加载时执行的排序后的所有函数符号，得到顺序执行的函数符号后，这些配置和clang插桩代码就可以删除了（除了Order File配置）
- (void)getOrderFile{
    NSMutableArray <NSString *> * symbolNames = [NSMutableArray array];
    while (YES) {
        //offsetof 就是针对某个结构体找到某个属性相对这个结构体的偏移量
        //出队，依次取出启动时执行的方法
        SLSymbolNode *node = OSAtomicDequeue(&symbolList, offsetof(SLSymbolNode, next));
        if (node == NULL) {
            break;
        }
        Dl_info info;
        dladdr(node->pc, &info);
        //根据内存地址获取函数名称
        NSString * name = @(info.dli_sname);
        BOOL  isObjc = [name hasPrefix:@"+["] || [name hasPrefix:@"-["];
        NSString * symbolName = isObjc ? name: [@"_" stringByAppendingString:name];
        [symbolNames addObject:symbolName];
        //        NSLog(@"%@",symbolName);
    }
    //取反
    NSEnumerator * emt = [symbolNames reverseObjectEnumerator];
    //去重
    NSMutableArray<NSString *> *funcs = [NSMutableArray arrayWithCapacity:symbolNames.count];
    NSString * name;
    while (name = [emt nextObject]) {
        if (![funcs containsObject:name]) {
            [funcs addObject:name];
        }
    }
    //干掉自己!
    [funcs removeObject:[NSString stringWithFormat:@"%s",__FUNCTION__]];
    //将数组变成字符串
    NSString * funcStr = [funcs  componentsJoinedByString:@"\n"];
    //写入
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"wsl.order"];
    NSData * fileContents = [funcStr dataUsingEncoding:NSUTF8StringEncoding];
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];
    if (result) {
        NSLog(@"二进制重排后的函数执行序列文件Order：%@",filePath);
    }else{
        NSLog(@"文件写入出错");
    }
    
    self.textView.text = funcStr;
}


//原子队列 存储启动时加载的所有函数方法
static  OSQueueHead symbolList = OS_ATOMIC_QUEUE_INIT;
//定义符号结构体
typedef struct {
    void *pc;
    void *next;
}SLSymbolNode;

/*
 所有处理完之后，最后需要Write Link Map File改为NO，把Other C Flags/Other Swift Flags的配置删除掉。
 因为这个配置会在我们代码中自动插入跳转执行 __sanitizer_cov_trace_pc_guard。重排完就不需要了，需要去除掉。
 同时把ViewController中的 __sanitizer_cov_trace_pc_guard也要去除掉。
 */
/// clang插桩代码
void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                         uint32_t *stop) {
    static uint64_t N;  // Counter for the guards.
    if (start == stop || *start) return;  // Initialize only once.
    //  printf("INIT: %p %p\n", start, stop);
    for (uint32_t *x = start; x < stop; x++)
        *x = ++N;  // Guards should start from 1.
}

/*
 静态插桩，相当于此函数在编译时插在了每一个函数体里，这个函数会捕获到所有程序运行过程中执行的方法。
 我们只需要捕获应用启动时执行的方法就行，把启动过程中执行的函数地址存储在symbolList中。
 */
static void*previousPc;
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    //    if (!*guard) return;  // Duplicate the guard check.
    /*  精确定位 哪里开始 到哪里结束!  在这里面做判断写条件!*/
    if(isBecomeActive) {
        //如果启动完成，后序的函数执行顺序完全取决于用户的操作，就不需要捕获了，只要捕获启动时首页渲染完毕时即可
        return;
    }
    
    //它的作用其实就是去读取 x30寄存器 中所存储的要返回时下一条指令的地址. 所以他名称叫做 __builtin_return_address . 换句话说 , 这个地址就是我当前这个函数执行完毕后 , 要返回到哪里去的函数地址 .
    void *PC = __builtin_return_address(0);
    
    SLSymbolNode *node = malloc(sizeof(SLSymbolNode));
    *node = (SLSymbolNode){PC,NULL};
    
    //防止循环引用，故在此过滤
    if (previousPc == PC) { return; }
    previousPc = PC;
    
    Dl_info info;
    dladdr(node->pc, &info);
    //根据内存地址获取函数名称
    NSString * name = @(info.dli_sname);
    //首页渲染完毕，即-[SceneDelegate sceneDidBecomeActive:]执行完毕后
    if ([name isEqualToString:@"-[SceneDelegate sceneDidBecomeActive:]"]) {
        isBecomeActive = YES;
    }
    
    //入队
    // offsetof 用在这里是为了入队添加下一个节点找到 前一个节点next指针的位置
    OSAtomicEnqueue(&symbolList, node, offsetof(SLSymbolNode, next));
}

@end
