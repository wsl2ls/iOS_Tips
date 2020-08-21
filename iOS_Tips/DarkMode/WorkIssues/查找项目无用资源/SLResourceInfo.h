//
//  SLResourceInfo.h
//  DarkMode
//
//  Created by wsl on 2020/8/21.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLResourceInfo : NSObject

///文件路径
@property (nonatomic, copy) NSString *fileName;
///文件路径
@property (nonatomic, copy) NSString *filePath;
///文件大小
@property (nonatomic, assign) CGFloat fileSize;
/// 是否为文件夹
@property (nonatomic, assign) BOOL isFolder;
/// 文件类型
@property (nonatomic, copy) NSString *fileType;

@end

NS_ASSUME_NONNULL_END
