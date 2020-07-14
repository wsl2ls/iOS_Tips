//
//  SLAPMCpu.m
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMCpu.h"

#include <mach/mach.h>

#import "BSBacktraceLogger.h"

@implementation SLAPMCpu

//struct thread_basic_info {
//    time_value_t    user_time;      /* user run time（用户运行时长） */
//    time_value_t    system_time;    /* system run time（系统运行时长） */
//    integer_t       cpu_usage;      /* scaled cpu usage percentage（CPU使用率，上限1000） */
//    policy_t        policy;         /* scheduling policy in effect（有效调度策略） */
//    integer_t       run_state;      /* run state (运行状态，见下) */
//    integer_t       flags;          /* various flags (各种各样的标记) */
//    integer_t       suspend_count;  /* suspend count for thread（线程挂起次数） */
//    integer_t       sleep_time;     /* number of seconds that thread has been sleeping（休眠时间） */
//};
#pragma mark - CPU占有率
+ (double)getCpuUsage {
    kern_return_t           kr;
    thread_array_t          threadList;         // 保存当前Mach task的线程列表
    mach_msg_type_number_t  threadCount;        // 保存当前Mach task的线程个数
    thread_info_data_t      threadInfo;         // 保存单个线程的信息列表
    mach_msg_type_number_t  threadInfoCount;    // 保存当前线程的信息列表大小
    thread_basic_info_t     threadBasicInfo;    // 线程的基本信息
    
    // 通过“task_threads”API调用获取指定 task 的线程列表
    //  mach_task_self_，表示获取当前的 Mach task
    kr = task_threads(mach_task_self(), &threadList, &threadCount);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    double cpuUsage = 0;
    for (int i = 0; i < threadCount; i++) {
        threadInfoCount = THREAD_INFO_MAX;
        // 通过“thread_info”API调用来查询指定线程的信息
        //  flavor参数传的是THREAD_BASIC_INFO，使用这个类型会返回线程的基本信息，
        //  定义在 thread_basic_info_t 结构体，包含了用户和系统的运行时间、运行状态和调度优先级等
        kr = thread_info(threadList[i], THREAD_BASIC_INFO, (thread_info_t)threadInfo, &threadInfoCount);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        threadBasicInfo = (thread_basic_info_t)threadInfo;
        if (!(threadBasicInfo->flags & TH_FLAGS_IDLE)) {
            cpuUsage += threadBasicInfo->cpu_usage;
        }
    }
    
    // 回收内存，防止内存泄漏
    vm_deallocate(mach_task_self(), (vm_offset_t)threadList, threadCount * sizeof(thread_t));
    
    float cpu = cpuUsage / (double)TH_USAGE_SCALE * 100.0;
    return cpu;
}

///  返回GPU使用情况 占有率
/// @param max  设定GPU使用率最大边界值
/// @param callback 超出边界后的回调方法  返回此时的堆栈信息
+ (double)getCpuUsageWithMax:(float)max outOfBoundsCallback:(void(^)(NSString *string))callback {
    float cpu= [SLAPMCpu getCpuUsage];
    if (cpu/100.0 >= max) {
        NSString *callbackString =  [BSBacktraceLogger bs_backtraceOfAllThread];
        callback(callbackString);
    }
    return cpu;
}


@end
