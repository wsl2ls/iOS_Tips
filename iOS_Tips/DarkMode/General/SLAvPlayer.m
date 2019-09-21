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

#pragma mark - HelpMethods
- (void)configure {
    _isLoopPlay = YES;
    //监听是否播放完毕
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
}
- (void)dealloc {
    [self stop];
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
        //        [monitor.layer insertSublayer:self.playerLayer atIndex:0];
        [monitor.layer addSublayer:self.playerLayer];
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
        _playerLayer.videoGravity =AVLayerVideoGravityResizeAspectFill;
    }
    return _playerLayer;
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
