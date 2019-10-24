//
//  SLImageView.m
//  WSLImageView
//
//  Created by 王双龙 on 2018/10/26.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import "SLImageView.h"
#include <mach/mach.h>

#define SL_LOCK_VIEW(...) dispatch_semaphore_wait(view->_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(view->_lock);

#define SL_LOCK(...) dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(self->_lock);

#define SL_BUFFER_SIZE (10 * 1024 * 1024) // 10MB (minimum memory buffer size)
#define SL_CLAMP(_x_, _low_, _high_)  (((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_)))

#pragma mark - 弱引用对象

//临时弱引用对象，解决循环引用的问题  引自 YYWeakProxy
@interface SLWeakProxy : NSProxy <NSObject>
@property (nullable, nonatomic, weak, readonly) id target;
@end
@implementation SLWeakProxy
+ (instancetype)proxyWithTarget:(id)target {
    return [[SLWeakProxy alloc] initWithTarget:target];
}
- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}
//将消息接收对象改为 _target
- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}
//self 对 target 是弱引用，一旦 target 被释放将调用下面两个方法，如果不实现的话会 crash
- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}
- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}
- (NSUInteger)hash {
    return [_target hash];
}
- (Class)superclass {
    return [_target superclass];
}
- (Class)class {
    return [_target class];
}
- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}
- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}
- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}
- (BOOL)isProxy {
    return YES;
}
- (NSString *)description {
    return [_target description];
}
- (NSString *)debugDescription {
    return [_target debugDescription];
}
@end

#pragma mark - 帧动画ImageView
@interface SLImageView () {
    @package
    CADisplayLink *_displayLink; /// 帧动画切换器
    NSTimeInterval _time; /// 上一帧展示完剩余的时间
    SLImage *_curAnimatedImage; /// 当前动画的image
    NSMutableDictionary *_buffer; ///< 帧缓冲池
    dispatch_semaphore_t _lock; ///<  给帧缓冲池_buffer加锁
    NSInteger _incrBufferCount; ///< 当前帧缓存池插入的帧数
    BOOL _bufferMiss; ///< 是否丢帧
    NSUInteger _maxBufferCount; ///< 最大的缓冲帧数量
    NSUInteger _totalFrameCount; ///< 总帧数
    SLImageFrame *_curFrame; ///< 当前展示的帧
    NSUInteger _curIndex; ///< 当前展示的帧索引
    dispatch_once_t _onceToken;
    NSOperationQueue *_requestQueue; ///< 连续获取某帧image的操作队列
}
/**
 根据当前内存大小动态计算适合的缓存帧数
 */
- (void)calcMaxBufferCount;
@end

#pragma mark - 解码操作
//解码获取某帧image的线程操作
@interface SLImageFrameDecodeOperation : NSOperation
@property (nonatomic, weak) SLImageView *view;
@property (nonatomic, assign) NSUInteger nextIndex; //解码下一帧
@property (nonatomic, strong) SLImage *curImage;
@end

@implementation SLImageFrameDecodeOperation
- (void)main {
    __strong SLImageView *view = _view;
    if (!view) return;
    if ([self isCancelled]) return;
    view->_incrBufferCount++;
    if (view->_incrBufferCount == 0) [view calcMaxBufferCount];
    if (view->_incrBufferCount > (NSInteger)view->_maxBufferCount) {
        view->_incrBufferCount = view->_maxBufferCount;
    }
    NSUInteger idx = _nextIndex;
    NSUInteger max = view->_incrBufferCount < 1 ? 1 : view->_incrBufferCount;
    NSUInteger total = view->_totalFrameCount;
    view = nil;
    
    for (int i = 0; i < max; i++, idx++) {
        @autoreleasepool {
            if (idx >= total) idx = 0;
            if ([self isCancelled]) break;
            __strong SLImageView *view = _view;
            if (!view) break;
            SL_LOCK_VIEW(BOOL miss = (view->_buffer[@(idx)] == nil));
            if (miss) {
                SLImageFrame *imageFrame = [_curImage imageFrameAtIndex:idx];
                if ([self isCancelled]) break;
                SL_LOCK_VIEW(view->_buffer[@(idx)] = imageFrame ? imageFrame : [NSNull null]);
                view = nil;
            }
        }
    }
}
@end

@implementation SLImageView
/**
 重置动画
 */
