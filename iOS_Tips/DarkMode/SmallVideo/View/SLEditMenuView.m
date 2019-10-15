//
//  SLEditMenuView.m
//  DarkMode
//
//  Created by wsl on 2019/10/9.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditMenuView.h"
#import "SLImageView.h"
#import "SLImage.h"

/// 涂鸦子菜单 画笔颜色选择
@interface SLSubmenuGraffitiView : UIView
@property (nonatomic, assign) int currentIndex; // 当前画笔颜色索引
@property (nonatomic, strong) UIColor *currentColor; // 当前画笔颜色
@property (nonatomic, copy) void(^selectedLineColor)(UIColor *lineColor); //选中颜色的回调
@property (nonatomic, copy) void(^goBack)(void); //返回上一步
@end
@implementation  SLSubmenuGraffitiView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentIndex = 0;
        _currentColor = [UIColor whiteColor];
    }
    return self;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _currentIndex = 0;
        _currentColor = [UIColor whiteColor];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self createSubmenu];
}
- (void)createSubmenu {
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    NSArray *colors = @[[UIColor whiteColor], [UIColor blackColor], [UIColor redColor], [UIColor yellowColor], [UIColor greenColor], [UIColor blueColor], [UIColor purpleColor], [UIColor clearColor]];
    int count = (int)colors.count;
    CGSize itemSize = CGSizeMake(20, 20);
    CGFloat space = (self.frame.size.width - count * itemSize.width)/(count + 1);
    for (int i = 0; i < count; i++) {
        UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(space + (itemSize.width + space)*i, (self.frame.size.height - itemSize.height)/2.0, itemSize.width, itemSize.height)];
        colorBtn.backgroundColor = colors[i];
        colorBtn.tag = 10 + i;
        [self addSubview:colorBtn];
        if (i == count - 1) {
            [colorBtn addTarget:self action:@selector(backToPreviousStep:) forControlEvents:UIControlEventTouchUpInside];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuGraffitiBack"] forState:UIControlStateNormal];
        }else {
            [colorBtn addTarget:self action:@selector(colorBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            colorBtn.layer.cornerRadius = itemSize.width/2.0;
            colorBtn.layer.borderColor = [UIColor whiteColor].CGColor;
            colorBtn.layer.borderWidth = 3;
            if (i != _currentIndex) {
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
                colorBtn.layer.borderWidth = 3;
            }else {
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 1.0f);
                colorBtn.layer.borderWidth = 4;
                _currentColor = colors[i];
                self.selectedLineColor(colors[i]);
            }
        }
    }
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 0.5)];
    line.backgroundColor = [UIColor whiteColor];
    line.alpha = 0.5;
    [self addSubview:line];
}
// 选中当前画笔颜色
- (void)colorBtnClicked:(UIButton *)colorBtn {
    UIButton *previousBtn = (UIButton *)[self viewWithTag:(10 + _currentIndex)];
    previousBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
    previousBtn.layer.borderWidth = 3;
    colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    colorBtn.layer.borderWidth = 4;
    _currentIndex = (int)colorBtn.tag- 10;
    _currentColor = colorBtn.backgroundColor;
    self.selectedLineColor(colorBtn.backgroundColor);
}
//返回上一步
- (void)backToPreviousStep:(id)sender {
    self.goBack();
}
@end

//贴画CollectionViewCell
@interface SLSubmenuStickingCell : UICollectionViewCell
@property (nonatomic, strong) SLImageView *imageView;
@end
@implementation SLSubmenuStickingCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    _imageView = [[SLImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_imageView];
}
- (void)setImage:(NSString *)imageName {
    _imageView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    _imageView.image = [SLImage imageNamed:imageName];
}
@end
/// 贴画子菜单
@interface SLSubmenuStickingView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) void(^selectedImage)(SLImage *image); //选中的图片 贴画
@end
@implementation SLSubmenuStickingView
- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self createSubmenu];
}
- (void)createSubmenu {
    [self addSubview:self.collectionView];
}
#pragma mark - Getter
- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[SLSubmenuStickingCell class] forCellWithReuseIdentifier:@"ItemId"];
    }
    return _collectionView;
}
- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
        for (int i = 0; i < 20; i++) {
            [_dataSource addObject:[NSString stringWithFormat:@"Images.bundle/%d",i]];
        }
    }
    return _dataSource;
}
#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SLSubmenuStickingCell * item = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemId" forIndexPath:indexPath];
    [item setImage:self.dataSource[indexPath.row]];
    return item;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    self.selectedImage([SLImage imageNamed:self.dataSource[indexPath.row]]);
}
#pragma mark -  UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((self.frame.size.width - 5*10)/4.0, self.frame.size.height);
}
//列间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10;
}
//行间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 10, 0, 10);
}
@end

