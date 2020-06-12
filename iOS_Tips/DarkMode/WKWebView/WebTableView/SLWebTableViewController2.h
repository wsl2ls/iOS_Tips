//
//  SLWebTableViewController2.h
//  DarkMode
//
//  Created by wsl on 2020/5/25.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLDynamicItem.h"

NS_ASSUME_NONNULL_BEGIN

/*
  WKWebView + UITableView
  方案2：将tableView加到WKWebView.scrollView上, WKWebView加载的HTML最后留一个空白占位div，用于确定tableView的位置，在监听到webView.scrollView.contentSize变化后，不断调整tableView的位置，同时将该div的尺寸设置为tableView的尺寸。禁用tableView和webView.scrollVie的scrollEnabled = NO，通过添加pan手势,手动调整contentOffset。tableView的最大高度为屏幕高度，当内容不足一屏时，高度为内容高度。
  参考： https://www.jianshu.com/p/42858f95ab43、https://dequan1331.github.io/hybrid-page-kit.html、https://www.jianshu.com/p/3721d736cf68
*/
@interface SLWebTableViewController2 : SLViewController

@end

NS_ASSUME_NONNULL_END
