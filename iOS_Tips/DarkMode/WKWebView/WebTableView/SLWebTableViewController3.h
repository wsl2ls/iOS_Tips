//
//  SLWebTableViewController3.h
//  DarkMode
//
//  Created by wsl on 2020/5/27.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
  WKWebView + UITableView
  方案3：(推荐) WKWebView作为TableView的Header, 但不撑开webView。禁用tableView和webView.scrollVie的scrollEnabled = NO，通过添加pan手势,手动调整contentOffset。WebView的最大高度为屏幕高度，当内容不足一屏时，高度为内容高度。和方案2类似，但是不需要插入占位Div。
*/
@interface SLWebTableViewController3 : SLViewController

@end

NS_ASSUME_NONNULL_END
