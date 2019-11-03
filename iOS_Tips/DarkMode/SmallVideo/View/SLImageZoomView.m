//
//  SLScrollView.m
//
//  Created by wsl on 2019/10/27.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLImageZoomView.h"

@interface SLImageZoomView ()<UIScrollViewDelegate>
/// 是否正在移动或缩放
@property (nonatomic, assign) BOOL isMoving;
@end

@implementation SLImageZoomView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.clipsToBounds = NO;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
        self.maximumZoomScale = MAXFLOAT;
        self.minimumZoomScale = 1;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        [self setupUI];
    }
    return self;
}
//超出bounce范围，依然可以触发事件
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL inside = [super pointInside:point withEvent:event];
    if (CGRectContainsPoint(self.imageView.frame, point)) {
        inside = YES;
    }
    return inside;;
}
#pragma mark - UI
- (void)setupUI {
    [self addSubview:self.imageView];
}

#pragma mark - Getter
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
//        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}
- (BOOL)isMoving {
    if (!self.isDecelerating && !self.isZooming && !self.isZoomBouncing && !self.isDragging) {
        return YES;
    }else {
        return NO;
    }
}
#pragma mark - Setter
- (void)setImage:(UIImage *)image {
    _image = image;
    self.imageView.image = image;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (!self.isMoving) {
        if ([self.zoomViewDelegate respondsToSelector:@selector(zoomViewDidBeginMoveImage:)]) {
            [self.zoomViewDelegate zoomViewDidBeginMoveImage:self];
        }
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        if (self.isMoving ) {
            if ([self.zoomViewDelegate respondsToSelector:@selector(zoomViewDidEndMoveImage:)]) {
                [self.zoomViewDelegate zoomViewDidEndMoveImage:self];
            }
        }
    }
}
//结束减速
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.isMoving ) {
        if ([self.zoomViewDelegate respondsToSelector:@selector(zoomViewDidEndMoveImage:)]) {
            [self.zoomViewDelegate zoomViewDidEndMoveImage:self];
        }
    }
}

//返回缩放视图
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}
//开始缩放
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view{
    if (!self.isMoving) {
        if ([self.zoomViewDelegate respondsToSelector:@selector(zoomViewDidBeginMoveImage:)]) {
            [self.zoomViewDelegate zoomViewDidBeginMoveImage:self];
        }
    }
}
//结束缩放
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    if (self.isMoving ) {
        if ([self.zoomViewDelegate respondsToSelector:@selector(zoomViewDidEndMoveImage:)]) {
            [self.zoomViewDelegate zoomViewDidEndMoveImage:self];
        }
    }
}
//缩放中
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (scrollView.isZooming || scrollView.isZoomBouncing) {
        // 延中心点缩放
        CGRect rect = CGRectApplyAffineTransform(scrollView.frame, scrollView.transform);
        CGFloat offsetX = (rect.size.width > scrollView.contentSize.width) ? ((rect.size.width - scrollView.contentSize.width) * 0.5) : 0.0;
        CGFloat offsetY = (rect.size.height > scrollView.contentSize.height) ? ((rect.size.height - scrollView.contentSize.height) * 0.5) : 0.0;
        self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    }
}

@end
