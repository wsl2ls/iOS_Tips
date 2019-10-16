//
//  SLAvEditExport.m
//  DarkMode
//
//  Created by wsl on 2019/10/14.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLAvEditExport.h"

@interface SLAvEditExport ()
@property (nonatomic, strong) AVAsset *asset;  //资源文件
@property (nonatomic, strong) AVAssetExportSession *exportSession;  //资源导出会话
@property (nonatomic, strong) AVMutableComposition *composition;  //可变工程文件 合并音视频素材
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;  //视频成分
@property (nonatomic, strong) AVMutableAudioMix *audioMix;   // 音频混合
@end

@implementation SLAvEditExport

- (id)initWithAsset:(AVAsset *)asset {
    self = [super init];
    if (self) {
        _asset = asset;
        _timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration);
        _rate = 1.f;
        _isNativeAudio = YES;
    }
    return self;
}
#pragma mark - Event Handle
// 导出编辑的视频
- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(NSError *error))handler progress:(void (^)(float progress))progress {
    [_exportSession cancelExport];
    _exportSession = nil;
    _composition = nil;
    _videoComposition = nil;
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager new];
    //删除原来剪辑的视频
    if ([fm fileExistsAtPath:self.outputURL.path]) {
        if (![fm removeItemAtURL:self.outputURL error:&error]) {
            NSLog(@"removeTrimPath error: %@ \n",[error localizedDescription]);
        }
    }
    if (self.asset.duration.timescale == 0 || self.exportSession == nil) {
        /** 这个情况AVAssetExportSession会卡死 */
        NSError *failError = [NSError errorWithDomain:@"SLVideoExportSessionError" code:(-100) userInfo:@{NSLocalizedDescriptionKey:@"exportSession init fail"}];
        if (handler) handler(failError);
        return;
    }
    
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"视频导出失败: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"视频导出成功");
                    break;
                default:
                    break;
            }
            if ([self.exportSession status] == AVAssetExportSessionStatusCompleted && [fm fileExistsAtPath:self.outputURL.path]) {
                if (handler) handler(nil);
            } else {
                if (handler) handler(self.exportSession.error);
            }
        });
    }];
}

