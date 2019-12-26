//
//  SLPaddingLabel.h
//  DarkMode
//
//  Created by wsl on 2019/10/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 可以设置内边距的Label
@interface SLPaddingLabel : UILabel
/// 内边距
@property (nonatomic, assign) UIEdgeInsets textPadding;
@end

NS_ASSUME_NONNULL_END
