//
//  SLSplitScreenCell.h
//  DarkMode
//
//  Created by wsl on 2019/12/9.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    GLKVector3 positionCoord; //  顶点坐标
    GLKVector2 textureCoord; //  纹理坐标
} SLSenceVertex;

/// 分屏个数选择
@interface SLSplitScreenCell : UICollectionViewCell

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) BOOL isSelect;

@end

NS_ASSUME_NONNULL_END
