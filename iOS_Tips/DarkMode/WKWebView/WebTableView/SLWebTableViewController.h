//
//  SLWebTableViewController.h
//  DarkMode
//
//  Created by wsl on 2020/5/22.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
   WKWebView + UITableView
   方案1：WebView作为TableView的Header, 撑开webView，显示渲染全部内容，当内容过多时，比如大量图片时，容易造成内存暴涨（不建议使用）
   参考： https://www.jianshu.com/p/42858f95ab43、https://dequan1331.github.io/hybrid-page-kit.html、https://www.jianshu.com/p/3721d736cf68
 */
@interface SLWebTableViewController : SLViewController

@end

NS_ASSUME_NONNULL_END
