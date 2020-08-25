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
 正则表达式入门：http://www.regexlab.com/zh/regref.htm
 正则表达式在线工具： https://tool.oschina.net/regex/
 */
@interface SLUnusedResourceViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation SLUnusedResourceViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
    [self getUnusedResourceData];
}

#pragma mark - UI
- (void)setupUI {
    self.navigationController.navigationBar.translucent = YES;
    self.tableView.estimatedRowHeight = 1;
    self.navigationItem.title = @"正在扫描无用图片...";
}

#pragma mark - Data
///获取没有用的图片信息
- (void)getUnusedResourceData {
    
    //文件目录路径
    NSString *folderPath = @"/Users/wsl/GitHub/iOS_Tips/iOS_Tips/DarkMode";
    
    NSString *imgTypes = @"jpeg|jpg|png|gif|imageset";
    NSString *imgExpression = [NSString stringWithFormat:@"([a-zA-Z0-9_-]*)(@[23]x)?\\.(%@)",imgTypes];
    NSMutableArray *imgResources = [self searchAllUnderFolderPath:folderPath fileTypes:imgTypes regularExpression:imgExpression];
    
    NSString *fileTypes = @"h|m$|swift|xib|storyboard|plist";
    NSString *fileExpression = [NSString stringWithFormat:@"([a-zA-Z0-9_-]*)(\\.)(%@)",fileTypes];
    NSMutableArray *files = [self searchAllUnderFolderPath:folderPath fileTypes:fileTypes regularExpression:fileExpression];
    
    NSMutableArray *unusedImgs = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (SLResourceInfo *imgInfo in imgResources) {
            //其他文件中是否使用了该图片
            BOOL isUsed = NO;
            for (SLResourceInfo *fileInfo in files) {
                //文件内容
                NSString *content = [NSString stringWithContentsOfFile:fileInfo.filePath encoding:NSUTF8StringEncoding error:nil];
                if (content == nil) continue;
                
                /*
                 文件类型、语法、用法等不同，匹配规则就不同，依项目情况而定
                 @"@\"%@\""    例 @"wsl"
                 @"@\"(%@)(\.(jpeg|jpg|png|gif))?\""  例 @"wsl.png"
                 @"imageNamed:@\"(.+)\"";
                 @"(imageNamed|contentOfFile):@\"(.*)\""
                 
                 @"image name=\"(.+?)\""  xib格式(.xib .storyboard)
                 (stickers_%d)
                 */
                //去掉.png等后缀
                NSString *imgName = [imgInfo.fileName stringByReplacingOccurrencesOfString:imgInfo.fileType withString:@""];
                NSRange range = [imgName rangeOfString:@"@"];
                if (range.length) {
                    //去掉 @2x @3x
                    imgName = [imgName stringByReplacingOccurrencesOfString:[imgName substringFromIndex:range.location] withString:@""];
                }
                //匹配规则
                //                NSString *regularExpStr = [NSString stringWithFormat:@"@\"(%@)\"",imgName];
                NSString *regularExpStr = [NSString stringWithFormat:@"@\"(%@)\"",imgName];
                NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:regularExpStr options:NSRegularExpressionCaseInsensitive error:nil];
                NSArray <NSTextCheckingResult *> *resultArr = [regularExp matchesInString:content options:NSMatchingReportProgress range:NSMakeRange(0, content.length)];
                if(resultArr.count > 0){
                    // 取出匹配出来的字符串
                    NSString *subStr = [content substringWithRange:resultArr.firstObject.range];
                    //                    NSLog(@"%@",subStr);
                    isUsed = YES;
                    break;
                }
            }
            //没有使用过，加入无用待处理数组
            if (!isUsed) [unusedImgs addObject:imgInfo];
        }
        
        for (SLResourceInfo *unusedImg in unusedImgs) {
            //            NSLog(@"⚠️ 没用 %@", unusedImg.fileName);
        }
        
        self.dataSource = unusedImgs;
        SL_DISPATCH_ON_MAIN_THREAD(^{
            self.navigationItem.title = @"ipa瘦身之扫描无用资源";
            [self.tableView reloadData];
        });
        
    });
    
}

#pragma mark - Getter
- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;;
}

#pragma mark - HelpMethods

/// 在searchPath路径下搜索所有suffixs类型的文件
/// @param searchPath 搜索路径
/// @param suffixs  文件后缀/格式 多种格式用|隔开即可 例如@"jpeg|jpg|png|gif|imageset"
/// @param expression  正则表达式/匹配规则
- (NSMutableArray *)searchAllUnderFolderPath:(NSString *)searchPath fileTypes:(NSString *)suffixs regularExpression:(NSString *)expression {
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
            
            //匹配规则
            NSString *regularExpStr = expression;
            NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:regularExpStr options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray <NSTextCheckingResult *> *resultArr = [regularExp matchesInString:fileName options:NSMatchingReportProgress range:NSMakeRange(0, fileName.length)];
            if(resultArr.count == 0) continue;
            //取出匹配出来的字符串
            //            NSString *subStr = [fileName substringWithRange:resultArr.firstObject.range];
            //            NSLog(@"%@",subStr);
            
            //全路径
            NSString *fullPath = [searchPath stringByAppendingPathComponent:subPath];
            //文件属性信息
            NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
            
            SLResourceInfo *info = [[SLResourceInfo alloc] init];
            info.filePath = fullPath;
            info.fileSize = [fileDic fileSize];
            info.isFolder = [[fileDic fileType] isEqualToString:@"NSFileTypeDirectory"] ? YES : NO;
            info.fileName = fileName;
            info.fileType = [fileName substringFromIndex:[fileName rangeOfString:@"."].location];
            [resourceInfos addObject:info];
        }
    }
    return resourceInfos;
}


#pragma mark - EventsHandle


#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cellID"];
    }
    SLResourceInfo *info = self.dataSource[indexPath.row];
    cell.imageView.image = [UIImage imageWithContentsOfFile:info.filePath];
    cell.textLabel.text = info.fileName;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

@end
