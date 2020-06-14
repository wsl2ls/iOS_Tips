//
//  SLWebTableViewController4.h
//  DarkMode
//
//  Created by wsl on 2020/5/28.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
  WKWebView + UITableView
  方案4：(推荐)[UIScrollView addSubView: WKWebView & UITableView];  UIScrollView.contenSize = WKWebView.contenSize + UITableView.contenSize; WKWebView和UITableView的最大高度为一屏高，并禁用scrollEnabled=NO，然后根据UIScrollView的滑动偏移量调整WKWebView和UITableView的展示区域contenOffset
*/
@interface SLWebTableViewController4 : SLViewController

@end

NS_ASSUME_NONNULL_END
