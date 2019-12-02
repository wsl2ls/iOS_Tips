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

@interface SLOpenGLController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
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
    [self.dataSource addObjectsFromArray:@[@"GLKit 加载一张图片", @" GLKit 绘制一个正方体", @"OpenGLES-Shader Language 加载一张图片"]];
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

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row,self.dataSource[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0: {
            SLLoadImageVC *loadImageVC = [[SLLoadImageVC alloc] init];
            loadImageVC.title = self.dataSource[indexPath.row];
            [self.navigationController pushViewController:loadImageVC animated:YES];
        }
            break;
        case 1: {
            SLCubeViewController *cubeViewController = [[SLCubeViewController alloc] init];
            cubeViewController.title = self.dataSource[indexPath.row];
            [self.navigationController pushViewController:cubeViewController animated:YES];
        }
            break;
        case 2: {
            SLShaderLanguageViewController *shaderLanguage = [[SLShaderLanguageViewController alloc] init];
            shaderLanguage.title = self.dataSource[indexPath.row];
            [self.navigationController pushViewController:shaderLanguage animated:YES];
        }
            break;
            
        default:
            break;
    }
}

@end
