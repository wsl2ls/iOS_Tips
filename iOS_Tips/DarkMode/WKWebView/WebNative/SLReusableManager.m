//
//  SLReusableManager.m
//  DarkMode
//
//  Created by wsl on 2020/6/14.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLReusableManager.h"

@interface SLReusableCell ()
@property (nonatomic, copy) NSString *cellID;
@property (nonatomic, assign) NSInteger index;
@end
@implementation SLReusableCell
@end

///复用管理
@interface SLReusableManager ()

///复用池
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *reusablePool;
///注册的类
@property (nonatomic, strong) NSMutableDictionary *registerClasses;
/// 每一行的坐标位置
@property (nonatomic, strong) NSMutableArray <NSValue *>*frameArray;
/// 当前可见的cells
@property (nonatomic, strong) NSMutableArray <SLReusableCell *>*visibleCells;
///记录最后一次的偏移量，用来判断滑动方向
@property (nonatomic, assign) CGFloat lastContentOffsetY;
///顶部即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexTop;
///底部即将展示的索引
@property (nonatomic, assign) NSInteger willDisplayIndexBottom;

@end
@implementation SLReusableManager

#pragma mark - Override
- (void)dealloc {
    [self removeKVO];
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

#pragma mark - Setter
- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView =scrollView;
    [self addKVO];
}

#pragma mark - KVO
- (void)addKVO {
    [self.scrollView addObserver:self
                      forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
}
- (void)removeKVO{
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if(object == self.scrollView && [keyPath isEqualToString:@"contentOffset"]) {
        if(self.scrollView.contentOffset.y > self.lastContentOffsetY) {
            [self willDisplayCellWithDirection:NO];
            [self willDisappearCellWithDirection:YES];
        }else {
            [self willDisplayCellWithDirection:YES];
            [self willDisappearCellWithDirection:NO];
        }
        self.lastContentOffsetY = self.scrollView.contentOffset.y;
    }
}

#pragma mark - Public
///刷新数据
- (void)reloadData {
    //清空布局信息
    [self.frameArray removeAllObjects];
    for (UIView *subView in self.scrollView.subviews) {
        if ([subView isKindOfClass:[SLReusableCell class]]) {
            [subView removeFromSuperview];
        }
    }
    [self.visibleCells removeAllObjects];
    
    self.willDisplayIndexTop = -1;
    //数据源个数
    NSInteger count = [self.dataSource numberOfRowsInReusableManager:self];
    self.willDisplayIndexBottom = count;
    
    CGFloat y = 0;
    //获取每一行的布局信息
    for (int i = 0; i < count; i++) {
        CGRect rect = [self.dataSource reusableManager:self frameForRowAtIndex:i];
        [self.frameArray addObject:[NSValue valueWithCGRect:rect]];
        
        if (rect.origin.y + rect.size.height < self.scrollView.contentOffset.y) {
            self.willDisplayIndexTop = i;
        }
        
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            SLReusableCell *cell = [self.dataSource reusableManager:self cellForRowAtIndex:i];
            cell.frame = rect;
            [self.scrollView addSubview:cell];
            [self.visibleCells addObject:cell];
        }
        
        if (rect.origin.y > self.scrollView.contentOffset.y + self.scrollView.sl_height && self.willDisplayIndexBottom == count) {
            self.willDisplayIndexBottom = i;
        }
        
        //下一行的起始纵坐标
        y += rect.size.height;
        
        //最后 确定了内容大小contentSize
        if (i == count - 1) {
            self.scrollView.contentSize = CGSizeMake(self.scrollView.sl_width, y);
        }
    }
}
///注册样式
- (void)registerClass:(Class)class forCellReuseIdentifier:(NSString *)cellID {
    self.reusablePool[cellID] = [NSHashTable weakObjectsHashTable];
    self.registerClasses[cellID] = class;
}
///根据cellID从复用池reusablePool取可重用的view，如果没有，重新创建一个新对象返回
- (SLReusableCell *)dequeueReusableCellWithIdentifier:(nonnull NSString *)cellID index:(NSInteger)index{
    NSHashTable *hashTable = self.reusablePool[cellID];
    SLReusableCell *cell = hashTable.allObjects.firstObject;
    if (cell == nil) {
        //复用池reusablePool没有可重用的，就重新创建一个新对象返回
        cell = [[self.registerClasses[cellID] alloc] init];
        cell.cellID = cellID;
        CGRect rect = [self.dataSource reusableManager:self frameForRowAtIndex:index];
        cell.frame = rect;
        cell.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectedAction:)];
        [cell addGestureRecognizer:tap];
    }else {
        //从缓冲池中取出可重用的cell
        [hashTable removeObject:cell];
    }
    cell.index = index;
    return cell;
}
///获取索引为index的cell，如果第index的cell不在可见范围内，返回nil
- (SLReusableCell *)cellForRowAtIndex:(NSInteger)index {
    for (SLReusableCell *cell in self.visibleCells) {
        if (cell.index == index) {
            return cell;
        }
    }
    return nil;
}

