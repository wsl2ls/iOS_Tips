//
//  SLImage.m
//  WSLImageView
//
//  Created by 王双龙 on 2018/10/26.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import "SLImage.h"

@interface SLImage () {
    NSUInteger _bytesPerFrame; //每一帧图片的字节大小
    dispatch_semaphore_t _preloadedLock; //预加载锁
    SLImageDecoder * _imageDecoder;  //解码工具
    NSArray <SLImageFrame *> * _preloadedFrames;  //预加载的图片帧
}
@end

@implementation SLImage

//减少内存的占用
+ (SLImage *)imageNamed:(NSString *)name{
    
    if (name.length == 0) return nil;
    if ([name hasSuffix:@"/"]) return nil;
    
    //从文件的最后一部分删除扩展名
    NSString *res = name.stringByDeletingPathExtension;
    //提取其文件扩展名
    NSString *ext = name.pathExtension;
    NSString *path = nil;
    CGFloat scale = 1;
    
    NSArray *exts = ext.length > 0 ? @[ext] : @[@"", @"png", @"jpeg", @"jpg", @"gif", @"webp", @"apng"];
    NSArray *scales = [SLImage preferredScales];
    for (int s = 0; s < scales.count; s++) {
        scale = ((NSNumber *)scales[s]).floatValue;
        //   FLT_EPSILON = 1.192092896e-07F 大于0的最小浮点数
        NSString *scaledName =  (fabs(scale - 1) <= __FLT_EPSILON__ || res == 0 ) ? res : [res stringByAppendingFormat:@"@%@x", @(scale)];
        for (NSString *e in exts) {
            path = [[NSBundle mainBundle] pathForResource:scaledName ofType:e];
            if (path) break;
        }
        if (path) break;
    }
    if (path.length == 0) return nil;
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length == 0) return nil;
    return [[self alloc] initWithData:data scale:scale];
}

+ (NSArray *)preferredScales{
    NSArray *scales;
    //像素分辨率,首先取当前分辨率的图片，没有的话取其他的
    CGFloat screenScale = [UIScreen mainScreen].scale;
    if (screenScale <= 1) {
        scales = @[@1,@2,@3];
    } else if (screenScale <= 2) {
        scales = @[@2,@3,@1];
    } else {
        scales = @[@3,@2,@1];
    }
    return scales;
}

+ (SLImage *)imageWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (SLImage *)imageWithData:(NSData *)data{
    return [[self alloc] initWithData:data];
}

+ (SLImage *)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[self alloc] initWithData:data scale:scale];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data scale:[UIScreen mainScreen].scale];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:[UIScreen mainScreen].scale];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    
    if (data.length == 0) return nil;
    if (scale <= 0) scale = [UIScreen mainScreen].scale;
    //信号量
    _preloadedLock = dispatch_semaphore_create(1);
    //创建一个自动释放池 ，有大量中间临时变量产生时，避免内存使用峰值过高，及时释放内存的场景 https://blog.csdn.net/z040145/article/details/69398768
    @autoreleasepool {
        _imageDecoder = [[SLImageDecoder alloc] init];
        [_imageDecoder  decoderWithData:data scale:[UIScreen mainScreen].scale];
        _imageType = _imageDecoder.imageType;
        _frameCount = _imageDecoder.frameCount;
        UIImage * imageFrame = [_imageDecoder imageAtIndex:0];
        if (!imageFrame) return nil;
        self = [self initWithCGImage:imageFrame.CGImage scale:scale orientation:UIImageOrientationUp];
        if (!self) return nil;
        _bytesPerFrame = CGImageGetBytesPerRow(imageFrame.CGImage) * CGImageGetHeight(imageFrame.CGImage);
        _animatedImageMemorySize = _bytesPerFrame * _imageDecoder.frameCount;
    }
    return self;
}

/**
 是否预解码所有的帧
 */
- (void)setPreloadAllAnimatedImageFrames:(BOOL)preloadAllAnimatedImageFrames{
    _preloadAllAnimatedImageFrames = preloadAllAnimatedImageFrames;
    if (_preloadAllAnimatedImageFrames && _imageDecoder.frameCount > 0) {
        NSMutableArray *frames = [NSMutableArray new];
        for (NSUInteger i = 0, max = _imageDecoder.frameCount; i < max; i++) {
            SLImageFrame *imageFrame = [_imageDecoder imageFrameAtIndex:i];
            if (imageFrame) {
                [frames addObject:imageFrame];
            } else {
                [frames addObject:[NSNull null]];
            }
        }
        dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
        _preloadedFrames = frames;
        dispatch_semaphore_signal(_preloadedLock);
    }else if(!_preloadAllAnimatedImageFrames){
        dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
        _preloadedFrames = nil;
        dispatch_semaphore_signal(_preloadedLock);
    }
}

#pragma mark - 帧信息

- (SLImageFrame *)imageFrameAtIndex:(NSInteger)index {
    if (index >= _imageDecoder.frameCount) return nil;
    dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
    SLImageFrame *imageFrame = _preloadedFrames[index];
    dispatch_semaphore_signal(_preloadedLock);
    if (imageFrame) return imageFrame == (id)[NSNull null] ? nil : imageFrame;
    return [_imageDecoder imageFrameAtIndex:index];
}
- (UIImage *)imageAtIndex:(NSUInteger)index {
    if (index >= _imageDecoder.frameCount) return nil;
    dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
    SLImageFrame *imageFrame = _preloadedFrames[index];
    dispatch_semaphore_signal(_preloadedLock);
    if (imageFrame.image) return imageFrame.image == (id)[NSNull null] ? nil : imageFrame.image;
    return [_imageDecoder imageAtIndex:index];
}
/**
 某一帧持续时长
 */
- (NSTimeInterval)imageDurationAtIndex:(NSUInteger)index{
    if (index >= _imageDecoder.frameCount) return 0;
    dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
    SLImageFrame *imageFrame = _preloadedFrames[index];
    dispatch_semaphore_signal(_preloadedLock);
    if (imageFrame.duration) return imageFrame.duration == 0 ? 0 : imageFrame.duration;
    return [_imageDecoder imageDurationAtIndex:index];
}
/**
 每一帧的字节
 */
- (NSUInteger)imageFrameBytes{
    return _bytesPerFrame;
}
/**
 循环次数
 */
- (NSInteger)loopCount{
    return _imageDecoder.loopCount;
}
/// 循环一次的时长
- (NSTimeInterval)totalTime {
    return _imageDecoder.totalTime;
}

@end
