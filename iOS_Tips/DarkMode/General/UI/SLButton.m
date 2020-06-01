//
//  EBButton.m
//  ZGEBook
//
//  Created by wsl on 2020/4/23.
//  Copyright © 2020 ZGEBook. All rights reserved.
//

#import "SLButton.h"

@interface SLButton ()

@end

@implementation SLButton

#pragma mark - Override
- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}
- (void)didMoveToSuperview {
    if (self.superview) {
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
    }
}
- (void)didMoveToWindow {
    if (self.superview) {
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
    }
}

#pragma mark - Getter
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        //        _imageView.backgroundColor = [UIColor greenColor];
    }
    return _imageView;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        //        _titleLabel.backgroundColor = [UIColor greenColor];
    }
    return _titleLabel;
}

#pragma mark - Public Methods
/// 设置文本和图片的位置
- (void)setTitleImageLayoutStyle:(SLButtonStyle)titleImageStyle space:(CGFloat)space {
    switch (titleImageStyle) {
        case SLButtonStyleImageLeft:
            [self imageLeft:space];
            break;
        case SLButtonStyleImageRight:
            [self imageRight:space];
            break;
        case SLButtonStyleImageTop:
            [self imageTop:space];
            break;
        case SLButtonStyleImageBottom:
            [self imageBottom:space];
            break;
        default:
            break;
    }
}

- (void)imageLeft:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeZero];
    [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY);
        make.size.mas_equalTo(imageSize);
        make.centerX.mas_equalTo(self.mas_centerX).offset(-imageSize.width/2.0-space/2.0);
    }];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY);
        make.size.mas_equalTo(titleSize);
        make.centerX.mas_equalTo(self.mas_centerX).offset(titleSize.width/2.0+space/2.0);
    }];
}
- (void)imageRight:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeZero];
    [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY);
        make.size.mas_equalTo(imageSize);
        make.centerX.mas_equalTo(self.mas_centerX).offset(imageSize.width/2.0+space/2.0);
    }];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY);
        make.size.mas_equalTo(titleSize);
        make.centerX.mas_equalTo(self.mas_centerX).offset(-titleSize.width/2.0-space/2.0);
    }];
}
- (void)imageTop:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeZero];
    CGFloat heightGap = imageSize.height - titleSize.height; //高度差距
    [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.size.mas_equalTo(imageSize);
        make.centerY.mas_equalTo(self.mas_centerY).offset(-imageSize.height/2.0-space/2.0 + heightGap/2.0);
    }];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.size.mas_equalTo(titleSize);
        make.centerY.mas_equalTo(self.mas_centerY).offset(titleSize.height/2.0+space/2.0 + heightGap/2.0);
    }];
}
- (void)imageBottom:(CGFloat)space {
    CGSize imageSize = self.imageView.image.size;
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeZero];
    [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.size.mas_equalTo(imageSize);
        make.centerY.mas_equalTo(self.mas_centerY).offset(imageSize.height/2.0+space/2.0);
    }];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.size.mas_equalTo(titleSize);
        make.centerY.mas_equalTo(self.mas_centerY).offset(-titleSize.height/2.0-space/2.0);
    }];
}

@end
