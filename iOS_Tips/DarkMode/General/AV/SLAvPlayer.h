//
//  SLAvPlayer.h
//  DarkMode
//
//  Created by wsl on 2019/9/20.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SLAvPlayer;
@protocol SLAvPlayerDelegate <NSObject>
@optional
/// 播放中
/// @param avPlayer 播放器
/// @param currentTime 当前时间
/// @param totalTime 总时间
- (void)avPlayer:(SLAvPlayer *)avPlayer playingToCurrentTime:(CMTime)currentTime totalTime:(CMTime)totalTime;
/// 播放结束 暂停
- (void)playDidEndOnAvplyer:(SLAvPlayer *)avPlayer;
@end

///  简易播放器
@interface SLAvPlayer : NSObject
/// 播放源
@property (nonatomic, strong) NSURL *url;
/// 视频尺寸  单位像素 px
@property (nonatomic, assign, readonly) CGSize naturalSize;
/// 总时长
@property (nonatomic, assign, readonly) CMTime duration;
/// 视频展示区域  显示器
@property (nonatomic, strong, nullable) UIView *monitor;
/// 代理
@property (nonatomic, weak) id <SLAvPlayerDelegate> delegate;

+ (instancetype)sharedAVPlayer;
///开始播放
- (void)play;
///暂停
- (void)pause;
///结束播放 销毁播放器
- (void)stop;
///跳转到time节点并暂停
- (void)seekToTime:(CMTime)time completionHandler:(void (^_Nullable)(BOOL finished))completionHandler;
@end

NS_ASSUME_NONNULL_END
