//
//  SLWebTableViewController3.m
//  DarkMode
//
//  Created by wsl on 2020/5/27.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLWebTableViewController3.h"
#import <WebKit/WebKit.h>
#import "SLDynamicItem.h"
#import "UIScrollView+SLCommon.h"

@interface SLWebTableViewController3 ()<UITableViewDelegate,UITableViewDataSource, UIDynamicAnimatorDelegate,WKNavigationDelegate,UIGestureRecognizerDelegate>
{
    int _dataCount;  //tableView的数据个数
}

@property (nonatomic, strong) WKWebView * webView;
@property (nonatomic, strong) UITableView *tableView;
///网页加载进度视图
@property (nonatomic, strong) UIProgressView * progressView;
/// WKWebView 内容的高度 
@property (nonatomic, assign) CGFloat webContentHeight;

/// self.view拖拽手势
@property(nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
/// 顶部、底部最大弹性距离
@property(nonatomic) CGFloat maxBounceDistance;

/*  UIKit 动力学/仿真物理学：https://blog.csdn.net/meiwenjie110/article/details/46771299 */
/// 动力装置  启动力
@property(nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
/// 惯性力    手指滑动松开后，scrollView借助于惯性力，以手指松开时的初速度以及设置的resistance动力减速度运动，直至停止
@property(nonatomic, weak) UIDynamicItemBehavior *inertialBehavior;
/// 吸附力   模拟UIScrollView滑到底部或顶部时的回弹效果
@property(nonatomic, weak) UIAttachmentBehavior *bounceBehavior;

@end

@implementation SLWebTableViewController3

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUi];
    [self addKVO];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.progressView removeFromSuperview];
}
- (void)dealloc {
    [self removeKVO];
}
// 滚动中单击可以停止滚动
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.dynamicAnimator removeAllBehaviors];
}

#pragma mark - SetupUI
- (void)setupUi {
    self.title = @"WKWebView+UITableView（方案3）";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.maxBounceDistance = 100;
    [self.view addGestureRecognizer:self.panRecognizer];
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.webView;
}

#pragma mark - Getter
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight) style:UITableViewStyleGrouped];
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 1;
        _tableView.scrollEnabled = NO;
    }
    return _tableView;
}
- (WKWebView *)webView {
    if(_webView == nil){
        //创建网页配置
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, 1) configuration:config];
        _webView.navigationDelegate = self;
        _webView.scrollView.scrollEnabled = NO;
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
//                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SL_GithubUrl]];
//                [_webView loadRequest:request];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"WebTableView.html" ofType:nil];
        NSString *htmlString = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        [_webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
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
- (UIPanGestureRecognizer *)panRecognizer {
    if (!_panRecognizer) {
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
        _panRecognizer.delegate = self;
    }
    return _panRecognizer;
}

- (UIDynamicAnimator *)dynamicAnimator {
    if (!_dynamicAnimator) {
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        _dynamicAnimator.delegate = self;
    }
    return _dynamicAnimator;
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
              && object == _webView.scrollView && _webContentHeight != _webView.scrollView.contentSize.height) {
        _webContentHeight = _webView.scrollView.contentSize.height;
        [self webViewContentSizeChanged];
    }
}

