//
//  SLPictureBrowseController.m
//  TELiveClass
//
//  Created by wsl on 2020/2/28.
//  Copyright © 2020 offcn_c. All rights reserved.
//

#import "SLPictureBrowseController.h"
#import <YYWebImage.h>

/// 图片缩放视图
@interface SLPictureZoomView : UIScrollView<UIScrollViewDelegate>
@property (nonatomic, strong) YYAnimatedImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView; //下载指示器
@property (nonatomic, assign) CGSize imageNormalSize; //图片原尺寸
@end
@implementation SLPictureZoomView

#pragma mark - Override
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - UI
- (void)setupUI {
    self.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
    }
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 2.0;
    self.clipsToBounds  = NO;
    [self addSubview:self.imageView];
}

#pragma mark - Getter
- (YYAnimatedImageView *)imageView {
    if (!_imageView) {
        _imageView = [[YYAnimatedImageView alloc] init];
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}
- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicatorView.frame = CGRectMake(0, 0, 30, 30);
        _indicatorView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0);
    }
    return _indicatorView;
}
- (CGSize)imageNormalSize {
    if (_imageNormalSize.width == 0) {
        _imageNormalSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
    }
    return _imageNormalSize;
}

#pragma mark - HelpMethods
- (void)setImageUrl:(NSURL *)url {
    
    [[YYImageCache sharedCache] getImageForKey:[url absoluteString] withType:YYImageCacheTypeAll withBlock:^(UIImage * _Nullable image, YYImageCacheType type) {
        if (!image) {
            [self.indicatorView startAnimating];
            [self addSubview:self.indicatorView];
        }else {
            [self.indicatorView stopAnimating];
            [self.indicatorView removeFromSuperview];
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    [self.imageView yy_setImageWithURL:url placeholder:nil options:YYWebImageOptionShowNetworkActivity completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        [weakSelf.indicatorView stopAnimating];
        [weakSelf.indicatorView removeFromSuperview];
        if (image == nil) {
            return ;
        }
        weakSelf.imageNormalSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width*image.size.height/image.size.width);
        weakSelf.imageView.frame = CGRectMake(0, 0, weakSelf.imageNormalSize.width, weakSelf.imageNormalSize.height);
        weakSelf.contentSize = weakSelf.imageNormalSize;
        if (weakSelf.imageNormalSize.height <= [UIScreen mainScreen].bounds.size.height) {
            weakSelf.imageView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0);
        }
    }];
}

#pragma mark - UIScrollViewDelegate
//返回缩放的视图
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}
//缩放过程中
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat imageSclaeW = scrollView.zoomScale * self.imageNormalSize.width;
    CGFloat imageSclaeH = scrollView.zoomScale * self.imageNormalSize.height;
    CGFloat imageX = 0;
    CGFloat imageY = 0;
    if (imageSclaeW < self.frame.size.width) {
        imageX = (self.frame.size.width - imageSclaeW)/2.0;
    }
    if (imageSclaeH < self.frame.size.height) {
        imageY = (self.frame.size.height - imageSclaeH)/2.0;
    }
    self.imageView.frame = CGRectMake(imageX, imageY, imageSclaeW, imageSclaeH);
}

@end


#define KSLPictureBrowseSpace 8 // 浏览的图片间隔1/2
/// 图片浏览单元
@interface SLPictureBrowsingCell: UICollectionViewCell
@property (nonatomic, strong) SLPictureZoomView *zoomView;
@end
@implementation SLPictureBrowsingCell

#pragma mark - Override
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - UI
- (void)setupUI {
    [self.contentView addSubview:self.zoomView];
    [self.zoomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView.mas_left).offset(KSLPictureBrowseSpace);
        make.top.bottom.mas_equalTo(self.contentView);
        make.right.mas_equalTo(self.contentView).offset(-KSLPictureBrowseSpace);
    }];
    //解决 self.pictureZoomView 和UICollectionView 手势冲突
    self.zoomView.userInteractionEnabled = NO;
    [self.contentView addGestureRecognizer:self.zoomView.panGestureRecognizer];
    [self.contentView addGestureRecognizer:self.zoomView.pinchGestureRecognizer];
}