/// 编辑主菜单
@interface SLEditMenuView ()
@property (nonatomic, strong) NSArray *menuTypes; //编辑类型集合
@property (nonatomic, strong) NSArray *imageNames; //编辑图标名称
@property (nonatomic, strong) NSArray *imageNamesSelected; //选中的 编辑图标名称
@property (nonatomic, strong) NSMutableArray *menuBtns; //编辑菜单按钮集合

@property (nonatomic, strong) SLSubmenuGraffitiView *submenuGraffiti; //涂鸦子菜单
@property (nonatomic, strong) SLSubmenuStickingView *submenuSticking; //贴图子菜单
@end
@implementation SLEditMenuView
#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createMenus];
    }
    return self;
}
#pragma mark - UI
- (void)createMenus {
    for (UIView *subView in self.subviews) {
        if (subView == _submenuGraffiti || subView == _submenuSticking) {
            continue;
        }
        [subView removeFromSuperview];
    }
    _menuTypes = @[@(SLEditMenuTypeGraffiti), @(SLEditMenuTypeSticking), @(SLEditMenuTypeText), @(SLEditMenuTypeCutting)];
    _imageNames = @[@"EditMenuGraffiti", @"EditMenuSticker", @"EditMenuText", @"EditMenuCut"];
    _imageNamesSelected = @[@"EditMenuGraffitiSelected", @"EditMenuStickerSelected", @"EditMenuTextSelected", @"EditMenuCutSelected"];
    int count = (int)_menuTypes.count;
    CGSize itemSize = CGSizeMake(20, 20);
    CGFloat space = (self.frame.size.width - count * itemSize.width)/count;
    _menuBtns = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        UIButton * menuBtn = [[UIButton alloc] initWithFrame:CGRectMake(space/2.0 + (itemSize.width + space)*i, self.frame.size.height - 80, itemSize.width, 80)];
        menuBtn.tag = i;
        [menuBtn setImage:[UIImage imageNamed:_imageNames[i]] forState:UIControlStateNormal];
        [menuBtn setImage:[UIImage imageNamed:_imageNamesSelected[i]] forState:UIControlStateSelected];
        [menuBtn addTarget:self action:@selector(menuBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:menuBtn];
        [_menuBtns addObject:menuBtn];
    }
}
#pragma mark - Getter
- (SLSubmenuGraffitiView *)submenuGraffiti {
    if (!_submenuGraffiti) {
        _submenuGraffiti = [[SLSubmenuGraffitiView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
        _submenuGraffiti.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _submenuGraffiti.selectedLineColor = ^(UIColor *lineColor) {
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"lineColor":lineColor});
        };
        _submenuGraffiti.goBack = ^{
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"goBack":@(YES)});
        };
        //        [self addSubview:_submenuGraffiti];
    }
    return _submenuGraffiti;
}
- (SLSubmenuStickingView *)submenuSticking {
    if (!_submenuSticking) {
        _submenuSticking = [[SLSubmenuStickingView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
        _submenuSticking.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _submenuSticking.selectedImage = ^(SLImage *image) {
            weakSelf.selectEditMenu(SLEditMenuTypeSticking, @{@"image":image});
        };
    }
    return _submenuSticking;
}
#pragma mark - Evenst Handle
- (void)menuBtnClicked:(UIButton *)menuBtn {
    for (UIButton *subView in self.menuBtns) {
        if (subView == menuBtn) {
            subView.selected = !subView.selected;
        } else {
            subView.selected = NO;
        }
    }
    SLEditMenuType editMenuType = [_menuTypes[menuBtn.tag] intValue];
    switch (editMenuType) {
        case SLEditMenuTypeGraffiti:
            [self hiddenView:self.submenuGraffiti hidden:!self.submenuGraffiti.hidden];
            self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuGraffiti.hidden), @"lineColor": self.submenuGraffiti.currentColor});
            [self hiddenView:self.submenuSticking hidden:YES];
            break;
        case SLEditMenuTypeSticking:
            [self hiddenView:self.submenuSticking hidden:!self.submenuSticking.hidden];
            self.selectEditMenu(editMenuType, nil);
            [self hiddenView:self.submenuGraffiti hidden:YES];
            break;
        case SLEditMenuTypeText:
            [self hiddenView:self.submenuSticking hidden:YES];
            self.selectEditMenu(editMenuType, nil);
            [self hiddenView:self.submenuGraffiti hidden:YES];
            break;
        case SLEditMenuTypeCutting:
            [self hiddenView:self.submenuSticking hidden:YES];
            self.selectEditMenu(editMenuType, nil);
            [self hiddenView:self.submenuGraffiti hidden:YES];
            break;
        default:
            break;
    }
}
- (void)hiddenView:(UIView *)view hidden:(BOOL)hidden{
    if (hidden) {
        view.hidden = YES;
        [view removeFromSuperview];
        //        view = nil;
    }else {
        view.hidden = NO;
        [self addSubview:view];
    }
}

@end


