//
//  SLTableViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLTableViewController.h"

@interface SLTableViewCell : UIButton
@property (nonatomic, copy) NSString *cellID;
@property (nonatomic, assign) NSInteger index;
@end
@implementation SLTableViewCell
@end

@class SLTableView;
@protocol SLTableViewDataSource <NSObject>
@required
///行数
- (NSInteger)numberOfRowsInTableView:(SLTableView *)tableView;
///行高
- (CGFloat)tableView:(SLTableView *)tableView heightForRowAtIndex:(NSInteger)index;
///行内容
- (SLTableViewCell *)tableView:(SLTableView *)tableView cellForRowAtIndex:(NSInteger)index;
@end
@protocol SLTableViewDelegate <NSObject, UIScrollViewDelegate>
///选中行
- (void)tableView:(SLTableView *)tableView didSelectRowAtIndex:(NSInteger)index;
@end

@interface SLTableView : UIScrollView
///复用池
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *reusablePool;
///注册的类
@property (nonatomic, strong) NSMutableDictionary *registerClasses;
/// 每一行的坐标位置
@property (nonatomic, strong) NSMutableArray <NSValue *>*frameArray;
/// 当前可见的cells
@property (nonatomic, strong) NSMutableArray <SLTableViewCell *>*visibleCells;
///记录最后一次的偏移量，用来判断滑动方向
@property (nonatomic, assign) CGFloat lastContentOffsetY;
///顶部即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexTop;
///底部即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexBottom;
///数据源代理
@property (nonatomic, weak) id<SLTableViewDelegate>delegate;
///数据源代理
@property (nonatomic, weak) id<SLTableViewDataSource>dataSource;
@end

@implementation SLTableView
@dynamic delegate;
#pragma mark - Override
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview) {
        [self addKVO];
    }
}
- (void)dealloc {
    [self removeKVO];
}

#pragma mark - Setter
- (void)setDelegate:(id<SLTableViewDelegate>)delegate{
    [super setDelegate:delegate];
}
#pragma mark - Getter
- (NSMutableDictionary *)reusablePool {
    if (!_reusablePool) {
        _reusablePool = [NSMutableDictionary dictionary];
    }
    return _reusablePool;;
}
- (NSMutableDictionary *)registerClasses {
    if (!_registerClasses) {
        _registerClasses = [NSMutableDictionary dictionary];
    }
    return _registerClasses;
}
- (NSMutableArray *)frameArray {
    if (!_frameArray) {
        _frameArray = [NSMutableArray array];
    }
    return _frameArray;
}
- (NSMutableArray *)visibleCells {
    if (!_visibleCells) {
        _visibleCells = [NSMutableArray array];
    }
    return _visibleCells;;
}
- (id<SLTableViewDelegate>)delegate{
    id curDelegate = [super delegate];
    return curDelegate;
}