#pragma mark - Getter
- (SLPictureZoomView *)zoomView {
    if (!_zoomView) {
        _zoomView = [[SLPictureZoomView alloc] init];
        _zoomView.backgroundColor = [UIColor clearColor];
    }
    return _zoomView;
}
@end

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "SLPictureTransitionAnimation.h"

/// 图集浏览控制器
@interface SLPictureBrowseController ()<UICollectionViewDelegate, UICollectionViewDataSource, UIViewControllerTransitioningDelegate>{
    UIViewController *_fromViewController;
}
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) SLPictureTransitionAnimation *transitionAnimation; //转场动画
@property (nonatomic, assign) NSInteger currentPage; //图片当前页码
@end

@implementation SLPictureBrowseController

#pragma mark - Override
- (id)init {
    self = [super init];
    if (self) {
        self.transitionAnimation = [[SLPictureTransitionAnimation alloc] init];
        self.transitionAnimation.transitionType = SLTransitionTypePresent;
        self.transitioningDelegate = self; //设置了这个属性之后，在present转场动画处理时，转场前的视图fromVC的view一直都在管理转场动画视图的容器containerView中，会被转场后,后加入到containerView中视图toVC的View遮住，类似于入栈出栈的原理；如果没有设置的话，present转场时，fromVC.view就会先出栈从containerView移除，然后toVC.View入栈，那之后再进行disMiss转场返回时，需要重新把fromVC.view加入containerView中。
        //在push转场动画处理时,设置这个属性是没有效果的，也就是没用的。
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)dealloc {
}
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.pageControl];
    [self.view addSubview:self.saveButton];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
        make.left.mas_equalTo(-KSLPictureBrowseSpace);
        make.right.mas_equalTo(KSLPictureBrowseSpace);
    }];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(SL_TopSafeAreaHeight);
    }];
    if (self.imagesArray.count > 1) {
        self.pageControl.numberOfPages = self.imagesArray.count;
        self.pageControl.currentPage = self.currentPage;
        self.pageControl.hidden = NO;
    }else {
        self.pageControl.hidden = YES;
    }
    if(self.imagesArray.count == 1) self.collectionView.scrollEnabled = NO;
    self.collectionView.contentSize = CGSizeMake(self.imagesArray.count * (self.view.frame.size.width + 2 * KSLPictureBrowseSpace), self.view.frame.size.height);
    self.collectionView.contentOffset = CGPointMake(self.currentPage * (self.view.frame.size.width + 2 * KSLPictureBrowseSpace), 0);
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.bottom.mas_equalTo(-25-SL_BottomSafeAreaHeight);
        make.size.mas_equalTo(CGSizeMake(120, 38));
    }];
    
    //添加拖拽手势 拖拽图片退出图集浏览界面
    self.view.userInteractionEnabled = YES;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPicture:)];
    [self.view addGestureRecognizer:pan];
    //单击手势 退出浏览
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.numberOfTouchesRequired = 1;
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
    //双击手势放大
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTouchesRequired = 1;
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    [singleTap requireGestureRecognizerToFail:doubleTap];
}

