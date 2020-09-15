//
//  SLScrollviewNesteVC.m
//  DarkMode
//
//  Created by wsl on 2020/9/2.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLScrollviewNesteVC.h"
#import "SLScrollViewJuejin.h"
#import "SLScrollViewWeibo.h"
#import "SLScrollViewJianShu.h"

@interface SLScrollviewNesteVC ()
@property (nonatomic, strong) NSMutableArray *titlesArray;
@property (nonatomic, strong) NSMutableArray *classArray;
@end

@implementation SLScrollviewNesteVC

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
    self.navigationController.navigationBar.translucent = YES;
    self.tableView.estimatedRowHeight = 1;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
}

#pragma mark - Data
- (void)getData {
    [self.titlesArray addObjectsFromArray:@[
        @"掘金APP个人中心页样式",
        @"微博发现页ScrollView嵌套样式",
        @"简书APP个人中心页样式"]];
    [self.classArray addObjectsFromArray:@[[SLScrollViewJuejin class],
                                           [SLScrollViewWeibo class],
                                           [SLScrollViewJianShu class]]];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (NSMutableArray *)titlesArray {
    if (_titlesArray == nil) {
        _titlesArray = [NSMutableArray array];
    }
    return _titlesArray;
}
- (NSMutableArray *)classArray {
    if (_classArray == nil) {
        _classArray = [NSMutableArray array];
    }
    return _classArray;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titlesArray.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text =  [NSString stringWithFormat:@"%ld、%@",(long)indexPath.row,self.titlesArray[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIViewController *nextVc = [[self.classArray[indexPath.row] alloc] init];
    nextVc.navigationItem.title = self.titlesArray[indexPath.row];
    [self.navigationController pushViewController:nextVc animated:YES];
}

@end
