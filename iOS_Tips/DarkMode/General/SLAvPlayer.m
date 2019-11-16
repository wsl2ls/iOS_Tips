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
    [_avPlayer pause];
    _avPlayer = nil;
    [_playerLayer removeFromSuperlayer];
    _playerLayer = nil;
    _playerTimeObserver = nil;
    _delegate = nil;
}
- (void)seekToTime:(CMTime)time completionHandler:(void (^_Nullable)(BOOL finished))completionHandler {
    [self.avPlayer.currentItem seekToTime:time completionHandler:completionHandler];
}

@end
