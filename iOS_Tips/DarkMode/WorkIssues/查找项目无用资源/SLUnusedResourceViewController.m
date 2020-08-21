//
//  SLUnusedResourceViewController.m
//  DarkMode
//
//  Created by wsl on 2020/8/20.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLUnusedResourceViewController.h"
#import "SLResourceInfo.h"

/* 资料：
 https://www.jianshu.com/p/cef2f6becbe6
 https://github.com/tinymind/LSUnusedResources
 正则表达式入门：https://www.runoob.com/regexp/regexp-tutorial.html
 正则表达式在线工具： https://tool.oschina.net/regex/
 */
@interface SLUnusedResourceViewController ()

@end

@implementation SLUnusedResourceViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self searchAllUnderFilePath:@"/Users/wsl/GitHub/iOS_Tips/iOS_Tips/DarkMode" fileTypes:@"jpeg|jpg|png|gif|imageset"];
    
}

#pragma mark - UI

#pragma mark - Data

#pragma mark - Getter

#pragma mark - HelpMethods

/// 在FilePath路径下搜索所有suffixs类型的文件
/// @param searchPath 搜索路径
/// @param suffixs  文件后缀/格式 多种格式用|隔开即可 例如@"jpeg|jpg|png|gif|imageset"
- (void)searchAllUnderFilePath:(NSString *)searchPath fileTypes:(NSString *)suffixs{
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:searchPath error:nil] ;
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    filesArray = nil;
    NSMutableArray *resourceInfos = [NSMutableArray array];
    //相对于searchPath的子路径
    NSString *subPath;
    while (subPath = [filesEnumerator nextObject]) {
        @autoreleasepool {
            //匹配对象
            NSString *fileName = subPath.lastPathComponent;
            //            fileName = subPath;
            //匹配规则
            NSString *regularExpStr = [@"[a-zA-Z0-9_-]*\\." stringByAppendingFormat:@"%@", suffixs];
            //            NSString *regularExpStr = @"([a-zA-Z0-9_-]*)\\.m";
            NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:regularExpStr options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray <NSTextCheckingResult *> *resultArr = [regularExp matchesInString:fileName options:NSMatchingReportProgress range:NSMakeRange(0, fileName.length)];
            if(resultArr.count == 0) continue;
            //取出匹配出来的字符串
            NSString *subStr = [fileName substringWithRange:resultArr.firstObject.range];
            NSLog(@"%@",fileName);
            
            //全路径
            NSString *fullPath = [searchPath stringByAppendingPathComponent:subPath];
            //文件属性信息
            NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
            
            SLResourceInfo *info = [[SLResourceInfo alloc] init];
            info.filePath = fullPath;
            info.fileSize = [fileDic fileSize];
            info.isFolder = [[fileDic fileType] isEqualToString:@"NSFileTypeDirectory"] ? YES : NO;
            info.fileName = fileName;
            [resourceInfos addObject:info];
        }
    }
    
}


#pragma mark - EventsHandle


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
