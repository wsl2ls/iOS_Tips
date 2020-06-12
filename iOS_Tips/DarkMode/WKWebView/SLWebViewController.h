//
//  SLWebViewController.h
//  DarkMode
//
//  Created by wsl on 2020/5/21.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///关于WKWebView的那些坑：  https://mp.weixin.qq.com/s/rhYKLIbXOsUJC_n6dt9UfA?
/// https://github.com/ChenYilong/ParseSourceCodeStudy/blob/master/02_Parse%E7%9A%84%E7%BD%91%E7%BB%9C%E7%BC%93%E5%AD%98%E4%B8%8E%E7%A6%BB%E7%BA%BF%E5%AD%98%E5%82%A8/iOS%E7%BD%91%E7%BB%9C%E7%BC%93%E5%AD%98%E6%89%AB%E7%9B%B2%E7%AF%87.md
/// https://dequan1331.github.io/index.html
///关于WKWebView的使用可以看我之前的总结：  https://github.com/wsl2ls/WKWebView
@interface SLWebViewController : SLViewController

///打开的web地址    默认:https://www.jianshu.com/p/5cf0d241ae12
@property (nonatomic, strong) NSString *urlString;

@end

NS_ASSUME_NONNULL_END
