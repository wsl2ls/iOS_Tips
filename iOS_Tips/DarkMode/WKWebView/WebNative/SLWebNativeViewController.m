//
//  SLWebNativeViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/8.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebNativeViewController.h"
#import <WebKit/WebKit.h>
#import "YYImage.h"
#import <YYWebImage.h>
#import "SLAvPlayer.h"
#import <YYModel.h>
#import "SLReusableManager.h"
#import "SLPictureBrowseController.h"

@interface SLWebNativeModel : NSObject<YYModel>
@property (nonatomic, copy) NSString *tagID; //标签ID
@property (nonatomic, copy) NSString *type; //元素类型
@property (nonatomic, copy) NSString *imgUrl; //图片地址
@property (nonatomic, copy) NSString *videoUrl; //视频地址
@property (nonatomic, copy) NSString *audioUrl; //音频地址
@property (nonatomic, assign) CGFloat width;  //该标签元素内容宽
@property (nonatomic, assign) CGFloat height; //该标签元素内容高
@end
@implementation SLWebNativeModel
@end


@interface SLWebNativeCell : SLReusableCell
@property (nonatomic, strong) YYAnimatedImageView *imageView;
@property (nonatomic, assign) CGSize imageViewSize;
@property (nonatomic, strong) UIImageView *playIcon;
@end
@implementation SLWebNativeCell
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    _imageView = [[YYAnimatedImageView alloc] init];
    [self addSubview:_imageView];
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.mas_equalTo(0);
    }];
    
    _playIcon = [[UIImageView alloc] init];
    _playIcon.image = [UIImage imageNamed:@"play"];
    _playIcon.hidden = YES;
    [_imageView addSubview:_playIcon];
    [_playIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(80, 80));
        make.centerX.mas_equalTo(_imageView.mas_centerX);
        make.centerY.mas_equalTo(_imageView.mas_centerY);
    }];
}

- (void)updateDataWith:(SLWebNativeModel *)model {
    _imageView.layer.contentsRect = CGRectMake(0, 0, 1, 1);
    __weak typeof(self) weakSelf = self;
    [self.imageView yy_setImageWithURL:[NSURL URLWithString:model.imgUrl] placeholder:nil options:YYWebImageOptionShowNetworkActivity completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        if(error) return ;
        if (image.size.width > image.size.height) {
            //宽图
            CGFloat width = weakSelf.imageViewSize.height*image.size.width/image.size.height;
            if (width > weakSelf.imageViewSize.width) {
                CGFloat proportion = weakSelf.imageViewSize.width/width;
                weakSelf.imageView.layer.contentsRect = CGRectMake((1 - proportion)/2, 0, proportion, 1);
            }
        }else if (image.size.width < image.size.height) {
            //长图
            CGFloat height = weakSelf.imageViewSize.width*image.size.height/image.size.width;
            if (height > weakSelf.imageViewSize.height) {
                CGFloat proportion = weakSelf.imageViewSize.height/height;
                weakSelf.imageView.layer.contentsRect = CGRectMake(0,(1 - proportion)/2, 1, proportion);
            }
        }
    }];
    
    if ([model.type isEqualToString:@"image"]) {
        //图片
        _playIcon.hidden = YES;
    }else if ([model.type isEqualToString:@"video"]) {
        //视频
        _playIcon.hidden = NO;
        [_playIcon mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(60, 60));
        }];
    }else if ([model.type isEqualToString:@"audio"]) {
        //音频
        _playIcon.hidden = NO;
        [_playIcon mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
    }
}
@end

/*
 HTML中部分非文本元素，替换为用native组件来实现展示，来达到个性化自定义、灵活、提高渲染效率、简化web和OC交互的处理流程。
 本示例 仅以用native组件替换HTML中的img、video、audio 内容来做展示，当然你也可以替换HTML中其它的标签元素。
 注意：1.用native组件替换时，我们也需要进行一些native组件复用、按需加载的优化处理，类似于tableView的机制。
 2.html界面调整时，要去重新调用JS方法获取原生标签的位置并更新native组件的位置。
 3.如果仅需要处理HTML的图片元素，也可以不用原生组件imageView展示，原生下载处理图片，然后通过oc调用JS设置图片
 */
