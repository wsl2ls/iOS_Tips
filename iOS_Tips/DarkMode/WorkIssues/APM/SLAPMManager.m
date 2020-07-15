//
//  SLAPMManager.m
//  DarkMode
//
//  Created by wsl on 2020/7/13.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMManager.h"
#import "SLTimer.h"

#import "SLAPMCpu.h"
#import "SLAPMFluency.h"

#include <mach/mach.h>

@interface SLAPMManager ()<SLAPMFluencyDelegate>
///任务名称
@property (nonatomic, copy) NSString *taskName;

@end

@implementation SLAPMManager

#pragma mark - Override
/// 重写allocWithZone方法，保证alloc或者init创建的实例不会产生新实例，因为该类覆盖了allocWithZone方法，所以只能通过其父类分配内存，即[super allocWithZone]
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self manager];
}
/// 重写copyWithZone方法，保证复制返回的是同一份实例
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [SLAPMManager manager];
}

#pragma mark - Public
+ (instancetype)manager {
    static SLAPMManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:NULL] init];
        manager.type = SLAPMTypeAll;
    });
    return manager;
}
///开始监控
- (void)startMonitoring {
    if (_isMonitoring) return;
    _isMonitoring = YES;
    
    if ((self.type & SLAPMTypeCpu) == SLAPMTypeCpu || (self.type & SLAPMTypeMemory) == SLAPMTypeMemory || (self.type & SLAPMTypeAll) == SLAPMTypeAll) {
        _taskName = [SLTimer execTask:self selector:@selector(monitoring) start:0 interval:1.0/60 repeats:YES async:YES];
    }
    
    if ((self.type & SLAPMTypeFluency) == SLAPMTypeFluency || (self.type & SLAPMTypeAll) == SLAPMTypeAll) {
        [SLAPMFluency sharedInstance].delegate = self;
        [[SLAPMFluency sharedInstance] startMonitoring];
    }
    
}
///结束监控
- (void)stopMonitoring {
    if (!_isMonitoring) return;
    _isMonitoring = NO;
    
    [SLTimer cancelTask:_taskName];
    [[SLAPMFluency sharedInstance] stopMonitoring];
}

#pragma mark - Monitoring
///监控中
- (void)monitoring {
    
    if ((self.type & SLAPMTypeCpu) == SLAPMTypeCpu || (self.type & SLAPMTypeAll) == SLAPMTypeAll) {
        float CPU = [SLAPMCpu getCpuUsage];
        NSLog(@" CPU使用率：%.2f%%",CPU);
    }
    
    if ((self.type & SLAPMTypeMemory) == SLAPMTypeMemory || (self.type & SLAPMTypeAll) == SLAPMTypeAll) {
        double useMemory = [SLAPMManager getUsageMemory];
        double freeMemory = [SLAPMManager getFreeMemory];
        double totalMemory = [SLAPMManager getTotalMemory];
        NSLog(@" Memory占用：%.1fM  空闲：%.1fM 总共：%.1fM",useMemory, freeMemory, totalMemory);
    }
    
}

#pragma mark - Memory / Disk
///当前应用的内存占用情况，和Xcode数值相近 单位MB
+ (double)getUsageMemory {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if(task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count) == KERN_SUCCESS) {
        return (double)vmInfo.phys_footprint / (1024 * 1024);
    } else {
        return -1.0;
    }
}
///剩余空闲内存  单位MB
+ (double)getFreeMemory{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return vm_stat.free_count * page_size / (1024 * 1024);
}
/// 总共的内存大小  单位MB
+ (double)getTotalMemory {
    int64_t mem = [[NSProcessInfo processInfo] physicalMemory];
    if (mem < -1) mem = -1;
    return mem / (1024 * 1024);
}

///filePath目录下的文件 占用的磁盘大小  单位MB  默认沙盒Caches目录
+ (double)getUsageDisk:(NSString *)filePath {
    if (filePath.length == 0)  filePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    ///定时执行时，此句代码会导致内存不断增长？0.1M   合理安排执行时机
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:filePath error:nil] ;
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    filesArray = nil;
    
    NSString *fileName;
    unsigned long long int fileSize = 0;
    while (fileName = [filesEnumerator nextObject]) {
        @autoreleasepool {
            //单个文件大小
            NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:[filePath stringByAppendingPathComponent:fileName] error:nil];
            fileSize += [fileDic fileSize];
        }
    }
    filesEnumerator = nil;
    return fileSize / (1024*1024);
}
///剩余空闲的磁盘容量  单位G
+ (double)getFreeDisk {
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    NSNumber *freeSize = [fattributes objectForKey:NSFileSystemFreeSize];
    return [freeSize integerValue] / (1024*1024*1024);
}
///总磁盘容量  单位G
+ (double)getTotalDisk {
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    NSNumber *totalSize = [fattributes objectForKey:NSFileSystemSize];
    return [totalSize integerValue] / (1024*1024*1024);
}

#pragma mark - Fluency/卡顿监测
///卡顿监控回调 当callStack不为nil时，表示发生卡顿并捕捉到卡顿时的调用栈
- (void)APMFluency:(SLAPMFluency *)fluency didChangedFps:(float)fps callStackOfStuck:(nullable NSString *)callStack {
    NSLog(@" 卡顿监测  fps：%f \n %@", fps, callStack == nil ? @"流畅":[NSString stringWithFormat:@"卡住了 %@",callStack]);
}

@end
