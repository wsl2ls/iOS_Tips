//
//  SLCubeViewController.m
//  DarkMode
//
//  Created by wsl on 2019/11/29.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLCubeViewController.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionCoord;   //顶点坐标
    GLKVector2 textureCoord;    //纹理坐标
    GLKVector3 normal;          //法线
} SLVertex;

// 顶点数
static NSInteger const kCoordCount = 36;

@interface SLCubeViewController ()  <GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) SLVertex *vertices;

@property (nonatomic, strong) CADisplayLink *displayLink;  //定时器更新 角度
@property (nonatomic, assign) NSInteger angle;  //旋转角度
@property (nonatomic, assign) GLuint vertexBuffer;  //顶点缓冲区 用完记得释放

@end

@implementation SLCubeViewController

#pragma mark - Override

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    
    //1. OpenGL ES 相关初始化
    [self commonInit];
    
    //2.顶点/纹理坐标数据
    [self vertexDataSetup];
    
    //3. 添加CADisplayLink
    [self addCADisplayLink];
    
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    //displayLink 失效
    [self.displayLink invalidate];
}
- (void)dealloc {
    NSLog(@"%@ 释放了", NSStringFromClass(self.class));
}

#pragma mark - 1.OpenGL ES 相关初始化
//OpenGL ES 相关初始化
- (void)commonInit {
    
    //1.创建context
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    //设置当前context
    [EAGLContext setCurrentContext:context];
    
    //2.创建GLKView并设置代理
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    self.glkView = [[GLKView alloc] initWithFrame:frame context:context];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;
    
    //3.使用深度缓存
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //默认是(0, 1)，这里用于翻转 z 轴，使正方形朝屏幕外
    glDepthRangef(1, 0);
    
    //4.将GLKView 添加self.view 上
    [self.view addSubview:self.glkView];
    
    //5.获取纹理图片
    NSString *myBundlePath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
    NSString *imagePath = [[NSBundle bundleWithPath:myBundlePath] pathForResource:@"素材1" ofType:@"png" inDirectory:@"Images"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    //6.设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    
    //7.使用baseEffect
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
}

#pragma mark - 2. 初始化顶点和纹理坐标
// 初始化顶点和纹理坐标
-(void)vertexDataSetup {
    /*
     解释一下:
     这里我们不复用顶点，使用每 3 个点画一个三角形的方式，需要 12 个三角形，则需要 36 个顶点
     以下的数据用来绘制以（0，0，0）为中心，边长为 1 的立方体
     */
    
    //8. 开辟顶点数据空间(数据结构SenceVertex 大小 * 顶点个数kCoordCount) 用完记得释放这个内存
    self.vertices = malloc(sizeof(SLVertex) * kCoordCount);
    
    // 前面
    self.vertices[0] = (SLVertex){{-0.5, 0.5, 0.5},  {0, 1}};
    self.vertices[1] = (SLVertex){{-0.5, -0.5, 0.5}, {0, 0}};
    self.vertices[2] = (SLVertex){{0.5, 0.5, 0.5},   {1, 1}};
    
    self.vertices[3] = (SLVertex){{-0.5, -0.5, 0.5}, {0, 0}};
    self.vertices[4] = (SLVertex){{0.5, 0.5, 0.5},   {1, 1}};
    self.vertices[5] = (SLVertex){{0.5, -0.5, 0.5},  {1, 0}};
    
    // 上面
    self.vertices[6] = (SLVertex){{0.5, 0.5, 0.5},    {1, 1}};
    self.vertices[7] = (SLVertex){{-0.5, 0.5, 0.5},   {0, 1}};
    self.vertices[8] = (SLVertex){{0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[9] = (SLVertex){{-0.5, 0.5, 0.5},   {0, 1}};
    self.vertices[10] = (SLVertex){{0.5, 0.5, -0.5},  {1, 0}};
    self.vertices[11] = (SLVertex){{-0.5, 0.5, -0.5}, {0, 0}};
    
    // 下面
    self.vertices[12] = (SLVertex){{0.5, -0.5, 0.5},    {1, 1}};
    self.vertices[13] = (SLVertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[14] = (SLVertex){{0.5, -0.5, -0.5},   {1, 0}};
    self.vertices[15] = (SLVertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[16] = (SLVertex){{0.5, -0.5, -0.5},   {1, 0}};
    self.vertices[17] = (SLVertex){{-0.5, -0.5, -0.5},  {0, 0}};
    
    // 左面
    self.vertices[18] = (SLVertex){{-0.5, 0.5, 0.5},    {1, 1}};
    self.vertices[19] = (SLVertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[20] = (SLVertex){{-0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[21] = (SLVertex){{-0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[22] = (SLVertex){{-0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[23] = (SLVertex){{-0.5, -0.5, -0.5},  {0, 0}};
    
    // 右面
    self.vertices[24] = (SLVertex){{0.5, 0.5, 0.5},    {1, 1}};
    self.vertices[25] = (SLVertex){{0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[26] = (SLVertex){{0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[27] = (SLVertex){{0.5, -0.5, 0.5},   {0, 1}};
    self.vertices[28] = (SLVertex){{0.5, 0.5, -0.5},   {1, 0}};
    self.vertices[29] = (SLVertex){{0.5, -0.5, -0.5},  {0, 0}};
    
    // 后面
    self.vertices[30] = (SLVertex){{-0.5, 0.5, -0.5},   {0, 1}};
    self.vertices[31] = (SLVertex){{-0.5, -0.5, -0.5},  {0, 0}};
    self.vertices[32] = (SLVertex){{0.5, 0.5, -0.5},    {1, 1}};
    self.vertices[33] = (SLVertex){{-0.5, -0.5, -0.5},  {0, 0}};
    self.vertices[34] = (SLVertex){{0.5, 0.5, -0.5},    {1, 1}};
    self.vertices[35] = (SLVertex){{0.5, -0.5, -0.5},   {1, 0}};
    
    //开辟缓存区 VBO
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SLVertex) * kCoordCount;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    //顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SLVertex), NULL + offsetof(SLVertex, positionCoord));
    
    //纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SLVertex), NULL + offsetof(SLVertex, textureCoord));
    
}

#pragma mark - 3.add CADisplayLink
-(void)addCADisplayLink {
    //CADisplayLink 类似定时器,提供一个周期性调用.属于QuartzCore.framework中.
    //具体可以参考该博客 https://www.cnblogs.com/panyangjun/p/4421904.html
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(rotation)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - GLKViewDelegate
//开始绘画
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //1.开启深度测试
    glEnable(GL_DEPTH_TEST);
    //2.清除颜色缓存区&深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //3.准备绘制
    [self.baseEffect prepareToDraw];
    //4.绘图
    glDrawArrays(GL_TRIANGLES, 0, kCoordCount);
}

#pragma mark - Events Handle
//更新正方体旋转角度
- (void)rotation {
    //1.计算旋转度数
    self.angle = (self.angle + 5) % 360;
    //2.修改baseEffect.transform.modelviewMatrix
    //    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.3, 1, -0.7);
    
    //  等价于 ==  self.baseEffect.transform.modelviewMatrix = GLKMatrix4Rotate(GLKMatrix4MakeRotation(GLKMathDegreesToRadians(315), 1, 0, -1), GLKMathDegreesToRadians(self.angle), 1, 1, 1);
    //模型视图矩阵
    self.baseEffect.transform.modelviewMatrix =  GLKMatrix4Rotate(GLKMatrix4MakeRotation(GLKMathDegreesToRadians(45), 1, 0, -1), GLKMathDegreesToRadians(self.angle), -1, 1, -1);
    //3.重新渲染
    [self.glkView display];
}

@end
