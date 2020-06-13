//
//  SLTableViewController.m
//  DarkMode
//
//  Created by wsl on 2020/6/9.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLTableViewController.h"

@interface SLScrollViewCell : UILabel
@property (nonatomic, copy) NSString *cellID;
@end
@implementation SLScrollViewCell
@end

@interface SLTableViewController ()<UIScrollViewDelegate>
{
    UITableView *tableView;
}

@property (nonatomic, strong) UIScrollView *scrollView;
///复用池
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *reusablePool;
/// 每一行的坐标位置
@property (nonatomic, strong) NSMutableArray <NSValue *>*frameArray;
/// 当前可见的cells
@property (nonatomic, strong) NSMutableArray <SLScrollViewCell *>*visibleCells;

///记录最后一次的偏移量，用来判断滑动方向
@property (nonatomic, assign) CGFloat lastContentOffsetY;
///顶部即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexTop;
///底部即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexBottom;

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
    [self registerClass:[SLScrollViewCell class] forCellReuseIdentifier:@"cellID"];
    [self reloadData];
}

#pragma mark - Data

#pragma mark - Getter
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return _scrollView;
}
- (NSMutableDictionary *)reusablePool {
    if (!_reusablePool) {
        _reusablePool = [NSMutableDictionary dictionary];
    }
    return _reusablePool;;
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

#pragma mark - Setter
- (void)setwillDisplayIndexTop:(NSInteger)willDisplayIndexTop{
    _willDisplayIndexTop = willDisplayIndexTop >= 0 ? willDisplayIndexTop : -1;
}
- (void)setwillDisplayIndexBottom:(NSInteger)willDisplayIndexBottom {
    NSInteger count = [self numberOfRowsInScrollView:self.scrollView];
    _willDisplayIndexBottom = willDisplayIndexBottom < count ? willDisplayIndexBottom : count;
}

#pragma mark - Help Methods
///刷新数据
- (void)reloadData {
    //清空布局信息
    [self.frameArray removeAllObjects];
    self.willDisplayIndexTop = -1;
    //数据源个数
    NSInteger count = [self numberOfRowsInScrollView:self.scrollView];
    self.willDisplayIndexBottom = count;
    
    CGFloat y = 0;
    //获取每一行的布局信息
    for (int i = 0; i < count; i++) {
        CGFloat cellHeight = [self scrollView:self.scrollView heightForRowAtIndex:i];
        CGRect rect = CGRectMake(0, y, self.scrollView.sl_width, cellHeight);
        [self.frameArray addObject:[NSValue valueWithCGRect:rect]];
        
        if (rect.origin.y + rect.size.height < self.scrollView.contentOffset.y) {
            self.willDisplayIndexTop = i;
        }
        
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            SLScrollViewCell *cell = [self scrollView:self.scrollView cellForRowAtIndex:i];
            cell.frame = rect;
            [self.scrollView addSubview:cell];
            [self.visibleCells addObject:cell];
        }
        
        if (rect.origin.y > self.scrollView.contentOffset.y + self.scrollView.sl_height && self.willDisplayIndexBottom == count) {
            self.willDisplayIndexBottom = i;
        }
        
        //下一行的起始纵坐标
        y += cellHeight;
        
        //最后 确定了内容大小contentSize
        if (i == count - 1) {
            self.scrollView.contentSize = CGSizeMake(self.scrollView.sl_width, y);
        }
    }
}
//当前可见cell的索引 其实绘制cell的时候就可以先保存可见的索引，不用每次遍历查询
- (NSArray *)indexForVisibleRows {
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSInteger i = self.willDisplayIndexTop+1; i < self.willDisplayIndexBottom; i++) {
        [indexs addObject:@(i)];
    }
    return indexs;
}
//即将显示的cell，显示时创建或从缓存池中取出调整坐标位置 top:YES上/NO下
- (void)willDisplayCellWithDirection:(BOOL)top {
    if(top) {
        if (_willDisplayIndexTop < 0) return;
        NSLog(@"上");
        CGRect rect = [self.frameArray[self.willDisplayIndexTop] CGRectValue];
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            SLScrollViewCell *cell = [self scrollView:self.scrollView cellForRowAtIndex:self.willDisplayIndexTop];
            cell.frame = rect;
            [self.scrollView addSubview:cell];
            self.willDisplayIndexTop -=1;
            [self.visibleCells insertObject:cell atIndex:0];
        }
    }else {
        NSInteger count = [self numberOfRowsInScrollView:self.scrollView];
        if (_willDisplayIndexBottom == count) return;
        NSLog(@"下");
        CGRect rect = [self.frameArray[self.willDisplayIndexBottom] CGRectValue];
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            SLScrollViewCell *cell = [self scrollView:self.scrollView cellForRowAtIndex:self.willDisplayIndexBottom];
            cell.frame = rect;
            [self.scrollView addSubview:cell];
            self.willDisplayIndexBottom +=1;
            [self.visibleCells addObject:cell];
        }
    }
}
//即将消失的cell，在消失时放入缓冲池里   top:YES上/NO下
- (void)willDisappearCellWithDirection:(BOOL)top {
    if(top) {
        CGRect rect = [self.frameArray[self.willDisplayIndexTop+1] CGRectValue];
        if (rect.origin.y + rect.size.height < self.scrollView.contentOffset.y) {
            self.willDisplayIndexTop = self.willDisplayIndexTop+1;
            SLScrollViewCell *cell = self.visibleCells.firstObject;
            NSHashTable * hashTable= self.reusablePool[cell.cellID];
            [hashTable addObject:cell];
            [self.visibleCells removeObjectAtIndex:0];
        }
    }else {
        CGRect rect = [self.frameArray[self.willDisplayIndexBottom-1] CGRectValue];
        if (rect.origin.y > self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            self.willDisplayIndexBottom = self.willDisplayIndexBottom-1;
            SLScrollViewCell *cell = self.visibleCells.lastObject;
            NSHashTable * hashTable= self.reusablePool[cell.cellID];
            [hashTable addObject:cell];
            [self.visibleCells removeLastObject];
        }
    }
}

