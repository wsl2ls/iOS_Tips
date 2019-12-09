//
//  SLMixColorTextureVC.m
//  DarkMode
//
//  Created by wsl on 2019/12/5.
//  Copyright © 2019 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "SLMixColorTextureVC.h"
#import "GLESMath.h"
#import "GLESUtils.h"

#import <OpenGLES/ES2/gl.h>

/// 三角体
@interface SLMixView : UIView

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property(nonatomic, strong)CAEAGLLayer *myEagLayer;
@property(nonatomic, strong)EAGLContext *myContext;

@property(nonatomic, assign) GLuint myColorRenderBuffer;  //渲染缓存区
@property(nonatomic, assign) GLuint myColorFrameBuffer;  // 帧缓冲区
@property (nonatomic, assign) GLuint vertexBuffer;  //顶点缓冲区 用完记得释放
@property(nonatomic, assign) GLuint myPrograme;  //着色器程序

@property (nonatomic, assign) NSInteger angle; //旋转弧度

@end

@implementation SLMixView

#pragma mark - Override
-(void)layoutSubviews {
    //1.设置图层
    [self setupLayer];
    
    //2.设置图形上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deleteRenderAndFrameBuffer];
    
    //4.设置RenderBuffer
    [self setupRenderBuffer];
    
    //5.设置FrameBuffer
    [self setupFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
    
}
//重写layerClass，将SLMixView返回的图层从CALayer替换成CAEAGLLayer
+(Class)layerClass {
    return [CAEAGLLayer class];
}
//清理内存
- (void)dealloc {
    if ([EAGLContext currentContext] == self.myContext) {
        [EAGLContext setCurrentContext:nil];
    }
    //清空缓存区
    [self deleteRenderAndFrameBuffer];
    //清除顶点缓冲区
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    if (_myPrograme) {
        glDeleteProgram(_myPrograme);
        _myPrograme = 0;
    }
}

#pragma mark - 1.设置图层
-(void)setupLayer {
    //1.创建特殊图层
    /*
     重写layerClass，将SLMixView返回的图层从CALayer替换成CAEAGLLayer
     */
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    
    //2.设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];
    
    //3.设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
     kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
     kEAGLDrawablePropertyColorFormat
     可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     
     kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
     kEAGLColorFormatRGB565：16位RGB的颜色，
     kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     
     */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
}

#pragma mark - 2.设置上下文
-(void)setupContext {
    //1.指定OpenGL ES 渲染API版本，我们使用2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    //2.创建图形上下文
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    //3.判断是否创建成功
    if (!context) {
        NSLog(@"Create context failed!");
        return;
    }
    //4.设置图形上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setCurrentContext failed!");
        return;
    }
    //5.将局部context，变成全局的
    self.myContext = context;
}