@interface SLWebNativeViewController ()<WKNavigationDelegate, WKUIDelegate, SLReusableDataSource, SLReusableDelegate, SLPictureAnimationViewDelegate>

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) WKWebView * webView;
/// 网页加载进度视图
@property (nonatomic, strong) UIProgressView * progressView;
/// WKWebView 内容的高度
@property (nonatomic, assign) CGFloat webContentHeight;
/// 原生组件所需的HTML中元素的数据
@property (nonatomic, strong) NSMutableArray <SLWebNativeModel *>*dataSource;

///复用管理
@property (nonatomic, strong) SLReusableManager *reusableManager;
/// 每一行的坐标位置
@property (nonatomic, strong) NSMutableArray <NSValue *>*frameArray;

@end

@implementation SLWebNativeViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self getData];
    [self setupUI];
    [self addKVO];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.progressView removeFromSuperview];
}
- (void)dealloc {
    [self removeKVO];
}

#pragma mark - UI
- (void)setupUI {
    self.navigationItem.title = @"Html非文本元素替换为native组件展示";
    [self.view addSubview:self.webView];
    
    _semaphore = dispatch_semaphore_create(1);
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WebNative.html" ofType:nil];
    NSString *htmlString = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [_webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

#pragma mark - Data
/// 获取原生组件所需的HTML中元素的数据
- (void)getData {
    [self.dataSource removeAllObjects];
    NSData *contentData = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle mainBundle] pathForResource:@"WebNativeJson" ofType:@"txt"]];
    NSDictionary * dataDict = [NSJSONSerialization JSONObjectWithData:contentData options:kNilOptions error:nil];
    for (NSDictionary *dict in dataDict[@"dataList"]) {
        SLWebNativeModel *model = [SLWebNativeModel yy_modelWithDictionary:dict];
        [self.dataSource addObject:model];
    }
}

#pragma mark - Getter
- (WKWebView *)webView {
    if(_webView == nil){
        //创建网页配置
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight) configuration:config];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
    }
    return _webView;
}
- (UIProgressView *)progressView {
    if (!_progressView){
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, 2)];
        _progressView.tintColor = [UIColor blueColor];
        _progressView.trackTintColor = [UIColor clearColor];
    }
    if (_progressView.superview == nil) {
        [self.navigationController.navigationBar addSubview:_progressView];
    }
    return _progressView;
}
- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}
- (SLReusableManager *)reusableManager {
    if (!_reusableManager) {
        _reusableManager = [[SLReusableManager alloc] init];
        _reusableManager.delegate = self;
        _reusableManager.dataSource = self;
        _reusableManager.scrollView = self.webView.scrollView;
        [_reusableManager registerClass:[SLWebNativeCell class] forCellReuseIdentifier:@"cellID"];
    }
    return _reusableManager;
}
- (NSMutableArray *)frameArray {
    if (!_frameArray) {
        _frameArray = [NSMutableArray array];
    }
    return _frameArray;
}

#pragma mark - KVO
///添加键值对监听
- (void)addKVO {
    //监听网页加载进度
    [self.webView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    //监听网页内容高度
    [self.webView.scrollView addObserver:self
                              forKeyPath:@"contentSize"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
}
///移除监听
- (void)removeKVO {
    //移除观察者
    [_webView removeObserver:self
                  forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [_webView.scrollView removeObserver:self
                             forKeyPath:NSStringFromSelector(@selector(contentSize))];
}
//kvo监听 必须实现此方法
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                      context:(void *)context{
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]
        && object == _webView) {
        //        NSLog(@"网页加载进度 = %f",_webView.estimatedProgress);
        self.progressView.progress = _webView.estimatedProgress;
        if (_webView.estimatedProgress >= 1.0f) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.progress = 0;
            });
        }
    }else if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]
              && object == _webView.scrollView) {
        if (_webContentHeight == _webView.scrollView.contentSize.height) {
        }else {
            _webContentHeight = _webView.scrollView.contentSize.height;
        }
    }
}

