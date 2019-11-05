//
//  SLEditTextView.m
//  DarkMode
//
//  Created by wsl on 2019/10/17.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditTextView.h"
#import "SLPaddingLabel.h"

@interface SLEditTextView ()<UITextViewDelegate>
{
    CGFloat _keyboardHeight;
}
@property (nonatomic, strong) UIButton *cancleEditBtn; //取消编辑
@property (nonatomic, strong) UIButton *doneEditBtn; //完成编辑
@property (nonatomic, strong) UITextView *textView;  //文本输入
@property (nonatomic, strong) NSArray *colors;  //颜色集合

@property (nonatomic, assign) int currentIndex; // 当前颜色索引
@property (nonatomic, strong) UIColor *currentColor; // 当前颜色
@property (nonatomic, assign) BOOL colorSwitch;  // 颜色开关 0：默认设置文本颜色  1：背景颜色
@end

@implementation SLEditTextView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        _currentColor = [UIColor whiteColor];
        _currentIndex = 0;
        _colors = @[[UIColor whiteColor], [UIColor blackColor], [UIColor redColor], [UIColor yellowColor], [UIColor greenColor], [UIColor blueColor], [UIColor purpleColor]];
        [self setupUI];
    }
    return self;
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview != nil) {
        [self.textView becomeFirstResponder];
    }
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - UI
- (void)setupUI {
    [self addSubview:self.textView];
    __weak typeof(self) weakSelf = self;
    self.configureEditParameters = ^(NSDictionary * _Nonnull parameters) {
        weakSelf.textView.textColor = parameters[@"textColor"];
        weakSelf.textView.backgroundColor = parameters[@"backgroundColor"];
        weakSelf.textView.text = parameters[@"text"];
        weakSelf.currentColor = weakSelf.textView.textColor;
        for (UIColor *color in weakSelf.colors) {
            if (CGColorEqualToColor(color.CGColor, weakSelf.currentColor.CGColor)) {
                weakSelf.currentIndex = (int)[weakSelf.colors indexOfObject:color];
            }
        }
        [weakSelf textViewDidChange:weakSelf.textView];
    };
    [self addSubview:self.cancleEditBtn];
    [self addSubview:self.doneEditBtn];
    //监听键盘frame改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}
//颜色选择菜单视图
- (void)colorSelectionView:(CGFloat)keyboardHeight {
    for (UIView *subView in self.subviews) {
        if (subView != self.doneEditBtn || subView != self.cancleEditBtn || subView != self.textView) {
            continue;
        }else {
            [subView removeFromSuperview];
        }
    }
    int count = (int)_colors.count + 1;
    CGSize itemSize = CGSizeMake(20, 20);
    CGFloat space = (self.frame.size.width - count * itemSize.width)/(count + 1);
    for (int i = 0; i < count; i++) {
        UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(space + (itemSize.width + space)*i, self.sl_h - keyboardHeight - 20 - 20, itemSize.width, itemSize.height)];
        [self addSubview:colorBtn];
        if (i == 0) {
            [colorBtn addTarget:self action:@selector(colorSwitchBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuTextColor"] forState:UIControlStateNormal];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuTextBackgroundColor"] forState:UIControlStateSelected];
        }else {
            colorBtn.backgroundColor = _colors[(i - 1)];
            colorBtn.tag = 10 + (i - 1);
            [colorBtn addTarget:self action:@selector(textColorBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            colorBtn.layer.cornerRadius = itemSize.width/2.0;
            colorBtn.layer.borderColor = [UIColor whiteColor].CGColor;
            if(_currentIndex == (i - 1)) {
                colorBtn.layer.borderWidth = 4;
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 1.0f);
            }else {
                colorBtn.layer.borderWidth = 2;
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
            }
        }
    }
}

#pragma mark - Getter
- (UIButton *)cancleEditBtn {
    if (_cancleEditBtn == nil) {
        _cancleEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 30, 40, 30)];
        [_cancleEditBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancleEditBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancleEditBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cancleEditBtn addTarget:self action:@selector(cancleEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancleEditBtn;
}
- (UIButton *)doneEditBtn {
    if (_doneEditBtn == nil) {
        _doneEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.sl_w - 50 - 15, 30, 40, 30)];
        _doneEditBtn.backgroundColor = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1];
        [_doneEditBtn setTitle:@"完成" forState:UIControlStateNormal];
        [_doneEditBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _doneEditBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _doneEditBtn.layer.cornerRadius = 4;
        [_doneEditBtn addTarget:self action:@selector(doneEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneEditBtn;
}
- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(30, 100, 0, 50)];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:26];
        _textView.textColor = _currentColor;
        _textView.scrollEnabled = NO;
        _textView.delegate = self;
        _textView.clipsToBounds = NO;
        _textView.keyboardAppearance = UIKeyboardAppearanceDark;
        _textView.tintColor = [UIColor colorWithRed:45/255.0 green:175/255.0 blue:45/255.0 alpha:1];
    }
    return _textView;
}

