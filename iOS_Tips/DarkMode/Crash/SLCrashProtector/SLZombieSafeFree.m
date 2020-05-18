//
//  SLZombieSafeFree.m
//  DarkMode
//
//  Created by wsl on 2020/4/29.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLZombieSafeFree.h"

#import "SLZombieCatcher.h"
#import "queue.h"
#import "fishhook.h"
#import <dlfcn.h>
#include <objc/runtime.h>
#include <malloc/malloc.h>

static Class sYHCatchIsa;
static size_t sYHCatchSize;

static void(* orig_free)(void *p);
struct DSQueue* _unfreeQueue = NULL;//用来保存自己偷偷保留的内存:1这个队列要线程安全或者自己加锁;2这个队列内部应该尽量少申请和释放堆内存。
int unfreeSize = 0;//用来记录我们偷偷保存的内存的大小
#define MAX_STEAL_MEM_SIZE 1024*1024*100//最多存这么多内存，大于这个值就释放一部分
#define MAX_STEAL_MEM_NUM 1024*1024*10//最多保留这么多个指针，再多就释放一部分
#define BATCH_FREE_NUM 100//每次释放的时候释放指针数量

/// 该类已弃用，有Hook冲突问题
@implementation SLZombieSafeFree

#pragma mark -------------------------- Life  Circle
+ (void)load{

    
#ifdef DEBUG
//    loadCatchProxyClass();
//    init_safe_free();
#endif
    
}


#pragma mark -------------------------- Public  Methods
//系统内存警告的时候调用这个函数释放一些内存
void free_some_mem(size_t freeNum){
#ifdef DEBUG
    size_t count = ds_queue_length(_unfreeQueue);
    freeNum= freeNum > count ? count:freeNum;
    for (int i=0; i<freeNum; i++) {
        void *unfreePoint = ds_queue_get(_unfreeQueue);
        size_t memSiziee = malloc_size(unfreePoint);
        __sync_fetch_and_sub(&unfreeSize, memSiziee);
        orig_free(unfreePoint);
    }
#endif
}


#pragma mark -------------------------- Private  Methods
void safe_free(void* p){
    
    int unFreeCount = ds_queue_length(_unfreeQueue);
    // 保留的内存大于一定值的时候就释放一部分
    if (unFreeCount > MAX_STEAL_MEM_NUM*0.9 || unfreeSize>MAX_STEAL_MEM_SIZE) {
        free_some_mem(BATCH_FREE_NUM);
    }
    else{
        size_t memSiziee = malloc_size(p);
        if (memSiziee > sYHCatchSize) {//有足够的空间才覆盖
            id obj=(id)p;
            Class origClass= object_getClass(obj);
            // 判断是不是objc对象
            char *type = @encode(typeof(obj));
            if (strcmp("@", type) == 0) {
                memset(obj, 0x55, memSiziee);
                memcpy(obj, &sYHCatchIsa, sizeof(void*));//把我们自己的类的isa复制过去
                object_setClass(obj, [SLZombieCatcher class]);
                ((SLZombieCatcher *)obj).originClass = origClass;
                __sync_fetch_and_add(&unfreeSize,(int)memSiziee);//多线程下int的原子加操作,多线程对全局变量进行自加，不用理线程锁了
                ds_queue_put(_unfreeQueue, p);
            }else{
               orig_free(p);
            }
        }else{
           orig_free(p);
        }
    }
}

void loadCatchProxyClass() {
    sYHCatchIsa = objc_getClass("SLZombieCatcher");
    sYHCatchSize = class_getInstanceSize(sYHCatchIsa);
}


bool init_safe_free() {
    _unfreeQueue = ds_queue_create(MAX_STEAL_MEM_NUM);
    orig_free = (void(*)(void*))dlsym(RTLD_DEFAULT, "free");
    rebind_symbols((struct rebinding[]){{"free", (void*)safe_free}}, 1);
    return true;
}

@end
