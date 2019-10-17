//
//  SLEditTextView.h
//  DarkMode
//
//  Created by wsl on 2019/10/17.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///  文本水印编辑 工具
@interface SLEditTextView : UIView
/// 编辑文本完成
@property (nonatomic, copy) void(^editTextCompleted)(UITextView *textView);
@end

NS_ASSUME_NONNULL_END
