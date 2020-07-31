//
//  SLAPMFluency.m
//  DarkMode
//
//  Created by wsl on 2020/7/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMFluency.h"
#import "SLProxy.h"

#import "BSBacktraceLogger.h"

/// 利用runloop 检测主线程每次执行消息循环的时间，当这一时间大于阈值时，就记为发生一次卡顿。
@interface SLAPMRunLoop : NSObject
{
    int _timeoutCount;   // 耗时次数
    CFRunLoopObserverRef _observer;  // 观察者
    dispatch_semaphore_t _semaphore; // 信号
    CFRunLoopActivity _activity; // 状态
}
///卡顿时的调用堆栈信息
@property (nonatomic, copy) NSString *callStack;
@property (nonatomic, copy) void (^showStuckInfo)(NSString *callStack);
@end

@implementation SLAPMRunLoop

#pragma mark - Public
// 开始监听
- (void)startRunning {
    if (_observer) {
        return;
    }
    
    // 创建信号
    _semaphore = dispatch_semaphore_create(0);
    NSLog(@"dispatch_semaphore_create:%@",getCurTime());
    
    // 注册RunLoop状态观察
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    //创建Run loop observer对象
    //第一个参数用于分配observer对象的内存
    //第二个参数用以设置observer所要关注的事件，详见回调函数myRunLoopObserver中注释
    //第三个参数用于标识该observer是在第一次进入run loop时执行还是每次进入run loop处理时均执行
    //第四个参数用于设置该observer的优先级
    //第五个参数用于设置该observer的回调函数
    //第六个参数用于设置该observer的运行环境
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    // 在子线程监控时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {   // 有信号的话 就查询当前runloop的状态
            
            // 假定连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)
            // 因为下面 runloop 状态改变回调方法runLoopObserverCallBack中会将信号量递增 1,所以每次 runloop 状态改变后,下面的语句都会执行一次
            // 当其返回0时表示在timeout之前，该函数所处的线程被成功唤醒。当其返回不为0时，表示timeout发生。
            long st = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
            
            if (st != 0) {  // 信号量超时了 - 即 runloop 的状态长时间没有发生变更,长期处于某一个状态下
                if (!self->_observer) {
                    self->_timeoutCount = 0;
                    self->_semaphore = 0;
                    self->_activity = 0;
                    return;
                }
                
                // kCFRunLoopBeforeSources - 即将处理source kCFRunLoopAfterWaiting - 刚从休眠中唤醒
                // 获取kCFRunLoopBeforeSources到kCFRunLoopBeforeWaiting再到kCFRunLoopAfterWaiting的状态就可以知道是否有卡顿的情况。
                // kCFRunLoopBeforeSources:停留在这个状态,表示在做很多事情
                if (self->_activity == kCFRunLoopBeforeSources || self->_activity == kCFRunLoopAfterWaiting) {    // 发生卡顿,记录卡顿次数
                    if (++self->_timeoutCount < 5) {
                        continue;   // 不足 5 次,直接 continue 当次循环,不将timeoutCount置为0
                    }
                    
                    // 收集此时卡顿的调用堆栈
                    NSString *callStack = [BSBacktraceLogger bs_backtraceOfMainThread];
                    self.callStack = callStack;
                    if(self.showStuckInfo) {
                        self.showStuckInfo(callStack);
                    }
                    //                    NSLog(@" 卡顿了 \n %@", callStack);
                }
            }
            self->_timeoutCount = 0;
        }
    });
}

// 停止监听
- (void)stopRunning  {
    if (!_observer) {
        return;
    }
    // 移除观察并释放资源
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

#pragma mark - runloop observer callback
///runloop状态改变回调 就记录一下
static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    
    SLAPMRunLoop *monitor = (__bridge SLAPMRunLoop*)info;
    // 记录状态值
    monitor->_activity = activity;
    
    // 发送信号
    dispatch_semaphore_t semaphore = monitor->_semaphore;
    // 当返回值为0时表示当前并没有线程等待其处理的信号量，其处理的信号量的值加1即可。当返回值不为0时，表示其当前有（一个或多个）线程等待其处理的信号量，并且该函数唤醒了一个等待的线程（当线程有优先级时，唤醒优先级最高的线程；否则随机唤醒）
    long st = dispatch_semaphore_signal(semaphore);
    //    NSLog(@"dispatch_semaphore_signal:st=%ld,time:%@",st,getCurTime());
    
    //    if (activity == kCFRunLoopEntry) {
    //        NSLog(@"runLoopObserverCallBack - %@",@"即将进入RunLoop");
    //    } else if (activity == kCFRunLoopBeforeTimers) {
    //        NSLog(@"runLoopObserverCallBack - %@",@"即将处理Timer");
    //    } else if (activity == kCFRunLoopBeforeSources) {
    //        NSLog(@"runLoopObserverCallBack - %@",@"即将处理Source");
    //    } else if (activity == kCFRunLoopBeforeWaiting) {
    //        NSLog(@"runLoopObserverCallBack - %@",@"即将进入休眠");
    //    } else if (activity == kCFRunLoopAfterWaiting) {
    //        NSLog(@"runLoopObserverCallBack - %@",@"刚从休眠中唤醒");
    //    } else if (activity == kCFRunLoopExit) {
    //        NSLog(@"runLoopObserverCallBack - %@",@"即将退出RunLoop");
    //    } else if (activity == kCFRunLoopAllActivities) {
    //        NSLog(@"runLoopObserverCallBack - %@",@"kCFRunLoopAllActivities");
    //    }
}

