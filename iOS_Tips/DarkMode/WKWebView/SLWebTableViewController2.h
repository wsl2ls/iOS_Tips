//
//  SLWebTableViewController2.h
//  DarkMode
//
//  Created by wsl on 2020/5/25.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
  WKWebView + UITableView
  方案二：将WKWebView作为主体，其加载的HTML最后留一个空白占位div，用于确定tableView的位置。tableView加到webView.scrollView上，在监听到webView.scrollView的内容尺寸变化后，不断调整tableView的位置对应于该空白div的位置，同时将该div的尺寸设置为tableView的尺寸
  参考： https://www.jianshu.com/p/42858f95ab43、https://dequan1331.github.io/hybrid-page-kit.html、https://www.jianshu.com/p/3721d736cf68
*/
@interface SLWebTableViewController2 : UIViewController

@end

NS_ASSUME_NONNULL_END