#pragma mark - 3.清空缓存区
-(void)deleteRenderAndFrameBuffer {
    /*
     buffer分为frame buffer 和 render buffer2个大类。
     其中frame buffer 相当于render buffer的管理者。
     frame buffer object即称FBO。
     render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
     */
    
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

#pragma mark - 4.设置RenderBuffer
//设置渲染缓冲区
-(void)setupRenderBuffer {
    //1.定义一个缓存区ID
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    //3.
    self.myColorRenderBuffer = buffer;
    //4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    //5.将可绘制对象drawable object's  CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

#pragma mark - 5.设置FrameBuffer
//帧缓存区
-(void)setupFrameBuffer {
    //1.定义一个缓存区ID
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    //3.
    self.myColorFrameBuffer = buffer;
    //4.
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    /*生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
     调用glFramebufferRenderbuffer函数进行绑定到对应的附着点上，后面的绘制才能起作用
     */
    //5.将渲染缓存区myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

#pragma mark - 6.开始绘制
// 顶点着色器
- (NSString *)vertexShaderString {
    return Shader_String (
                          attribute vec4 position;  //顶点坐标  由客户端传入
                          attribute vec4 positionColor;  //顶点颜色 由客户端传入
                          attribute vec2 textCoor;   //纹理坐标 由客户端传入
                          
                          uniform mat4 projectionMatrix;  //投影矩阵 把三维空间视图透视投影到二维平面上
                          uniform mat4 modelViewMatrix;   //模型视图矩阵  旋转、平移、缩放
                          
                          varying lowp vec2 vTextCoor;  // 纹理坐标  传递给片元着色器
                          varying lowp vec4 varyColor;  //颜色 传递给片元着色器
                          
                          void main() {
        varyColor = positionColor;
        vTextCoor = textCoor;
        
        vec4 vPos;
        vPos = projectionMatrix * modelViewMatrix * position;   // 投影矩阵 * 模型视图矩阵 * 世界坐标系  等等后面一系列矩阵坐标转换，映射到屏幕坐标
        gl_Position = vPos;
    });
}
// 片元着色器
- (NSString *)fragmentShaderString {
    return Shader_String (
                          precision highp float;   //float数据类型 默认精度为highp
                          varying lowp vec2 vTextCoor; //纹理坐标 由顶点着色器传入
                          varying lowp vec4 varyColor;  //顶点颜色 由顶点着色器传入
                          uniform sampler2D colorMap;  //纹理采样器
                          
                          void main() {
        vec4 weakMask = texture2D(colorMap, vTextCoor);  //纹素 本质上也是颜色
        vec4 mask = varyColor;  //颜色
        float alpha = 0.3;
        
        vec4 mixColor = mask * (1.0 - alpha) + weakMask * alpha;   // 混合后的颜色
        gl_FragColor = mixColor;
    });
}

// 渲染图层
-(void)renderLayer {
    @autoreleasepool {
        //清空缓存区
        [self deleteRenderAndFrameBuffer];
        //清除顶点缓冲区
        if (_vertexBuffer) {
            glDeleteBuffers(1, &_vertexBuffer);
            _vertexBuffer = 0;
        }
        if (_myPrograme) {
            //如果之前存在就删除
            glDeleteProgram(_myPrograme);
            _myPrograme = 0;
        }
        
        //设置清屏颜色
        glClearColor(0.3f, 0.45f, 0.5f, 1.0f);
        //清除颜色缓冲区和深度缓冲区
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        //1.设置视口大小
        CGFloat scale = [[UIScreen mainScreen]scale];
        glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
        
        //2.读取顶点着色程序、片元着色程序
        //3.读取/加载/编译shader
        self.myPrograme = [self loadShaders:[self vertexShaderString] Withfrag:[self fragmentShaderString]];
        //4.链接
        glLinkProgram(self.myPrograme);
        GLint linkStatus;
        //获取链接状态
        glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
        if (linkStatus == GL_FALSE) {
            GLchar message[512];
            glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
            NSString *messageString = [NSString stringWithUTF8String:message];
            NSLog(@"着色器程序 Program Link Error:%@",messageString);
            return;
        }
        NSLog(@"着色器程序 Program Link Success!");
        //5.使用program
        glUseProgram(self.myPrograme);
        
        //6.创建顶点数组 & 索引数组
        //(1)顶点数组 前3顶点值（x,y,z），中3位颜色值(RGB)  后两位纹理坐标xy
        //注意：默认三角锥底面是垂直于屏幕朝外的，即是三角锥往屏幕里倒了90°
        GLfloat attrArr[] =
        {
            -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 1.0f,    0.0f, 1.0f,  //左上0  蓝
            0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,    1.0f, 1.0f,  //右上1
            -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,    0.0f, 0.0f,  //左下2  白
            0.5f, -0.5f, 0.0f,      1.0f, 0.0f, 0.0f,    1.0f, 0.0f,  //右下3  红
            
            0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,    0.5f, 0.5f,   //顶点4  绿
        };
        //(2).索引数组
        GLuint indices[] =
        {
            0, 3, 2,
            0, 1, 3,
            0, 2, 4,
            0, 4, 1,
            2, 3, 4,
            1, 4, 3,
        };
        
        //7.-----处理顶点数据--------
        //(1)顶点缓存区
        //(2)申请一个缓存区标识符 https://blog.csdn.net/qq_36383623/article/details/85123077
        if (self.vertexBuffer == 0) {
            // 判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
            glGenBuffers(1, &_vertexBuffer);
        }
        //(3)将_vertexBuffer绑定到GL_ARRAY_BUFFER标识符上
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        //(4)把顶点数据从CPU内存复制到GPU上
        glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
        
        //8.将顶点数据通过myPrograme中的传递到顶点着色程序的position
        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
        //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
        //3.最后数据是通过glVertexAttribPointer传递过去的。
        
        //(1)注意：第二参数字符串必须和vertexShaderString中的输入变量：position保持一致
        GLuint position = glGetAttribLocation(self.myPrograme, "position");
        //(2).打开position 属性通道
        glEnableVertexAttribArray(position);
        //(3).设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, NULL);
        
        //9.--------处理顶点颜色值-------
        GLuint positionColor = glGetAttribLocation(self.myPrograme, "positionColor");
        glEnableVertexAttribArray(positionColor);
        glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (float *)NULL + 3);
        
        // ------- 处理纹理坐标------
        //纹理坐标
        GLuint textCoor = glGetAttribLocation(self.myPrograme, "textCoor");
        glEnableVertexAttribArray(textCoor);
        glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (float *)NULL + 6);
        //加载纹理
        [self setupTexture];
        //设置纹理采样器 sampler2D, 将采样器绑定到对应的纹理单元 0
        glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
        
        
        //10.找到myProgram中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象。
        GLuint projectionMatrixSlot = glGetUniformLocation(self.myPrograme, "projectionMatrix");
        GLuint modelViewMatrixSlot = glGetUniformLocation(self.myPrograme, "modelViewMatrix");
        
        float width = self.frame.size.width;
        float height = self.frame.size.height;
        
        //11.创建4 * 4投影矩阵  把三维空间视图透视投影到二维平面上, 远大近小 https://www.jianshu.com/p/3448f546eac4
        KSMatrix4 _projectionMatrix;
        //(1)获取单元矩阵
        ksMatrixLoadIdentity(&_projectionMatrix);
        //(2)计算纵横比例 = 长/宽
        float aspect = width / height; //长宽比
        //(3)获取透视投影矩阵
        /*
         参数1：矩阵
         参数2：视角，度数为单位
         参数3：纵横比
         参数4：近平面距离
         参数5：远平面距离
         参考PPT
         */
        ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f); //透视变换，视角30°
        //(4)将投影矩阵传递到顶点着色器
        /*
         void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
         参数列表：
         location:指要更改的uniform变量的位置
         count:更改矩阵的个数
         transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
         value:执行count个元素的指针，用来更新指定uniform变量
         */
        glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
        
        
        //12.创建一个4 * 4 矩阵，模型视图矩阵  用于旋转、平移、缩放
        KSMatrix4 _modelViewMatrix;
        //(1)获取单元矩阵
        ksMatrixLoadIdentity(&_modelViewMatrix);
        //(2)平移，z轴平移-10 在投影矩阵的近平面距离和远平面距离之间平移，超出范围看不到了
        ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
        //(3)创建一个4 * 4 矩阵，旋转矩阵
        KSMatrix4 _rotationMatrix;
        //(4)初始化为单元矩阵
        ksMatrixLoadIdentity(&_rotationMatrix);
        //(5)旋转
        self.angle = (self.angle + 5) % 360;
        ksRotate(&_rotationMatrix, 110 , 1.0, 0.0, 0.0); //绕X轴
        //                ksRotate(&_rotationMatrix, 45, 0.0, 1.0, 0.0); //绕Y轴
        ksRotate(&_rotationMatrix, self.angle, 0.0, 0.0, 1.0); //绕Z轴 立方体的Z
        //(6)把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
        ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
        //(7)将模型视图矩阵传递到顶点着色器
        /*
         void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
         参数列表：
         location:指要更改的uniform变量的位置
         count:更改矩阵的个数
         transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
         value:执行count个元素的指针，用来更新指定uniform变量
         */
        glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        
        //13.开启正背面剔除和深度测试操作效果
        glEnable(GL_CULL_FACE);
        glEnable(GL_DEPTH_TEST);
        
        //14.使用索引绘图
        /*
         void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
         参数列表：
         mode:要呈现的画图的模型
         GL_POINTS
         GL_LINES
         GL_LINE_LOOP
         GL_LINE_STRIP
         GL_TRIANGLES
         GL_TRIANGLE_STRIP
         GL_TRIANGLE_FAN
         count:绘图个数
         type:类型
         GL_BYTE
         GL_UNSIGNED_BYTE
         GL_SHORT
         GL_UNSIGNED_SHORT
         GL_INT
         GL_UNSIGNED_INT
         indices：绘制索引数组
         */
        glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
        
        //15.从渲染缓存区显示到屏幕上
        [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}
//从图片中加载纹理  图片翻转问题可以看这里 https://www.jianshu.com/p/848d982db9f2 有多种解决方案
- (GLuint)setupTexture{
    NSString *myBundlePath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
    NSString *imagePath = [[NSBundle bundleWithPath:myBundlePath] pathForResource:@"lufei" ofType:@"png" inDirectory:@"Images"];
    //1、将 UIImage 转换为 CGImageRef
    CGImageRef spriteImage = [UIImage imageWithContentsOfFile:imagePath].CGImage;
    
    //判断图片是否获取成功
    if (!spriteImage) {
        NSLog(@"Failed to load image");
        exit(1);
    }
    
    //2、读取图片的大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //3.获取图片字节数 宽*高*4（RGBA）
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    
    //4.创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    //5、在CGContextRef上--> 将图片绘制出来
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, width, height);
    
    //6.使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //将图片源文件翻转
    /*
     CTM（current transformation matrix当前转换矩阵）
     CGContextScaleCTM：坐标系X,Y缩放
     CGContextTranslateCTM：坐标系平移
     CGContextRotateCTM：坐标系旋转
     CGContextConcatCTM：
     CGContextGetCTM：获得一份CTM
     https://blog.csdn.net/sqc3375177/article/details/25708447
     */
    CGContextTranslateCTM(spriteContext,0, rect.size.height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //7、画图完毕就释放上下文
    CGContextRelease(spriteContext);
    
    //8、绑定纹理到默认的纹理ID 0
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //9.设置纹理属性
    /*  https://www.jianshu.com/p/1b327789220d
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    //10.载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //11.释放spriteData
    free(spriteData);
    return 0;
}

#pragma mark - 加载/编译 shader 着色器
//加载shader
-(GLuint)loadShaders:(NSString *)vert Withfrag:(NSString *)frag {
    //1.定义2个零时着色器对象
    GLuint verShader, fragShader;
    //创建program
    GLint program = glCreateProgram();
    
    //2.编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：着色器程序字符串
    [self compileShader:&verShader type:GL_VERTEX_SHADER shaderString:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER shaderString:frag];
    
    //3.创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //4.释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}
//编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type shaderString:(NSString *)shaderString{
    //1.读取文件路径字符串
    const GLchar* source = (GLchar *)[shaderString UTF8String];
    
    //2.创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //3.将着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source,NULL);
    
    //4.把着色器源代码编译成目标代码
    glCompileShader(*shader);
}
@end

@interface SLMixColorTextureVC ()
@property (nonatomic, strong) CADisplayLink *displayLink;  //定时器更新 角度
@end
@implementation SLMixColorTextureVC

- (void)viewDidLoad {
    [super viewDidLoad];
    SLMixView *triangleView = [[SLMixView alloc] initWithFrame:self.view.bounds];
    triangleView.tag = 10;
    [self.view addSubview:triangleView];
    [self addCADisplayLink];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.displayLink invalidate];
    self.displayLink = nil;
}
- (void)dealloc {
    NSLog(@"%@ 释放了", NSStringFromClass(self.class));
}
-(void)addCADisplayLink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(rotation)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Events Handle
//更新旋转角度
- (void)rotation {
    @autoreleasepool {
        SLMixView *triangleView = [self.view viewWithTag:10];
        //重新渲染图层
        [triangleView renderLayer];
    }
}

@end

