//
//  SLAPMMemoryDisk.m
//  DarkMode
//
//  Created by wsl on 2020/7/18.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMMemoryDisk.h"
#include <mach/mach.h>

@implementation SLAPMMemoryDisk


#pragma mark - Memory / Disk
///当前应用的内存占用情况，和Xcode数值相近 单位MB
+ (double)getAppUsageMemory {
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
+ (double)getFileUsageDisk:(NSString *)filePath {
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


@end
