//
//  SLSplitScreenCell.h
//  DarkMode
//
//  Created by wsl on 2019/12/9.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 分屏个数选择
@interface SLSplitScreenCell : UICollectionViewCell

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) BOOL isSelect;

@end

NS_ASSUME_NONNULL_END
