//
//  SLMenuView.m
//  DarkMode
//
//  Created by wsl on 2020/9/3.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLMenuView.h"


@interface SLMenuViewCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@end
@implementation SLMenuViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.contentView);
    }];
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}
@end

@interface SLMenuView ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *indicatorView;
@end
@implementation SLMenuView

#pragma mark - Override
- (void)didMoveToSuperview {
    if (self.superview) {
        [self setupUI];
    }
}
- (void)didMoveToWindow {
    if (self.superview) {
        [self setupUI];
    }
}
- (void)layoutSubviews {
    self.collectionView.frame = self.bounds;
    NSInteger count = self.titles.count == 0 ? 1 : self.titles.count;
    self.indicatorView.frame = CGRectMake(_currentPage*self.bounds.size.width/count, self.bounds.size.height-2, self.bounds.size.width/count, 2);
}

#pragma mark - UI
- (void)setupUI {
    [self addSubview:self.collectionView];
    [self addSubview:self.indicatorView];
}

#pragma mark - Getter
- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[SLMenuViewCell class] forCellWithReuseIdentifier:@"ItemId"];
    }
    return _collectionView;
}
- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] init];
        _indicatorView.backgroundColor = [UIColor colorWithRed:11/255.0 green:112/255.0 blue:230/255.0 alpha:1.0];
    }
    return _indicatorView;
}

#pragma mark - Setter
- (void)setCurrentPage:(NSInteger)currentPage {
    _currentPage = currentPage;
    NSInteger count = self.titles.count == 0 ? 1 : self.titles.count;
    self.indicatorView.frame = CGRectMake(_currentPage*self.bounds.size.width/count, self.bounds.size.height-2, self.bounds.size.width/count, 2);
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titles.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SLMenuViewCell * item = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemId" forIndexPath:indexPath];
    item.titleLabel.text = self.titles[indexPath.row];
    if (indexPath.row == self.currentPage) {
        item.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        item.titleLabel.textColor = [UIColor colorWithRed:11/255.0 green:112/255.0 blue:230/255.0 alpha:1.0];
    }else {
        item.titleLabel.font = [UIFont systemFontOfSize:15];
        item.titleLabel.textColor = [UIColor blackColor];
    }
    return item;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    [self.delegate menuView:self didSelectItemAtIndex:indexPath.row];
}

#pragma mark -  UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.bounds.size.width/self.titles.count, self.bounds.size.height);
}
//列间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
//行间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

@end