- (void)resetAnimated {
    dispatch_once(&_onceToken, ^{
        self->_lock = dispatch_semaphore_create(1);
        self->_buffer = [NSMutableDictionary new];
        self->_requestQueue = [[NSOperationQueue alloc] init];
        self->_requestQueue.maxConcurrentOperationCount = 1;
        self->_displayLink = [CADisplayLink displayLinkWithTarget:[SLWeakProxy proxyWithTarget:self] selector:@selector(playAnimationImage:)];
        [self->_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self->_displayLink.paused = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
    
    if (_curIndex != 0) {
        [self willChangeValueForKey:@"currentAnimatedImageIndex"];
        _curIndex = 0;
        [self didChangeValueForKey:@"currentAnimatedImageIndex"];
    }
    
    _displayLink.paused = !_currentIsPlaying;
    _time = 0;
    _curFrame = nil;
    _bufferMiss = NO;
    _incrBufferCount = 0;
    [_buffer removeAllObjects];
    [_requestQueue cancelAllOperations];
}

#pragma mark - Event Handle
//切换图片帧
- (void)playAnimationImage:(CADisplayLink *)displayLink {
    if (!_autoPlayAnimatedImage) {
        return;
    }
    NSMutableDictionary *buffer = _buffer;
    SLImageFrame *nextBufferedImage = nil;
    SLImageFrame *curBufferedImage = nil;
    BOOL bufferIsFull = NO;
    NSUInteger nextIndex = (_curIndex + 1) % _curAnimatedImage.frameCount;
    curBufferedImage = buffer[@(_curIndex)];
    nextBufferedImage = buffer[@(nextIndex)];
    
    NSTimeInterval imageDuration = 0;
    if (!_bufferMiss) {
        _time += _displayLink.duration;
        imageDuration = curBufferedImage == nil ? [_curAnimatedImage imageDurationAtIndex:_curIndex] : curBufferedImage.duration;
        if (_time < imageDuration) return;
        _time -= imageDuration;
        if (nextIndex == 0) {
            //一个循环完成
        }
        imageDuration = nextBufferedImage == nil ? [_curAnimatedImage imageDurationAtIndex:nextIndex] : nextBufferedImage.duration;
        if (_time > imageDuration) _time = imageDuration; // do not jump over frame
    }
    
    SL_LOCK(
            if (nextBufferedImage) {
        if ((int)_incrBufferCount < _totalFrameCount) {
            [buffer removeObjectForKey:@(nextIndex)];
        }
        [self willChangeValueForKey:@"currentAnimatedImageIndex"];
        _curIndex = nextIndex;
        [self didChangeValueForKey:@"currentAnimatedImageIndex"];
        _curFrame = nextBufferedImage == (id)[NSNull null] ? nil : nextBufferedImage;
        super.image = _curFrame.image == nil ? [UIImage new] :_curFrame.image ;
        nextIndex = (_curIndex + 1) % _totalFrameCount;
        _bufferMiss = NO;
        if (buffer.count == _totalFrameCount) {
            bufferIsFull = YES;
        }
    } else {
        _bufferMiss = YES;
    }
            )//LOCK
    
    if (!bufferIsFull && _requestQueue.operationCount == 0) {
        //异步串行队列去执行下一帧的解码任务
        SLImageFrameDecodeOperation *operation = [SLImageFrameDecodeOperation new];
        operation.view = self;
        operation.nextIndex = nextIndex;
        operation.curImage = _curAnimatedImage;
        [_requestQueue addOperation:operation];
    }
    
}

//收到内存警告，缓冲池里只保留下一帧
- (void)didReceiveMemoryWarning:(NSNotification *)notification{
    [_requestQueue cancelAllOperations];
    [_requestQueue addOperationWithBlock: ^{
        self->_incrBufferCount = -60 - (int)(arc4random() % 120); // about 1~3 seconds to grow back..
        NSNumber *next = @((self->_curIndex + 1) % self->_totalFrameCount);
        SL_LOCK(
                NSArray * keys = self->_buffer.allKeys;
                for (NSNumber * key in keys) {
            if (![key isEqualToNumber:next]) { // keep the next frame for smoothly animation
                [self->_buffer removeObjectForKey:key];
            }
        }
                )//LOCK
    }];
}
//进入后台，缓冲池里只保留下一帧
- (void)didEnterBackground:(NSNotification *)notification{
    [_requestQueue cancelAllOperations];
    NSNumber *next = @((_curIndex + 1) % _totalFrameCount);
    SL_LOCK(
            NSArray * keys = _buffer.allKeys;
            for (NSNumber * key in keys) {
        if (![key isEqualToNumber:next]) { // keep the next frame for smoothly animation
            [_buffer removeObjectForKey:key];
        }
    }
            )//LOCK
}

#pragma mark - Help Methods
// 根据当前内存大小动态计算适合的缓存帧数
- (void)calcMaxBufferCount {
    int64_t bytes = (int64_t)[_curAnimatedImage imageFrameBytes];
    if (bytes == 0) bytes = 1024;
    int64_t total = [self memoryTotal];
    int64_t free = [self memoryFree];
    int64_t max = MIN(total * 0.2, free * 0.6);
    max = MAX(max, SL_BUFFER_SIZE);
    if (_maxBufferSize) max = max > _maxBufferSize ? _maxBufferSize : max;
    double maxBufferCount = (double)max / (double)bytes;
    maxBufferCount = SL_CLAMP(maxBufferCount, 1, 100);
    _maxBufferCount = maxBufferCount;
}
// 总共的内存大小
- (int64_t)memoryTotal {
    int64_t mem = [[NSProcessInfo processInfo] physicalMemory];
    if (mem < -1) mem = -1;
    return mem;
}
// 空闲的内存大小
- (int64_t)memoryFree {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return vm_stat.free_count * page_size;
}

#pragma mark -  Setter And Getter
- (void)setImage:(SLImage *)image{
    if ([image isMemberOfClass:[UIImage class]]) {
        image = [SLImage imageWithData:UIImagePNGRepresentation(image)];
    }
    [self resetAnimated];
    _curAnimatedImage = (SLImage *)image;
    _totalFrameCount = _curAnimatedImage.frameCount;
    super.image = [_curAnimatedImage imageAtIndex:_curIndex];
    [self calcMaxBufferCount];
    [self didMoved];
}
- (void)setCurrentImageIndex:(NSUInteger)currentImageIndex{
    if (!_curAnimatedImage) return;
    if (currentImageIndex >= _curAnimatedImage.frameCount) return;
    if (_curIndex == currentImageIndex) return;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            SL_LOCK(
                    [self->_requestQueue cancelAllOperations];
                    [self->_buffer removeAllObjects];
                    [self willChangeValueForKey:@"currentAnimatedImageIndex"];
                    self->_curIndex = currentImageIndex;
                    [self didChangeValueForKey:@"currentAnimatedImageIndex"];
                    self->_curFrame = [self->_curAnimatedImage imageFrameAtIndex:self->_curIndex];
                    self->_time = 0;
                    self->_bufferMiss = NO;
                    super.image = [self->_curAnimatedImage imageAtIndex:self->_curIndex];
                    )//LOCK
        });
    });
}
- (SLImage *)animatedImage {
    return _curAnimatedImage;
}
- (NSUInteger)currentImageIndex{
    return _curIndex;
}
- (SLImageType)imageType {
    return _curAnimatedImage.imageType;
}

#pragma mark - Overrice NSObject(NSKeyValueObservingCustomization)

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"currentAnimatedImageIndex"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

#pragma mark - 重写系统方法
- (instancetype)init {
    self = [super init];
    if (self) {
        _autoPlayAnimatedImage = YES;
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _autoPlayAnimatedImage = YES;
    }
    return self;
}
/**
 开始动画
 */
- (void)startAnimating{
    if(_curAnimatedImage.frameCount > 1 && _totalFrameCount != 0){
        _displayLink.paused = NO;
        _currentIsPlaying = YES;
    }else{
        [self stopAnimating];
        _currentIsPlaying = NO;
    }
}
/**
 关闭动画
 */
- (void)stopAnimating{
    [super stopAnimating];
    [_requestQueue cancelAllOperations];
    _displayLink.paused = YES;
    _currentIsPlaying = NO;
}
- (void)dealloc {
    [self stopAnimating];
    [_displayLink invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self didMoved];
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self didMoved];
}
- (void)didMoved {
    if (self.autoPlayAnimatedImage) {
        if(self.superview && self.window) {
            [self startAnimating];
        } else {
            [self stopAnimating];
        }
    }
}

@end