#pragma mark - Help Methods
// 返回一个文本水印视图
- (UILabel *)copyTextView:(UITextView *)textView {
    SLPaddingLabel *label = [[SLPaddingLabel alloc] initWithFrame:textView.bounds];
    label.font = textView.font;
    label.userInteractionEnabled = YES;
    label.backgroundColor = textView.backgroundColor;
    label.textColor = textView.textColor;
    label.lineBreakMode = NSLineBreakByCharWrapping;
    label.textPadding = UIEdgeInsetsMake(textView.textContainerInset.top, 4, textView.textContainerInset.bottom, 4);
    label.text = textView.text;
    label.numberOfLines = 0;
    return label;
}

#pragma mark - EventsHandle
//取消编辑
- (void)cancleEditBtnClicked:(id)sender {
    [self.textView resignFirstResponder];
    if (self.editTextCompleted) {
        self.editTextCompleted(nil);
    }
    [self removeFromSuperview];
}
//完成编辑
- (void)doneEditBtnClicked:(id)sender {
    [self.textView resignFirstResponder];
    if (self.editTextCompleted) {
        self.editTextCompleted([self copyTextView:self.textView]);
    }
    [self removeFromSuperview];
}
//选中的当前颜色
- (void)textColorBtnClicked:(UIButton *)colorBtn {
    UIButton *previousBtn = (UIButton *)[self viewWithTag:(10 + _currentIndex)];
    previousBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
    previousBtn.layer.borderWidth = 2;
    colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    colorBtn.layer.borderWidth = 4;
    _currentIndex = (int)colorBtn.tag- 10;
    _currentColor = colorBtn.backgroundColor;
    if (_colorSwitch) {
        self.textView.backgroundColor = colorBtn.backgroundColor;
    }else {
        self.textView.textColor = colorBtn.backgroundColor;
    }
}
//选择当前是文本颜色菜单还是背景颜色菜单
- (void)colorSwitchBtnClicked:(UIButton *)colorSwitch {
    _colorSwitch = !_colorSwitch;
    colorSwitch.selected = _colorSwitch;
    if (_colorSwitch) {
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = _currentColor;
    }else {
        self.textView.backgroundColor = _currentColor;
        self.textView.textColor = [UIColor whiteColor];
    }
}
//键盘即将弹出
- (void)keyboardWillShow:(NSNotification *)notification {
    //获取键盘高度 keyboardHeight
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    _keyboardHeight = keyboardRect.size.height;
    [self colorSelectionView:_keyboardHeight];
}
#pragma mark - UITextViewDelegate
-(void)textViewDidChange:(UITextView *)textView{
    //最大高度
    CGFloat maxHeight = self.sl_h - 100 - _keyboardHeight - 20 - 20 - 20;
    CGSize constraintSize = CGSizeMake(self.sl_w - 2*30, MAXFLOAT);
    CGSize size = [textView sizeThatFits:constraintSize];
    if (size.height >= maxHeight) {
        textView.sl_y = 100 - (size.height - maxHeight);
    } else {
        textView.sl_y = 100;
    }
    textView.sl_h = size.height;
    textView.sl_w = size.width;
}
@end
