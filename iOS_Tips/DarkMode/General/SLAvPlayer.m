//
//  SLAvPlayer.m
//  DarkMode
//
//  Created by wsl on 2019/9/20.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLAvPlayer.h"

@interface SLAvPlayer () {
    id _playerTimeObserver;
}
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;  //视频显示器
@end
@implementation SLAvPlayer

+ (instancetype)sharedAVPlayer {
    static SLAvPlayer *avPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        avPlayer = [[SLAvPlayer alloc] init];
    });
    return avPlayer;
}

#pragma mark - OverWrite
- (instancetype)init {
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}
- (void)dealloc {
    [self stop];
}

#pragma mark - HelpMethods
- (void)configure {
}
//视频的方向
- (UIImageOrientation)orientationFromAVAssetTrack:(AVAssetTrack *)videoTrack {
    UIImageOrientation orientation = UIImageOrientationUp;
    CGAffineTransform t = videoTrack.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        orientation = UIImageOrientationRight;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        orientation = UIImageOrientationLeft;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        orientation = UIImageOrientationUp;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        orientation = UIImageOrientationDown;
    }
    return orientation;
}

#pragma mark - Setter
- (void)setUrl:(nonnull NSURL *)url {
    _url = url;
    if (_url == nil) {
        return;
    }
    [self.avPlayer replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:self.url]];
}
- (void)setMonitor:(nullable UIView *)monitor {
    _monitor = monitor;
    if (monitor == nil) {
        [self.playerLayer removeFromSuperlayer];
    }else {
        self.playerLayer.frame = monitor.bounds;
        [monitor.layer insertSublayer:self.playerLayer atIndex:0];
    }
}

#pragma mark - Getter
- (AVPlayer *)avPlayer {
    if (_avPlayer == nil) {
        _avPlayer = [[AVPlayer alloc] init];
        //播放进度观察者 设置每0.1秒执行一次
        __weak typeof(self) weakSelf = self;
        _playerTimeObserver = [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            CGFloat current = CMTimeGetSeconds(time);
            CMTime totalTime = weakSelf.avPlayer.currentItem.duration;
            CGFloat total = CMTimeGetSeconds(totalTime);
            if([weakSelf.delegate respondsToSelector:@selector(avPlayer:playingToCurrentTime:totalTime:)]) {
                [weakSelf.delegate avPlayer:weakSelf playingToCurrentTime:time totalTime:totalTime];
            }
            if (current >= total) {
                //播放完毕
                if([weakSelf.delegate respondsToSelector:@selector(playDidEndOnAvplyer:)]) {
                    [weakSelf pause];
                    [weakSelf.delegate playDidEndOnAvplyer:weakSelf];
                }
            }
        }];
    }
    return _avPlayer;
}
- (AVPlayerLayer *)playerLayer {
    if (_playerLayer == nil) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        _playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        _playerLayer.frame = [UIScreen mainScreen].bounds;
        _playerLayer.videoGravity =AVLayerVideoGravityResizeAspect;
    }
    return _playerLayer;
}
- (CMTime)duration {
    return self.avPlayer.currentItem.duration;
}
- (CGSize)naturalSize {
    AVAsset *asset = [AVAsset assetWithURL:self.url];
    //资源文件的视频轨道
    AVAssetTrack *assetVideoTrack = nil;
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }else {
        return CGSizeZero;
    }
    //    UIImageOrientation orientation = [self orientationFromAVAssetTrack:assetVideoTrack];
    //    //视频素材原大小 像素大小px 不是pt
    //    CGSize renderSize = assetVideoTrack.naturalSize;
    //    if (orientation == UIImageOrientationLeft || orientation == UIImageOrientationRight ) {
    //        renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
    //    }
    CGSize renderSize = assetVideoTrack.naturalSize;
    renderSize = CGSizeApplyAffineTransform(assetVideoTrack.naturalSize, assetVideoTrack.preferredTransform);
    return CGSizeMake(fabs(renderSize.width), fabs(renderSize.height));
}

#pragma mark - EventsHandle
- (void)play {
    [self.avPlayer play];
}
- (void)pause {
    [self.avPlayer pause];
}
- (void)stop {
    [self.avPlayer pause];
    self.avPlayer = nil;
    [_playerLayer removeFromSuperlayer];
    _playerLayer = nil;
    _playerTimeObserver = nil;
    _delegate = nil;
}
- (void)seekToTime:(CMTime)time completionHandler:(void (^_Nullable)(BOOL finished))completionHandler {
    [self.avPlayer.currentItem seekToTime:time completionHandler:completionHandler];
}

@end