#pragma mark - Getter
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
        }
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        _collectionView.allowsSelection = NO;
        [_collectionView registerClass:[SLPictureBrowsingCell class] forCellWithReuseIdentifier:@"SLPictureBrowsingCell"];
    }
    return _collectionView;
}
- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.pageIndicatorTintColor = [UIColor grayColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    }
    return _pageControl;
}
- (UIButton *)saveButton {
    if (!_saveButton) {
        _saveButton = [[UIButton alloc] init];
        [_saveButton setTitle:@"保存" forState:UIControlStateNormal];
        [_saveButton setTitleColor:SL_UIColorFromHex(0xffffff,1.0) forState:UIControlStateNormal];
        _saveButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_saveButton setImage:[UIImage imageNamed:@"message_img_download"] forState:UIControlStateNormal];
        _saveButton.backgroundColor = SL_UIColorFromHex(0x393939,1.0);
        _saveButton.layer.masksToBounds = YES;
        _saveButton.layer.cornerRadius = 4;
        [_saveButton addTarget:self action:@selector(saveButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveButton;
}

#pragma mark - HelpMethods
//返回当前页面用于转场动画的视图
- (UIView *)currentAnimatonView {
    SLPictureBrowsingCell *cell = [self.collectionView visibleCells].firstObject;
    if (cell == nil) {
        cell = [[SLPictureBrowsingCell  alloc] initWithFrame: CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height)];
        NSURL *imgUrl = self.imagesArray[self.currentPage];
        [cell.zoomView setImageUrl:imgUrl];
        UIView *tempView = cell.zoomView.imageView;
        return tempView;
    }else {
        UIView *imageView = cell.zoomView.imageView;
        UIView *tempView = [imageView snapshotViewAfterScreenUpdates:YES];
        tempView.frame = [imageView convertRect:imageView.bounds toView:self.view];
        return tempView;
    }
}

#pragma mark - EventsHandle
//拖拽即将推出图片浏览模式
- (void)panPicture:(UIPanGestureRecognizer *)pan {
    SLPictureBrowsingCell *cell = [self.collectionView visibleCells].firstObject;
    SLPictureZoomView *zoomView = cell.zoomView;
    CGPoint translation = [pan translationInView:cell];
    zoomView.center = CGPointMake(zoomView.center.x+translation.x, zoomView.center.y+translation.y);
    [pan setTranslation:CGPointZero inView:cell];
    //滑动的距离百分比
    CGFloat percentComplete = 0;
    percentComplete = (zoomView.center.y - [UIScreen mainScreen].bounds.size.height/2.0)/([UIScreen mainScreen].bounds.size.height/2.0);
    percentComplete = fabs(percentComplete);
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            self.saveButton.hidden = YES;
            break;
        case UIGestureRecognizerStateChanged:
            if  (zoomView.center.y > [UIScreen mainScreen].bounds.size.height/2.0 && percentComplete > 0.01 && percentComplete < 1.0) {
                self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1 - percentComplete];
                zoomView.transform = CGAffineTransformMakeScale(1 - percentComplete/2.0, 1 - percentComplete/2.0);
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (percentComplete >= 0.5 && zoomView.center.y > [UIScreen mainScreen].bounds.size.height/2.0) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }else {
                self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
                [UIView animateWithDuration:0.3 animations:^{
                    zoomView.center = CGPointMake(([UIScreen mainScreen].bounds.size.width+KSLPictureBrowseSpace * 2)/2.0, [UIScreen mainScreen].bounds.size.height/2.0);
                    zoomView.transform = CGAffineTransformMakeScale(1, 1);
                } completion:^(BOOL finished) {
                    self.saveButton.hidden = NO;
                }];
            }
            break;
        default:
            break;
    }
    
}
//单击退出出图片浏览模式
- (void)singleTap:(UITapGestureRecognizer *)singleTap {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//双击放大点击点
- (void)doubleTap:(UITapGestureRecognizer *)doubleTap {
    SLPictureBrowsingCell *cell = [self.collectionView visibleCells].firstObject;
    SLPictureZoomView *zoomView = cell.zoomView;
    //获得触摸点在imageView上的位置
    CGPoint tapPosionOfPicture = [doubleTap locationInView:zoomView.imageView];
    //获得触摸点在zoomView上的位置
    CGPoint tapPosionOfScreen = [doubleTap locationInView:zoomView];
    [UIView animateWithDuration:0.3 animations:^{
        if(zoomView.zoomScale != 1) {
            zoomView.zoomScale = 1;
            [zoomView scrollViewDidZoom:zoomView];
            zoomView.contentOffset = CGPointZero;
        }else {
            //获得点击的图片位置放大后的坐标 相对于ImageView
            CGPoint newTapPosionOfPicture = CGPointMake(tapPosionOfPicture.x*zoomView.maximumZoomScale, tapPosionOfPicture.y*zoomView.maximumZoomScale);
            zoomView.zoomScale = zoomView.maximumZoomScale;
            [zoomView scrollViewDidZoom:zoomView];
            
            if (newTapPosionOfPicture.y < zoomView.frame.size.height || zoomView.imageView.frame.size.height < zoomView.frame.size.height) {
                // 放大后对应的点击点在图片上的位置 处在前一屏当中
                zoomView.contentOffset = CGPointMake(newTapPosionOfPicture.x - tapPosionOfScreen.x, 0);
            } else {  // 点击点在图片上的位置超过一屏时
                if (newTapPosionOfPicture.y > zoomView.imageView.frame.size.height -  zoomView.frame.size.height){
                    // 点击点在图片最底部一屏中
                    zoomView.contentOffset = CGPointMake(newTapPosionOfPicture.x - tapPosionOfScreen.x, zoomView.imageView.frame.size.height -  zoomView.frame.size.height);
                }else{
                    //点击点在图片中间层
                    zoomView.contentOffset = CGPointMake(newTapPosionOfPicture.x - tapPosionOfScreen.x, newTapPosionOfPicture.y - tapPosionOfScreen.y);
                }
            }
        }
    } completion:^(BOOL finished) {
        
    }];
}
//保存
- (void)saveButtonAction:(UIButton *)btn {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) { // 用户还没有做出选择
        // 弹框请求用户授权
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                // 用户第一次同意了访问相册权限
                [self saveImageToPhotosAlbum];
            }
        }];
        return;
    }else if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
        //        [self showOnlyTextWithHint:@"App需要经过您的同意,才能保存图片到相册"];
        return;
    }
    [self saveImageToPhotosAlbum];
}
//保存图片到相册
- (void)saveImageToPhotosAlbum {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = self.imagesArray[self.currentPage];
        [[YYImageCache sharedCache] getImageDataForKey:[url absoluteString] withBlock:^(NSData * _Nullable imageData) {
            if (imageData) {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            //                                      [self showOnlyTextWithHint:@"保存失败"];
                        }else {
                            //                                      [self showOnlyTextWithHint:@"保存成功"];
                        }
                    });
                }];
            }
            
        }];
        
    });
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //四舍五入
    self.currentPage = roundf(scrollView.contentOffset.x/(self.view.frame.size.width + 2 * KSLPictureBrowseSpace));
    self.pageControl.currentPage = self.currentPage;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.currentPage = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.pageControl.currentPage = self.currentPage;
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagesArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    SLPictureBrowsingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SLPictureBrowsingCell" forIndexPath:indexPath];
    NSURL *imgUrl = self.imagesArray[indexPath.row];
    [cell.zoomView setImageUrl:imgUrl];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark -  UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([UIScreen mainScreen].bounds.size.width + 2 * KSLPictureBrowseSpace, self.collectionView.frame.size.height);
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UIViewControllerTransitioningDelegate
// 自定义转场动画
//返回一个处理presente动画过渡的对象
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    _fromViewController = source;
    self.transitionAnimation.transitionType = SLTransitionTypePresent;
    if([source conformsToProtocol:@protocol(SLPictureAnimationViewDelegate)]) {
        if ([source respondsToSelector:@selector(animationViewOfPictureTransition:)]) {
            self.transitionAnimation.fromAnimatonView = [source performSelector:@selector(animationViewOfPictureTransition:) withObject:self.indexPath];
        }
    }
    self.transitionAnimation.toAnimatonView = [self currentAnimatonView];
    return self.transitionAnimation;
}
//返回一个处理dismiss动画过渡的对象
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.transitionAnimation.transitionType = SLTransitionTypeDissmiss;
    if([_fromViewController conformsToProtocol:@protocol(SLPictureAnimationViewDelegate)]) {
        if ([_fromViewController respondsToSelector:@selector(animationViewOfPictureTransition:)]) {
            self.transitionAnimation.toAnimatonView = [_fromViewController performSelector:@selector(animationViewOfPictureTransition:) withObject:self.indexPath];
        }
    }
    self.transitionAnimation.fromAnimatonView = [self currentAnimatonView];;
    return self.transitionAnimation;
}

@end