#pragma mark - EventsHandle
/// 拖拽手势，模拟UIScrollView滑动
- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            //开始拖动，移除之前所有的动力行为
            [self.dynamicAnimator removeAllBehaviors];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [recognizer translationInView:self.view];
            //拖动过程中调整scrollView.contentOffset
            [self scrollViewsSetContentOffsetY:translation.y];
            [recognizer setTranslation:CGPointZero inView:self.view];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            // 这个if是为了避免在拉到边缘时，以一个非常小的初速度松手不回弹的问题
            if (fabs([recognizer velocityInView:self.view].y) < 120) {
                if ([self.tableView sl_isTop] &&
                    [self.webView.scrollView sl_isTop]) {
                    //顶部
                    [self performBounceForScrollView:self.webView.scrollView isAtTop:YES];
                } else if ([self.tableView sl_isBottom] &&
                           [self.webView.scrollView sl_isBottom]) {
                    //底部
                    if (self.tableView.frame.size.height < self.view.sl_height) { //tableView不足一屏，webView bounce
                        [self performBounceForScrollView:self.webView.scrollView isAtTop:NO];
                    } else {
                        [self performBounceForScrollView:self.tableView isAtTop:NO];
                    }
                }
                return;
            }
            
            //动力元素 力的操作对象
            SLDynamicItem *item = [[SLDynamicItem alloc] init];
            item.center = CGPointZero;
            __block CGFloat lastCenterY = 0;
            UIDynamicItemBehavior *inertialBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[item]];
            //给item添加初始线速度 手指松开时的速度
            [inertialBehavior addLinearVelocity:CGPointMake(0, -[recognizer velocityInView:self.view].y) forItem:item];
            //减速度  无速度阻尼
            inertialBehavior.resistance = 2;
            __weak typeof(self) weakSelf = self;
            inertialBehavior.action = ^{
                //惯性力 移动的距离
                [weakSelf scrollViewsSetContentOffsetY:lastCenterY - item.center.y];
                lastCenterY = item.center.y;
            };
             //注意，self.inertialBehavior 的修饰符是weak，惯性力结束停止之后，会释放inertialBehavior对象，self.inertialBehavior = nil
            self.inertialBehavior = inertialBehavior;
            [self.dynamicAnimator addBehavior:inertialBehavior];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Help Methods
/// 根据拖拽手势在屏幕上的拖拽距离，调整scrollView.contentOffset
- (void)scrollViewsSetContentOffsetY:(CGFloat)deltaY {
    if (deltaY < 0) { //上滑
        if ([self.webView.scrollView sl_isBottom]) { //webView已滑到底，此时应滑动tableView
            if ([self.tableView sl_isBottom]) { //tableView也到底
                CGFloat bounceDelta = MAX(0, (self.maxBounceDistance - fabs(self.tableView.contentOffset.y - self.tableView.sl_maxContentOffsetY)) / self.maxBounceDistance) * 0.5;
                self.tableView.contentOffset = CGPointMake(0, self.tableView.contentOffset.y - deltaY * bounceDelta);
                [self performBounceIfNeededForScrollView:self.tableView isAtTop:NO];
            } else {
                self.tableView.contentOffset = CGPointMake(0, MIN(self.tableView.contentOffset.y - deltaY, [self.tableView sl_maxContentOffsetY]));
            }
        } else {
            self.webView.scrollView.contentOffset = CGPointMake(0, MIN(self.webView.scrollView.contentOffset.y - deltaY, [self.webView.scrollView sl_maxContentOffsetY]));
            
        }
    } else if (deltaY > 0) { //下滑
        if ([self.tableView sl_isTop]) { //tableView滑到顶，此时应滑动webView
            if ([self.webView.scrollView sl_isTop]) { //webView到顶
                CGFloat bounceDelta = MAX(0, (self.maxBounceDistance - fabs(self.webView.scrollView.contentOffset.y)) / self.maxBounceDistance) * 0.5;
                self.webView.scrollView.contentOffset = CGPointMake(0, self.webView.scrollView.contentOffset.y - bounceDelta * deltaY);
                [self performBounceIfNeededForScrollView:self.webView.scrollView isAtTop:YES];
            } else {
                //tableView内容到顶后，调整webView.contentOffset
                self.webView.scrollView.contentOffset = CGPointMake(0, MAX(self.webView.scrollView.contentOffset.y - deltaY, 0));
            }
        } else {
            //tableView内容还未到顶，调整tableView.contentOffset
            self.tableView.contentOffset = CGPointMake(0, MAX(self.tableView.contentOffset.y - deltaY, 0));
        }
    }
}

