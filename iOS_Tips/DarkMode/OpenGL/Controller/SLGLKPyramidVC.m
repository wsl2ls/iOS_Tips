//
//  SLGLKPyramidVC.m
//  DarkMode
//
//  Created by wsl on 2019/12/5.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLGLKPyramidVC.h"
#import <GLKit/GLKit.h>

@interface SLGLKPyramidVC () <GLKViewDelegate>

@property(nonatomic,strong)EAGLContext *mContext;
@property(nonatomic,strong)GLKBaseEffect *mEffect;
@property (nonatomic, strong) GLKView *glkView;

@property(nonatomic,assign) int count;  //顶点个数

@property (nonatomic, strong) CADisplayLink *displayLink;  //定时器更新 角度

@end

@implementation SLGLKPyramidVC

#pragma mark - Override
-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    //1.新建图层
    [self setupContext];
    //2.渲染图形
    [self render];
    // 3.添加定时器
    [self addCADisplayLink];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [EAGLContext setCurrentContext:nil];
    //displayLink 失效
    [self.displayLink invalidate];
}
- (void)dealloc {
    NSLog(@"%@ 释放了", NSStringFromClass(self.class));
}

#pragma mark - 新建图层
//1.新建图层
-(void)setupContext {
    //1.新建OpenGL ES上下文
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width);
    _glkView= [[GLKView alloc] initWithFrame:frame context:self.mContext];
    _glkView.center = CGPointMake(self.view.frame.size.width/2.0, self.view.frame.size.height/2.0);
    _glkView.backgroundColor = [UIColor clearColor];
    _glkView.delegate = self;
    _glkView.context = self.mContext;
    _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self.view addSubview:_glkView];
    
    [EAGLContext setCurrentContext:self.mContext];
    //    开启正背面剔除和深度测试操作效果
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
}

#pragma mark - 2.渲染图形
//2.渲染图形
-(void)render {
    //1.顶点数据
    //前3个元素，是顶点数据；中间3个元素，是顶点颜色值，最后2个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
    
    //2.绘图索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //顶点个数
    self.count = sizeof(indices) /sizeof(GLuint);
    
    //将顶点数组放入数组缓冲区中 GL_ARRAY_BUFFER
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    //将索引数组存储到索引缓冲区 GL_ELEMENT_ARRAY_BUFFER
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    //使用顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, NULL);
    
    //使用颜色数据
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    
    //使用纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
    //获取纹理路径
    NSString *myBundlePath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
    NSString *imagePath = [[NSBundle bundleWithPath:myBundlePath] pathForResource:@"lufei" ofType:@"png" inDirectory:@"Images"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(YES),GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:imagePath options:options error:nil];
    
    //着色器
    self.mEffect = [[GLKBaseEffect alloc]init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    //投影视图
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.f);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    //模型视图
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
}
// 3.添加定时器
-(void)addCADisplayLink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(rotation)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - GLKViewDelegate
//开始绘画
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(1.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.mEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

#pragma mark - Events Handle
//旋转
- (void)rotation {
    float XDegree = -M_PI/6.0;
    static float ZDegree = 0.0 ;
    
    //模型视图矩阵 平移旋转
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, XDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, ZDegree += 0.1f);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    //重新渲染
    [self.glkView display];
}
@end