#pragma mark - WKNavigationDelegate
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.frameArray removeAllObjects];
    //根据服务器下发的标签相关的数据，用原生组件展示，这里原生组件的创建要注意按需加载和复用，类似于tableView，否则对内存还是有不小的消耗的。
    int i = 0;
    SL_WeakSelf;
    for (SLWebNativeModel *model in self.dataSource) {
        NSString *jsString = [NSString stringWithFormat:@"getElementFrame('%@',%f, %f)",model.tagID,model.width,model.height];
        [_webView evaluateJavaScript:jsString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            //获取标签位置坐标
            NSDictionary *frameDict = (NSDictionary *)data;
            CGRect frame = CGRectMake(
                                      [frameDict[@"x"] floatValue], [frameDict[@"y"] floatValue], [frameDict[@"width"] floatValue], [frameDict[@"height"] floatValue]);
            if(!CGRectEqualToRect(frame, CGRectZero)) {
                [weakSelf.frameArray addObject:[NSValue valueWithCGRect:frame]];
            }
            dispatch_semaphore_signal(weakSelf.semaphore);
            if (i == weakSelf.dataSource.count - 1) {
                [weakSelf.reusableManager reloadData];
            }
        }];
        i++;
    }
}

#pragma mark - SLReusableDataSource
- (NSInteger)numberOfRowsInReusableManager:(SLReusableManager *)reusableManager {
    return self.frameArray.count;
}
- (CGRect)reusableManager:(SLReusableManager *)reusableManager frameForRowAtIndex:(NSInteger)index {
    CGRect rect = [self.frameArray[index] CGRectValue];
    return rect;
}
- (SLReusableCell *)reusableManager:(SLReusableManager *)reusableManager cellForRowAtIndex:(NSInteger)index {
    SLWebNativeCell *cell = (SLWebNativeCell *)[reusableManager dequeueReusableCellWithIdentifier:@"cellID" index:index];
    SLWebNativeModel *model = self.dataSource[index];
    cell.imageViewSize = [self.frameArray[index] CGRectValue].size;
    [cell updateDataWith:model];
    return cell;
}

#pragma mark - SLReusableDelegate
- (void)reusableManager:(SLReusableManager *)reusableManager didSelectRowAtIndex:(NSInteger)index {
    SLWebNativeModel *model = self.dataSource[index];
    if ([model.type isEqualToString:@"image"]) {
        //图片
        NSLog(@"点击了 %ld 图片", index);
        SLPictureBrowseController *pictureBrowseController = [[SLPictureBrowseController alloc] init];
        pictureBrowseController.imagesArray = [NSMutableArray arrayWithArray:@[[NSURL URLWithString:model.imgUrl]]];
        pictureBrowseController.indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self presentViewController:pictureBrowseController animated:YES completion:nil];
        
    }else if ([model.type isEqualToString:@"video"]) {
        //视频
        NSLog(@"点击了 %ld 视频", index);
    }else if ([model.type isEqualToString:@"audio"]) {
        //音频
        NSLog(@"点击了 %ld 音频", index);
    }
}

#pragma mark - SLPictureAnimationViewDelegate
//用于转场的动画视图
- (UIView *)animationViewOfPictureTransition:(NSIndexPath *)indexPath {
    SLWebNativeCell *imageCell = (SLWebNativeCell *)[self.reusableManager  cellForRowAtIndex:indexPath.row];
    UIImageView *tempView = [UIImageView new];
    tempView.image = imageCell.imageView.image;
    tempView.layer.contentsRect = imageCell.imageView.layer.contentsRect;
    tempView.frame = [imageCell.imageView convertRect:imageCell.imageView.bounds toView:self.view];
    return tempView;
}

@end
