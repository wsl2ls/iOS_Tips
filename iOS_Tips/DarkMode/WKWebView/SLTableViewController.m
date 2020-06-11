//
//  SLTableViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLTableViewController.h"

@interface SLTableViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

 ///复用池
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *multiplexingPool;

@end

@implementation SLTableViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.scrollView];
}

#pragma mark - Data

#pragma mark - Getter
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.delegate = self;
    }
    return _scrollView;
}
- (NSMutableDictionary *)multiplexingPool {
    if (!_multiplexingPool) {
        _multiplexingPool = [NSMutableDictionary dictionary];
    }
    return _multiplexingPool;;
}

#pragma mark - Help Methods
///刷新数据
- (void)reloadData {
    
}
///注册样式
- (void)registerClass:(Class)class forCellReuseIdentifier:(NSString *)cellID {
    self.multiplexingPool[cellID] = [NSHashTable weakObjectsHashTable];
}
///行数
- (NSInteger)numberOfRowsInScrollView:(UIScrollView *)scrollView {
   return 20;
}
///行高
- (CGFloat)scrollView:(UIScrollView *)scrollView heightForRowAtIndex:(NSInteger)index {
   return 0;
}
///行内容
- (UIView *)scrollView:(UIScrollView *)scrollView cellForRowAtIndex:(NSInteger)index{
    UIView *view = [UIView new];
    view.backgroundColor = SL_UIColorFromRandomColor;
    return view;
}
///点击行
- (void)scrollView:(UIScrollView *)scrollView didSelectRowAtIndex:(NSInteger)index {
    
}

#pragma mark - EventsHandle

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    
}



@end
