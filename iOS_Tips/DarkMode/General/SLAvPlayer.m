//
//  SLAvPlayer.m
//  DarkMode
//
//  Created by wsl on 2019/9/20.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLAvPlayer.h"
#import <AVKit/AVKit.h>

@interface SLAvPlayer ()
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
- (void)setIsLoopPlay:(BOOL)isLoopPlay {
    _isLoopPlay = isLoopPlay;
    //监听是否播放完毕
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
}
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
        //        [monitor.layer addSublayer:self.playerLayer];
    }
}

#pragma mark - Getter
- (AVPlayer *)avPlayer {
    if (_avPlayer == nil) {
        _avPlayer = [[AVPlayer alloc] init];
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
- (CGSize)naturalSize {
    AVAsset *asset = [AVAsset assetWithURL:self.url];
    //资源文件的视频轨道
    AVAssetTrack *assetVideoTrack = nil;
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }else {
        return CGSizeZero;
    }
    UIImageOrientation orientation = [self orientationFromAVAssetTrack:assetVideoTrack];
    //视频素材原大小 像素大小px 不是pt
    CGSize renderSize = assetVideoTrack.naturalSize;
    if (orientation == UIImageOrientationLeft || orientation == UIImageOrientationRight ) {
        renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
    }
    return CGSizeMake(renderSize.width, renderSize.height);
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
//播放完成
- (void)moviePlayDidEnd:(NSNotification*)notification {
    AVPlayerItem*item = [notification object];
    if (_isLoopPlay) {
        [item seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {}];
        [self.avPlayer play];
    }
}

@end
