//
//  SLOpenGLController.m
//  DarkMode
//
//  Created by wsl on 2019/11/28.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLOpenGLController.h"
#import "SLLoadImageVC.h"
#import "SLCubeViewController.h"
#import "SLShaderLanguageViewController.h"
#import "SLShaderCubeViewController.h"
#import "SLMixColorTextureVC.h"
#import "SLGLKPyramidVC.h"
#import "SLSplitScreenViewController.h"
#import "SLShaderFilterViewController.h"
#import "SLSpecialEffectsViewController.h"

@interface SLOpenGLController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableArray *classArray;
@end

@implementation SLOpenGLController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getData];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}
- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - UI
- (void)setupUI {
    self.navigationItem.title = @"OpenGL-ES学习";
    [self.view addSubview:self.tableView];
}

#pragma mark - Data
- (void)getData {
    //tableView、UIAlertView等系统控件，在不自定义颜色的情况下，默认颜色都是动态的，支持暗黑模式
    [self.dataSource addObjectsFromArray:@[@" GLKit 加载图片",
                                           @" GLKit 绘制正方体",
                                           @" GLKit 颜色和纹理混合金字塔",
                                           @" OpenGL ShaderLanguage（GLSL） 加载图片",
                                           @" GLSL 绘制金字塔", @" GLSL 颜色和纹理混合",
                                           @" GLSL 分屏特效",
                                           @" GLSL 滤镜集合",
                                           @"GLSL 抖音部分特效集合"]];
    [self.classArray addObjectsFromArray:@[[SLLoadImageVC class],
                                           [SLCubeViewController class],
                                           [SLGLKPyramidVC class],
                                           [SLShaderLanguageViewController class],
                                           [SLShaderCubeViewController class],
                                           [SLMixColorTextureVC class],
                                           [SLSplitScreenViewController class],
                                           [SLShaderFilterViewController class],
                                           [SLSpecialEffectsViewController class]]];
    [self.tableView reloadData];
}
#pragma mark - Getter
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 1;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
    }
    return _tableView;
}

#pragma mark - Getter
- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}
- (NSMutableArray *)classArray {
    if (!_classArray) {
        _classArray = [NSMutableArray array];
    }
    return _classArray;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath ];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row,self.dataSource[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIViewController *nextVc = [[self.classArray[indexPath.row] alloc] init];
    nextVc.title = self.dataSource[indexPath.row];
    [self.navigationController pushViewController:nextVc animated:YES];
}

@end