#pragma mark - Getter
- (AVAssetExportSession *)exportSession {
    if (!_exportSession) {
        //导出会话
        _exportSession = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:AVAssetExportPresetHighestQuality];
        /** 创建混合视频时开始剪辑 */
        _exportSession.timeRange = self.timeRange;
        _exportSession.videoComposition = self.videoComposition;
        _exportSession.outputURL = self.outputURL;
        _exportSession.outputFileType = AVFileTypeMPEG4;
        _exportSession.audioMix = self.audioMix;
    }
    return _exportSession;
}
- (AVMutableComposition *)composition {
    if (!_composition) {
        _composition = [[AVMutableComposition alloc] init];
    }
    return _composition;
}
- (AVMutableVideoComposition *)videoComposition {
    if (!_videoComposition) {
        _videoComposition = [AVMutableVideoComposition videoComposition];
        _videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
        //资源文件的视频轨道
        AVAssetTrack *assetVideoTrack = nil;
        // 是否包含视频轨道
        if ([[self.asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
            assetVideoTrack = [self.asset tracksWithMediaType:AVMediaTypeVideo][0];
        }
        CMTime insertionPoint = kCMTimeZero;
        NSError *error = nil;
        // 添加视频轨道和素材 并裁剪视频
        if (assetVideoTrack != nil) {
            // 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
            AVMutableCompositionTrack *compositionVideoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            // 视频方向
            [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
            // 把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
            [compositionVideoTrack insertTimeRange:self.timeRange ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
            [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, self.timeRange.duration) toDuration:CMTimeMake(self.timeRange.duration.value/self.rate, self.timeRange.duration.timescale)];
        }
        //视频方向
        UIImageOrientation orientation = [self orientationFromAVAssetTrack:assetVideoTrack];
        CGAffineTransform transform = CGAffineTransformIdentity;
        //视频素材原大小  像素大小px 不是pt
        CGSize renderSize = assetVideoTrack.naturalSize;
        switch (orientation) {
            case UIImageOrientationLeft:
                //顺时针旋转270°
                //            NSLog(@"视频旋转270度，home按键在右");
                transform = CGAffineTransformTranslate(transform, 0.0, assetVideoTrack.naturalSize.width);
                transform = CGAffineTransformRotate(transform,M_PI_2*3.0);
                renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
                break;
            case UIImageOrientationRight:
                //顺时针旋转90°
                //            NSLog(@"视频旋转90度,home按键在左");
                transform = CGAffineTransformTranslate(transform, assetVideoTrack.naturalSize.height, 0.0);
                transform = CGAffineTransformRotate(transform,M_PI_2);
                renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
                break;
            case UIImageOrientationDown:
                //顺时针旋转180°
                //            NSLog(@"视频旋转180度，home按键在上");
                transform = CGAffineTransformTranslate(transform, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
                transform = CGAffineTransformRotate(transform,M_PI);
                renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
                break;
            default:
                break;
        }
        _videoComposition.renderSize = renderSize;
        
        /** iOS9之前的处理方法，之后使用CIFilter ，待学习*/
        if (orientation != UIImageOrientationUp) {
            AVAssetTrack *videoTrack = [self.composition tracksWithMediaType:AVMediaTypeVideo][0];
            AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition.duration);
            AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            [roateLayerInstruction setTransform:transform atTime:kCMTimeZero];
            roateInstruction.layerInstructions = @[roateLayerInstruction];
            //将视频方向旋转加入到视频处理中
            _videoComposition.instructions = @[roateInstruction];
        }
        /** 涂鸦 贴图  文字 */
        if(self.graffitiView || self.stickerLayers.count) {
            CALayer *parentLayer = [CALayer layer];
            CALayer *videoLayer = [CALayer layer];
            parentLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
            videoLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
            [parentLayer addSublayer:videoLayer];
            //涂鸦层
            CALayer *graffitiLayer = [self graffitiViewLayer:renderSize];
            [parentLayer addSublayer:graffitiLayer];
            //贴画层
            for (CALayer *gifLayer in self.stickerLayers) {
                //注意!：Layer的frame里的单位是px 不是pt
                CGRect changeRect =CGRectMake(CGRectGetMinX(gifLayer.frame)*[UIScreen mainScreen].scale, CGRectGetMinY(gifLayer.frame)*[UIScreen mainScreen].scale, CGRectGetWidth(gifLayer.frame)*[UIScreen mainScreen].scale, CGRectGetHeight(gifLayer.frame)*[UIScreen mainScreen].scale);
                gifLayer.frame = CGRectMake(CGRectGetMinX(changeRect), renderSize.height - CGRectGetMaxY(changeRect), CGRectGetWidth(changeRect), CGRectGetHeight(changeRect));
                [parentLayer addSublayer:gifLayer];
            }
            //文字层
            
            _videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        }
    }
    return _videoComposition;
}
- (AVMutableAudioMix *)audioMix {
    if (!_audioMix) {
        //音频轨道
        AVAssetTrack *assetAudioTrack = nil;
        if ([[self.asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
            assetAudioTrack = [self.asset tracksWithMediaType:AVMediaTypeAudio][0];
        }
        CMTime insertionPoint = kCMTimeZero;
        NSError *error = nil;
        if (assetAudioTrack != nil && _isNativeAudio) {
            AVMutableCompositionTrack *compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            compositionAudioTrack.preferredTransform = assetAudioTrack.preferredTransform;
            [compositionAudioTrack insertTimeRange:self.timeRange ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
            [compositionAudioTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, self.timeRange.duration) toDuration:CMTimeMake(self.timeRange.duration.value/self.rate, self.timeRange.duration.timescale)];
        }
        
        /// 创建额外音轨特效
        NSMutableArray<AVAudioMixInputParameters *> *inputParameters;
        if (self.audioUrls.count) {
            inputParameters = [@[] mutableCopy];
        }
        /// 添加其他音频
        for (NSURL *audioUrl in self.audioUrls) {
            /** 声音采集 */
            AVURLAsset *audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
            AVAssetTrack *additional_assetAudioTrack = nil;
            /** 检查是否有效音轨 */
            if ([[audioAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
                additional_assetAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
            }
            if (additional_assetAudioTrack) {
                AVMutableCompositionTrack *additional_compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                additional_compositionAudioTrack.preferredTransform = additional_assetAudioTrack.preferredTransform;
                [additional_compositionAudioTrack insertTimeRange:self.timeRange ofTrack:additional_assetAudioTrack atTime:insertionPoint error:&error];
                [additional_compositionAudioTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, self.timeRange.duration) toDuration:CMTimeMake(self.timeRange.duration.value/self.rate, self.timeRange.duration.timescale)];
                
                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:additional_compositionAudioTrack];
                mixParameters.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;
                [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:0.3 timeRange:CMTimeRangeMake(kCMTimeZero, self.timeRange.duration)];
                [inputParameters addObject:mixParameters];
            }
        }
        if (inputParameters.count) {
            self.audioMix = [AVMutableAudioMix audioMix];
            self.audioMix.inputParameters = inputParameters;
        }
    }
    return _audioMix;
}

#pragma mark - Help Methods
//生成涂鸦层
- (CALayer *)graffitiViewLayer:(CGSize)size {
    UIImage *watermarkImage = [self graffitiImageForVideoSize:size];
    CALayer *graffitiLayer = [CALayer layer];
    graffitiLayer.contentsScale = [UIScreen mainScreen].scale;
    if (watermarkImage) {
        graffitiLayer.contents = (__bridge id _Nullable)(watermarkImage.CGImage);
    }
    graffitiLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [graffitiLayer setMasksToBounds:YES];
    return graffitiLayer;
}
// 涂鸦 截图
- (UIImage *)graffitiImageForVideoSize:(CGSize)videoSize {
    UIView *graffitiView = self.graffitiView;
    if (graffitiView) {
        CGRect rect = graffitiView.frame;
        /** 参数取整，否则可能会出现1像素偏差 */
        /** 有小数部分才调整差值 */
#define lfme_export_fixDecimal(d) ((fmod(d, (int)d)) > 0.59f ? ((int)(d+0.5)*1.f) : (((fmod(d, (int)d)) < 0.59f && (fmod(d, (int)d)) > 0.1f) ? ((int)(d)*1.f+0.5f) : (int)(d)*1.f))
        rect.origin.x = lfme_export_fixDecimal(rect.origin.x);
        rect.origin.y = lfme_export_fixDecimal(rect.origin.y);
        rect.size.width = lfme_export_fixDecimal(rect.size.width);
        rect.size.height = lfme_export_fixDecimal(rect.size.height);
#undef lfme_export_fixDecimal
        CGSize size = rect.size;
        //1.开启上下文
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        //2.绘制图层
        [graffitiView.layer renderInContext: context];
        //3.从上下文中获取新图片
        UIImage *watermarkImage = UIGraphicsGetImageFromCurrentImageContext();
        //4.关闭图形上下文
        UIGraphicsEndImageContext();
        /** 缩放至视频大小 */
        UIGraphicsBeginImageContextWithOptions(videoSize, NO, 1);
        [watermarkImage drawInRect:CGRectMake(0, 0, videoSize.width, videoSize.height)];
        UIImage *generatedWatermarkImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return generatedWatermarkImage;
    }
    return nil;
}
//视频的方向
- (UIImageOrientation)orientationFromAVAssetTrack:(AVAssetTrack *)videoTrack {
    UIImageOrientation orientation = UIImageOrientationUp;
    CGAffineTransform t = videoTrack.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        // Portrait
        //        degress = 90;
        orientation = UIImageOrientationRight;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        // PortraitUpsideDown
        //        degress = 270;
        orientation = UIImageOrientationLeft;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        // LandscapeRight
        //        degress = 0;
        orientation = UIImageOrientationUp;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        // LandscapeLeft
        //        degress = 180;
        orientation = UIImageOrientationDown;
    }
    return orientation;
}

@end
