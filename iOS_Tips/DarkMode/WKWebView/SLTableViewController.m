//
//  SLTableViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLTableViewController.h"

@interface SLTableViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;

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
        _scrollView = [[UIScrollView alloc] init];
    }
    return _scrollView;;
}

#pragma mark - HelpMethods

#pragma mark - EventsHandle

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource


@end