#pragma mark - Help Methods
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
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            NSLog(@"上 第 %ld 个cell显示",self.willDisplayIndexTop);
            SLReusableCell *cell = [self.dataSource reusableManager:self cellForRowAtIndex:self.willDisplayIndexTop];
            cell.frame = rect;
            [self.scrollView addSubview:cell];
            self.willDisplayIndexTop -=1;
            [self.visibleCells insertObject:cell atIndex:0];
        }
    }else {
        NSInteger count = [self.dataSource numberOfRowsInReusableManager:self];
        if (_willDisplayIndexBottom >= count) return;
        CGRect rect = [self.frameArray[self.willDisplayIndexBottom] CGRectValue];
        //按需加载 只加载坐标位置是在当前窗口显示的视图
        if (rect.origin.y + rect.size.height >= self.scrollView.contentOffset.y && rect.origin.y <= self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            NSLog(@"下 第 %ld 个cell显示",self.willDisplayIndexBottom);
            SLReusableCell *cell = [self.dataSource reusableManager:self cellForRowAtIndex:self.willDisplayIndexBottom];
            cell.frame = rect;
            [self.scrollView addSubview:cell];
            self.willDisplayIndexBottom +=1;
            [self.visibleCells addObject:cell];
        }
    }
}
//即将消失的cell，在消失时放入缓冲池里，并且重置视图cell的内容   top:YES上/NO下
- (void)willDisappearCellWithDirection:(BOOL)top {
    if(top) {
        if (self.willDisplayIndexTop+1 >= self.frameArray.count) return;
        CGRect rect = [self.frameArray[self.willDisplayIndexTop+1] CGRectValue];
        if (rect.origin.y + rect.size.height < self.scrollView.contentOffset.y) {
            self.willDisplayIndexTop = self.willDisplayIndexTop+1;
            NSLog(@"上 第 %ld 个cell消失",self.willDisplayIndexTop);
            SLReusableCell *cell = self.visibleCells.firstObject;
            
            //进入缓冲池后，要清空重置cell上的内容，防止下一个取出时显示之前的内容，我这里重置时用了自己的默认logo，你可以自己重绘默认时的cell内容
//            for (UIView *subView in cell.subviews) {
//                subView.layer.contents = (__bridge id)[UIImage imageNamed:@"wsl"].CGImage;
//            }
//            cell.layer.contents = (__bridge id)[UIImage imageNamed:@"wsl"].CGImage;
            
            NSHashTable * hashTable= self.reusablePool[cell.cellID];
            [hashTable addObject:cell];
            [self.visibleCells removeObjectAtIndex:0];
        }
    }else {
        if (self.willDisplayIndexBottom-1 < 0) return;
        CGRect rect = [self.frameArray[self.willDisplayIndexBottom-1] CGRectValue];
        if (rect.origin.y > self.scrollView.contentOffset.y + self.scrollView.sl_height) {
            self.willDisplayIndexBottom = self.willDisplayIndexBottom-1;
            NSLog(@"下 第 %ld 个cell消失",self.willDisplayIndexBottom);
            SLReusableCell *cell = self.visibleCells.lastObject;
            
            //进入缓冲池后，要清空重置cell上的内容，防止下一个取出时显示之前的内容，我这里重置时用了自己的默认logo，你可以自己重绘默认时的cell内容
//            for (UIView *subView in cell.subviews) {
//                subView.layer.contents = (__bridge id)[UIImage imageNamed:@"wsl"].CGImage;
//            }
//            cell.layer.contents = (__bridge id)[UIImage imageNamed:@"wsl"].CGImage;
            
            NSHashTable * hashTable= self.reusablePool[cell.cellID];
            [hashTable addObject:cell];
            [self.visibleCells removeLastObject];
        }
    }
}

#pragma mark - Events Handle
- (void)didSelectedAction:(UITapGestureRecognizer *)tap {
    SLReusableCell *cell = (SLReusableCell *)tap.view;
    [self.delegate reusableManager:self didSelectRowAtIndex:cell.index];
}
@end

