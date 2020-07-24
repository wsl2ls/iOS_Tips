//
//  SLAPMThreadCount.m
//  DarkMode
//
//  Created by wsl on 2020/7/23.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMThreadCount.h"
#include <pthread/introspection.h>
#include <mach/mach.h>
#import "SLTimer.h"

#import "BSBacktraceLogger.h"

#ifndef kk_dispatch_main_async_safe
#define kk_dispatch_main_async_safe(block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif

static pthread_introspection_hook_t old_pthread_introspection_hook_t = NULL;  //hook前原来的函数指针
static int threadCount = 0; //线程数量
#define KK_THRESHOLD 40   //线程总数量阈值
static const int threadIncreaseThreshold = 10;  //线程1秒内的增量阈值

//线程数量超过40，就会弹窗警告，并且控制台打印所有线程的堆栈；之后阈值每增加5条(45、50、55...)同样警告+打印堆栈；如果线程数量再次少于40条，阈值恢复到40
static int maxThreadCountThreshold = KK_THRESHOLD;
static dispatch_semaphore_t global_semaphore;   //信号量 保证线程安全
static int threadCountIncrease = 0; //线程增长数量
static bool isMonitor = false;  //是否正在监测
static NSString *taskName;  //任务ID

@implementation SLAPMThreadCount

///调用startMonitor函数，开始监控线程数量。在这个函数里用global_semaphore来保证，task_threads获取的线程数量，到hook完成，线程数量不会变化（加解锁之间，没有线程新建跟销毁）。
+ (void)startMonitorThreadCount {
    if (isMonitor) return;
    global_semaphore = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(global_semaphore, DISPATCH_TIME_FOREVER);
    mach_msg_type_number_t count;
    thread_act_array_t threads;
    //获取线程数量
    task_threads(mach_task_self(), &threads, &count);
    //加解锁之间，保证线程的数量不变
    threadCount = count;
    /*
     看这个函数名，很像我们平时hook函数一样的。
     返回值是上面声明的old_pthread_introspection_hook_t函数指针：返回原线程生命周期函数。
     参数也是函数指针：传入的是我们自定义的线程生命周期函数
     */
    old_pthread_introspection_hook_t = pthread_introspection_hook_install(kk_pthread_introspection_hook_t);
    dispatch_semaphore_signal(global_semaphore);
    
    isMonitor = true;
    
    //判断是否在主线程
    kk_dispatch_main_async_safe(^{
        taskName = [SLTimer execTask:self selector:@selector(clearThreadCountIncrease) start:0 interval:1.0 repeats:YES async:NO];
    });
}
//定时器每一秒都将线程增长数置0
+ (void)clearThreadCountIncrease
{
    threadCountIncrease = 0;
}
///结束监听
+ (void)stopMonitorThreadCount {
    if (!global_semaphore || !taskName) {
        return;
    }
    dispatch_semaphore_wait(global_semaphore, DISPATCH_TIME_FOREVER);
    pthread_introspection_hook_t lastHook = pthread_introspection_hook_install(old_pthread_introspection_hook_t);
    isMonitor = NO;
    [SLTimer cancelTask:taskName];
    dispatch_semaphore_signal(global_semaphore);
}

/**
 定义函数指针：pthread_introspection_hook_t
 event  : 线程处于的生命周期（下面枚举了线程的4个生命周期）
 thread ：线程
 addr   ：线程栈内存基址
 size   ：线程栈内存可用大小
 enum {
 PTHREAD_INTROSPECTION_THREAD_CREATE = 1, //创建线程
 PTHREAD_INTROSPECTION_THREAD_START, // 线程开始运行
 PTHREAD_INTROSPECTION_THREAD_TERMINATE,  //线程运行终止
 PTHREAD_INTROSPECTION_THREAD_DESTROY, //销毁线程
 };
 */
void kk_pthread_introspection_hook_t(unsigned int event,
                                     pthread_t thread, void *addr, size_t size)
{
    if (old_pthread_introspection_hook_t) {
        //执行原来的线程生命周期函数
        old_pthread_introspection_hook_t(event, thread, addr, size);
    }
    
    dispatch_semaphore_wait(global_semaphore, DISPATCH_TIME_FOREVER);
    if (event == PTHREAD_INTROSPECTION_THREAD_CREATE) {
        //创建线程
        threadCount = threadCount + 1;  //线程总量加1
        if (isMonitor && (threadCount > maxThreadCountThreshold)) {
            //如果线程总数大于监测的阈值，阈值+5；发出警告⚠️
            maxThreadCountThreshold += 5;
            kk_Alert_Log_CallStack(false, 0);
        }
        threadCountIncrease = threadCountIncrease + 1;
        if (isMonitor && (threadCountIncrease > threadIncreaseThreshold)) {
            //如果线程在1秒内的增长数超过了阈值，发出警告⚠️
            kk_Alert_Log_CallStack(true, threadCountIncrease);
        }
    }
    else if (event == PTHREAD_INTROSPECTION_THREAD_DESTROY){
        //销毁线程
        threadCount = threadCount - 1;  //线程总量-1
        if (threadCount < KK_THRESHOLD) {
            //如果线程数量再次少于40条，阈值恢复到40
            maxThreadCountThreshold = KK_THRESHOLD;
        }
        if (threadCountIncrease > 0) {
            //线程增量-1
            threadCountIncrease = threadCountIncrease - 1;
        }
    }
    dispatch_semaphore_signal(global_semaphore);
}

///发出警告 输出调用堆栈
void kk_Alert_Log_CallStack(bool isIncreaseLog, int num)
{
    if (isIncreaseLog) {
        NSLog(@"⚠️ 1秒钟开启了 %d 条线程！", num);
    }
    NSLog(@"⚠️ 线程监听：%@",[BSBacktraceLogger bs_backtraceOfAllThread]);
}

@end

