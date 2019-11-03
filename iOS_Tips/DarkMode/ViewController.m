//
//  ViewController.m
//  DarkMode
//
//  Created by wsl on 2019/9/16.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "ViewController.h"
#import "SLDarkModeViewController.h"
#import "SLShotViewController.h"


@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self getData];
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
    self.navigationItem.title = @"iOS Tips";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
}

#pragma mark - Data
- (void)getData {
    //tableView、UIAlertView等系统控件，在不自定义颜色的情况下，默认颜色都是动态的，支持暗黑模式
    [self.dataSource addObjectsFromArray:@[@"暗黑/光亮模式", @"AppleId登录应用(查看本仓库下的AddingTheSignInWithAppleFlowToYourApp)", @"微信拍摄功能"]];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

#pragma mark - HelpMethods

#pragma mark - EventsHandle

#pragma mark - UITableViewDelegate, UITableViewDataSource>

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row + 1,self.dataSource[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0: {
            SLDarkModeViewController * darkModeViewController = [[SLDarkModeViewController alloc] init];
            [self.navigationController pushViewController:darkModeViewController animated:YES];
        }
            break;
        case 1: {
            
        }
            break;
        case 2: {
            SLShotViewController * shotViewController = [[SLShotViewController alloc] init];
            shotViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:shotViewController animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}

@end
