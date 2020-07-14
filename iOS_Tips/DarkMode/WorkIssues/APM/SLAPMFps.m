//
//  SLAPMFps.m
//  DarkMode
//
//  Created by wsl on 2020/7/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLAPMFps.h"
#import "SLProxy.h"

@interface SLAPMFps ()
{
    NSTimeInterval _lastTime;
    int _count;
}
@property (nonatomic, strong) CADisplayLink *displayLink;
@end
@implementation SLAPMFps

#pragma mark - Override
/// 重写allocWithZone方法，保证alloc或者init创建的实例不会产生新实例，因为该类覆盖了allocWithZone方法，所以只能通过其父类分配内存，即[super allocWithZone]
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}
/// 重写copyWithZone方法，保证复制返回的是同一份实例
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [SLAPMFps sharedInstance];
}

#pragma mark - Public
+ (instancetype)sharedInstance {
    static SLAPMFps *fps = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fps = [[super allocWithZone:NULL] init];
    });
    return fps;
}
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
    
    //1秒之后，初始化时间和次数，重新开始监测
    _lastTime = link.timestamp;
    _count = 0;
    
    if([self.delegate respondsToSelector:@selector(APMFps:didChangedFps:)]) {
        [self.delegate APMFps:self didChangedFps:fps];
    }
}

@end