#pragma mark - private function
NSString * getCurTime(void) {
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"YYYY/MM/dd hh:mm:ss:SSS"];
    NSString *curTime = [format stringFromDate:[NSDate date]];
    return curTime;
}

@end

///监测帧频，抖动比较大，无法获取卡顿时的调用栈，所以结合runloop检测主线程消息循环执行的时间来作为卡顿的衡量指标
@interface SLAPMFps : NSObject
{
    NSTimeInterval _lastTime; //上次屏幕刷新时间
    int _count;  //FPS
}
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) float fps;
@property (nonatomic, copy) void (^fpsChanged)(float fps);
@end
@implementation SLAPMFps

#pragma mark - Public
///开始
- (void)play {
    [self.displayLink setPaused:NO];
}
///暂停
- (void)paused {
    [self.displayLink setPaused:YES];
}
///销毁
- (void)invalidate {
    [self paused];
    [self.displayLink invalidate];
    self.displayLink = nil;
}

#pragma mark - Getter
- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:[SLProxy proxyWithTarget:self] selector:@selector(displayLinkTick:)];
        [_displayLink setPaused:YES];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return _displayLink;
}

//这个方法的执行频率跟当前屏幕的刷新频率是一样的，屏幕每渲染刷新一次，就执行一次，那么1秒的时长执行刷新的次数就是当前的FPS值
- (void)displayLinkTick:(CADisplayLink *)link{
    //     duration 是只读的， 表示屏幕刷新的间隔 = 1/fps
    //     timestamp 是只读的， 表示上次屏幕渲染的时间点
    //    frameInterval 是表示定时器被触发的间隔， 默认值是1， 就是表示跟屏幕的刷新频率一致。
    //    NSLog(@"timestamp= %f  duration= %f frameInterval= %f",link.timestamp, link.duration, frameInterval);
    
    //初始化屏幕渲染的时间
    if (_lastTime == 0) {
        _lastTime = link.timestamp;
        return;
    }
    //刷新次数累加
    _count++;
    //刚刚屏幕渲染的时间与最开始幕渲染的时间差
    NSTimeInterval interval = link.timestamp - _lastTime;
    if (interval < 1) {
        //不足1秒，继续统计刷新次数
        return;
    }
    //刷新频率
    float fps = _count / interval;
    _fps = fps;
    
    //1秒之后，初始化时间和次数，重新开始监测
    _lastTime = link.timestamp;
    _count = 0;
    
    if (self.fpsChanged) {
        self.fpsChanged(fps);
    }
}
@end


@interface SLAPMFluency ()
@property (nonatomic, strong) SLAPMFps *fps;
@property (nonatomic, strong) SLAPMRunLoop *runLoop;
@end

@implementation SLAPMFluency
#pragma mark - Override
/// 重写allocWithZone方法，保证alloc或者init创建的实例不会产生新实例，因为该类覆盖了allocWithZone方法，所以只能通过其父类分配内存，即[super allocWithZone]
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}
/// 重写copyWithZone方法，保证复制返回的是同一份实例
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [SLAPMFluency sharedInstance];
}

#pragma mark - Public
+ (instancetype)sharedInstance {
    static SLAPMFluency *luency = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        luency = [[super allocWithZone:NULL] init];
        luency.type =  SLAPMFluencyTypeRunloop;
    });
    return luency;
}

///开始监听
- (void)startMonitorFluency {
    __weak typeof(self) weakSelf = self;
    if (self.type == SLAPMFluencyTypeRunloop) {
        [self.runLoop startRunning];
        //防止跟 self.fps.fpsChanged的回调重复执行
        self.runLoop.showStuckInfo = ^(NSString *callStack) {
            if ([weakSelf.delegate respondsToSelector:@selector(APMFluency:didChangedFps:callStackOfStuck:)]) {
                [weakSelf.delegate APMFluency:weakSelf didChangedFps:weakSelf.fps.fps callStackOfStuck:callStack];
            }
        };
        
    }else  if (self.type == SLAPMFluencyTypeFps) {
        [self.fps play];
        self.fps.fpsChanged = ^(float fps) {
            if ([weakSelf.delegate respondsToSelector:@selector(APMFluency:didChangedFps:callStackOfStuck:)]) {
                [weakSelf.delegate APMFluency:weakSelf didChangedFps:fps callStackOfStuck:[weakSelf.runLoop.callStack copy]];
                weakSelf.runLoop.callStack = nil;
            }
        };
    }else if (self.type == SLAPMFluencyTypeAll) {
        [self.fps play];
        [self.runLoop startRunning];
        self.fps.fpsChanged = ^(float fps) {
            if ([weakSelf.delegate respondsToSelector:@selector(APMFluency:didChangedFps:callStackOfStuck:)]) {
                [weakSelf.delegate APMFluency:weakSelf didChangedFps:fps callStackOfStuck:[weakSelf.runLoop.callStack copy]];
                weakSelf.runLoop.callStack = nil;
            }
        };
    }
    
}
///结束监听
- (void)stopMonitorFluency {
    [self.fps paused];
    [self.runLoop stopRunning];
}

#pragma mark - Getter
- (SLAPMFps *)fps {
    if (!_fps) {
        _fps = [[SLAPMFps alloc] init];
    }
    return _fps;
}
- (SLAPMRunLoop *)runLoop {
    if (!_runLoop) {
        _runLoop = [[SLAPMRunLoop alloc] init];
    }
    return _runLoop;;
}

@end