//两种回弹触发方式：
//1.惯性滚动到边缘处回弹
- (void)performBounceIfNeededForScrollView:(UIScrollView *)scrollView isAtTop:(BOOL)sl_isTop {
    if (self.inertialBehavior) {
        [self performBounceForScrollView:scrollView isAtTop:sl_isTop];
    }
}
//2.手指拉到边缘处回弹
- (void)performBounceForScrollView:(UIScrollView *)scrollView isAtTop:(BOOL)isTop {
    if (!self.bounceBehavior) {
        //移除惯性力
        [self.dynamicAnimator removeBehavior:self.inertialBehavior];
        
        //吸附力操作元素
        SLDynamicItem *item = [[SLDynamicItem alloc] init];
        item.center = scrollView.contentOffset;
        //吸附力的锚点Y
        CGFloat attachedToAnchorY = 0;
        if (scrollView == self.tableView) {
            //顶部时吸附力的Y轴锚点是0  底部时的锚点是Y轴最大偏移量
            attachedToAnchorY = isTop ? 0 : [self.tableView sl_maxContentOffsetY];
        }else {
            attachedToAnchorY = 0;
        }
        //吸附力
        UIAttachmentBehavior *bounceBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:CGPointMake(0, attachedToAnchorY)];
        //吸附点的距离
        bounceBehavior.length = 0;
        //阻尼/缓冲
        bounceBehavior.damping = 1;
        //频率
        bounceBehavior.frequency = 2;
        bounceBehavior.action = ^{
            scrollView.contentOffset = CGPointMake(0, item.center.y);
        };
        self.bounceBehavior = bounceBehavior;
        [self.dynamicAnimator addBehavior:bounceBehavior];
    }
}

//webViewContentSize发生了变化，需要针对变化做出调整
- (void)webViewContentSizeChanged {
    // webViewHeight的最大高度为屏幕高度，当内容contentSize不足一屏时，高度为内容contentSize高度。
    CGRect frame = self.webView.frame;
    frame.size.height = self.webView.scrollView.contentSize.height < SL_kScreenHeight ? self.webView.scrollView.contentSize.height : SL_kScreenHeight;
    self.webView.frame = frame;
    self.tableView.tableHeaderView = self.webView;
    //当WebView的contentSize改变时，tableView滚到顶部WebView，tableView展示内容向下移，更新展示区域
    [self.tableView sl_scrollToTopWithAnimated:NO];
}

#pragma mark - UIDynamicAnimatorDelegate
//动力装置即将启动
- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    //    防止误触tableView的点击事件
    self.webView.userInteractionEnabled = NO;
    self.tableView.userInteractionEnabled = NO;
}
//动力装置暂停
- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    self.webView.userInteractionEnabled = YES;
    self.tableView.userInteractionEnabled = YES;
}
#pragma mark - UIGestureRecognizerDelegate
// 避免影响横滑手势
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.view];
    return fabs(velocity.y) > fabs(velocity.x);
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //这里可以在webView加载完成之后，再刷新显示tableView的数据
    _dataCount = 10;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataCount == 0 ? 0 : 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataCount;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [UILabel new];
    label.text = @"评论";
    label.textColor = UIColor.whiteColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor orangeColor];
    return label;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cellId"];
    }
    cell.detailTextLabel.numberOfLines = 0;
    cell.textLabel.text = [NSString stringWithFormat:@"第%ld条评论",(long)indexPath.row];
    cell.detailTextLabel.text = @"方案3：\n WKWebView作为TableView的Header, 但不撑开webView。\n 禁用tableView和webView.scrollVie的scrollEnabled = NO，通过添加pan手势,手动调整contentOffset。\n WebView的最大高度为屏幕高度，当内容不足一屏时，高度为内容高度。和方案2类似，但是不需要插入占位Div";
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