///根据cellID去复用池reusablePool取可重用的view，如果没有，重新创建一个新对象返回
- (SLScrollViewCell *)dequeueReusableCellWithIdentifier:(nonnull NSString *)cellID{
    NSHashTable *hashTable = self.reusablePool[cellID];
    SLScrollViewCell *cell = hashTable.allObjects.firstObject;
    if (cell == nil) {
        cell = [[SLScrollViewCell alloc] init];
        cell.cellID = cellID;
    }
    return cell;
}
///注册样式
- (void)registerClass:(Class)class forCellReuseIdentifier:(NSString *)cellID {
    self.reusablePool[cellID] = [NSHashTable weakObjectsHashTable];
}
///行数
- (NSInteger)numberOfRowsInScrollView:(UIScrollView *)scrollView {
    return 30;
}
///行高
- (CGFloat)scrollView:(UIScrollView *)scrollView heightForRowAtIndex:(NSInteger)index {
    return 100;
}
///行内容
- (SLScrollViewCell *)scrollView:(UIScrollView *)scrollView cellForRowAtIndex:(NSInteger)index{
    SLScrollViewCell *cell = [self dequeueReusableCellWithIdentifier:@"cellID"];
    cell.layer.borderWidth = 3;
    cell.text = [NSString stringWithFormat:@"第 %ld 个",(long)index];
    cell.textAlignment = NSTextAlignmentCenter;
    return cell;
}
///点击行
- (void)scrollView:(UIScrollView *)scrollView didSelectRowAtIndex:(NSInteger)index {
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView.contentOffset.y > self.lastContentOffsetY) {
        [self willDisplayCellWithDirection:NO];
        [self willDisappearCellWithDirection:YES];
    }else {
        [self willDisplayCellWithDirection:YES];
        [self willDisappearCellWithDirection:NO];
    }
    self.lastContentOffsetY = scrollView.contentOffset.y;
}

@end
