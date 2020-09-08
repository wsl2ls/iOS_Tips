//
//  SLScrollViewWeibo.m
//  DarkMode
//
//  Created by wsl on 2020/9/8.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLScrollViewWeibo.h"
#import "SLMenuView.h"
#import <MJRefresh.h>
#import "SLPanTableView.h"

@interface SLScrollViewWeibo ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate, SLMenuViewDelegate>

@property (nonatomic, strong) UIView *navigationView;
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, assign) BOOL isTopHovering;  //正在顶部悬停

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) SLMenuView *menuView;
@property (nonatomic, strong) UIScrollView *tabScrollView;

@property (nonatomic, assign) NSInteger dataCount; //默认 20
@end

@implementation SLScrollViewWeibo

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}



@end