#pragma mark - KVO
- (void)addKVO {
    [self addObserver:self
           forKeyPath:@"contentOffset"
              options:NSKeyValueObservingOptionNew
              context:nil];
}
- (void)removeKVO{
    [self removeObserver:self forKeyPath:@"contentOffset"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if(object == self && [keyPath isEqualToString:@"contentOffset"]) {
        if(self.contentOffset.y > self.lastContentOffsetY) {
            [self willDisplayCellWithDirection:NO];
            [self willDisappearCellWithDirection:YES];
        }else {
            [self willDisplayCellWithDirection:YES];
            [self willDisappearCellWithDirection:NO];
        }
        self.lastContentOffsetY = self.contentOffset.y;
    }
}

#pragma mark - Help Methods
///刷新数据
- (void)reloadData {
    //清空布局信息
    [self.frameArray removeAllObjects];
    self.willDisplayIndexTop = -1;
    //数据源个数
    NSInteger count = [self.dataSource numberOfRowsInTableView:self];
    self.willDisplayIndexBottom = count;
    
    CGFloat y = 0;
    //获取每一行的布局信息
    for (int i = 0; i < count; i++) {
        CGFloat cellHeight = [self.dataSource tableView:self heightForRowAtIndex:i];
        CGRect rect = CGRectMake(0, y, self.sl_width, cellHeight);
        [self.frameArray addObject:[NSValue valueWithCGRect:rect]];
        
        if (rect.origin.y + rect.size.height < self.contentOffset.y) {
            self.willDisplayIndexTop = i;
        }
        
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.contentOffset.y && rect.origin.y <= self.contentOffset.y + self.sl_height) {
            SLTableViewCell *cell = [self.dataSource tableView:self cellForRowAtIndex:i];
            cell.frame = rect;
            [self addSubview:cell];
            [self.visibleCells addObject:cell];
        }
        
        if (rect.origin.y > self.contentOffset.y + self.sl_height && self.willDisplayIndexBottom == count) {
            self.willDisplayIndexBottom = i;
        }
        
        //下一行的起始纵坐标
        y += cellHeight;
        
        //最后 确定了内容大小contentSize
        if (i == count - 1) {
            self.contentSize = CGSizeMake(self.sl_width, y);
        }
    }
}
///根据cellID从复用池reusablePool取可重用的view，如果没有，重新创建一个新对象返回
- (SLTableViewCell *)dequeueReusableCellWithIdentifier:(nonnull NSString *)cellID index:(NSInteger)index{
    NSHashTable *hashTable = self.reusablePool[cellID];
    SLTableViewCell *cell = hashTable.allObjects.firstObject;
    if (cell == nil) {
        //复用池reusablePool没有可重用的，就重新创建一个新对象返回
        cell = [[self.registerClasses[cellID]  alloc] init];
        [cell addTarget:self action:@selector(didSelectedAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.cellID = cellID;
    }else {
        //从缓冲池中取出可重用的cell
        [hashTable removeObject:cell];
    }
    cell.index = index;
    return cell;
}
///注册样式
- (void)registerClass:(Class)class forCellReuseIdentifier:(NSString *)cellID {
    self.reusablePool[cellID] = [NSHashTable weakObjectsHashTable];
    self.registerClasses[cellID] = class;
}
///当前可见cell的索引 其实绘制cell的时候就可以先保存可见的索引，不用每次遍历查询
- (NSArray *)indexForVisibleRows {
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSInteger i = self.willDisplayIndexTop+1; i < self.willDisplayIndexBottom; i++) {
        [indexs addObject:@(i)];
    }
    return indexs;
}
///即将显示的cell，显示时创建或从缓存池中取出调整坐标位置 top:YES上/NO下
- (void)willDisplayCellWithDirection:(BOOL)top {
    if(top) {
        if (_willDisplayIndexTop < 0) return;
        CGRect rect = [self.frameArray[self.willDisplayIndexTop] CGRectValue];
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.contentOffset.y && rect.origin.y <= self.contentOffset.y + self.sl_height) {
            NSLog(@"上 第 %ld 个cell显示",self.willDisplayIndexTop);
            SLTableViewCell *cell = [self.dataSource tableView:self cellForRowAtIndex:self.willDisplayIndexTop];
            cell.frame = rect;
            [self addSubview:cell];
            self.willDisplayIndexTop -=1;
            [self.visibleCells insertObject:cell atIndex:0];
        }
    }else {
        NSInteger count = [self.dataSource numberOfRowsInTableView:self];
        if (_willDisplayIndexBottom >= count) return;
        CGRect rect = [self.frameArray[self.willDisplayIndexBottom] CGRectValue];
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.contentOffset.y && rect.origin.y <= self.contentOffset.y + self.sl_height) {
            NSLog(@"下 第 %ld 个cell显示",self.willDisplayIndexBottom);
            SLTableViewCell *cell = [self.dataSource tableView:self cellForRowAtIndex:self.willDisplayIndexBottom];
            cell.frame = rect;
            [self addSubview:cell];
            self.willDisplayIndexBottom +=1;
            [self.visibleCells addObject:cell];
        }
    }
}
//即将消失的cell，在消失时放入缓冲池里   top:YES上/NO下
- (void)willDisappearCellWithDirection:(BOOL)top {
    if(top) {
        if (self.willDisplayIndexTop+1 >= self.frameArray.count) return;
        CGRect rect = [self.frameArray[self.willDisplayIndexTop+1] CGRectValue];
        if (rect.origin.y + rect.size.height < self.contentOffset.y) {
            self.willDisplayIndexTop = self.willDisplayIndexTop+1;
            NSLog(@"上 第 %ld 个cell消失",self.willDisplayIndexTop);
            SLTableViewCell *cell = self.visibleCells.firstObject;
            NSHashTable * hashTable= self.reusablePool[cell.cellID];
            [hashTable addObject:cell];
            [self.visibleCells removeObjectAtIndex:0];
        }
    }else {
        if (self.willDisplayIndexBottom-1 < 0) return;
        CGRect rect = [self.frameArray[self.willDisplayIndexBottom-1] CGRectValue];
        if (rect.origin.y > self.contentOffset.y + self.sl_height) {
            self.willDisplayIndexBottom = self.willDisplayIndexBottom-1;
            NSLog(@"下 第 %ld 个cell消失",self.willDisplayIndexBottom);
            SLTableViewCell *cell = self.visibleCells.lastObject;
            NSHashTable * hashTable= self.reusablePool[cell.cellID];
            [hashTable addObject:cell];
            [self.visibleCells removeLastObject];
        }
    }
}

#pragma mark - Events Handle
- (void)didSelectedAction:(SLTableViewCell *)cell {
    [self.delegate tableView:self didSelectRowAtIndex:cell.index];
}
@end

@interface SLTableViewController ()<SLTableViewDataSource, SLTableViewDelegate>
@property (nonatomic, strong) SLTableView *tableView;
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
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (SLTableView *)tableView {
    if (!_tableView) {
        _tableView = [[SLTableView alloc] initWithFrame:self.view.bounds];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        [_tableView registerClass:[SLTableViewCell class] forCellReuseIdentifier:@"cellID"];
    }
    return _tableView;
}

#pragma mark - SLTableViewDataSource
///行数
- (NSInteger)numberOfRowsInTableView:(SLTableView *)tableView {
    return 40;
}
///行高
- (CGFloat)tableView:(SLTableView *)tableView heightForRowAtIndex:(NSInteger)index {
    return 100;
}
///行内容
- (SLTableViewCell *)tableView:(SLTableView *)tableView cellForRowAtIndex:(NSInteger)index {
    SLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" index:index];
    cell.layer.borderWidth = 3;
    [cell setTitle:[NSString stringWithFormat:@"第 %ld 个",(long)index] forState:UIControlStateNormal];
    [cell setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    cell.titleLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

#pragma mark - SLTableViewDelegate
///选中行
- (void)tableView:(SLTableView *)tableView didSelectRowAtIndex:(NSInteger)index {
    NSLog(@"选中 %ld",(long)index);
}
@end
