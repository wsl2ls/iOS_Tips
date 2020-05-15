# iOS_Tips
> iOS的一些示例，不定时更新~ 由于内容较多，文件会有点大，建议终端用git clone命令下载，这样以后只需git pull更新就行；有时是GitHub的原因，就从百度网盘：https://pan.baidu.com/s/1UOlN21zWKbQRtVe2I7pPvg (可能不是最新) 下载
简书地址：https://www.jianshu.com/p/a2a04cabb98d 

### 目录 
> 1、暗黑模式  
> 2、AppleID登录应用  
> 3、AVFoundation 高仿微信相机拍摄和编辑   
> 4、AVFoundation 人脸检测  
> 5、AVFoundation 实时滤镜  
> 6、GPUImage框架的使用  
> 7、VideoToolBox和AudioToolBox音视频编解码  
> 8、OpenGL ES学习   
> 9、LeetCode算法练习  
> 10、键盘和UIMenuController的并存问题  
> 11、iOS Crash防护
> 问题说明
 
 
## 1、 暗黑模式适配

![暗黑模式](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/暗黑模式.gif)
  
## 2、AppleID登录应用

* 查看本仓库下的AddingTheSignInWithAppleFlowToYourApp

## 3、[微信相机拍摄照片、小视频以及编辑功能](https://www.jianshu.com/p/a2a04cabb98d)  
> 效果描述：  
> * 1、自定义相机 拍摄视频和照片
> * 2、切换前后摄像头、调整焦距/设置聚焦点、横屏拍摄
> * 3、视频编辑：涂鸦、gif贴图、文字水印、视频裁剪 、添加背景音乐 
> * 4 、图片编辑：涂鸦、贴图、文字水印、马赛克、图片裁剪

> 主要类：SLAvCaptureTool(音视频采集录制工具)、SLAvEditExport(导出编辑的音视频)。关于视频的压缩问题，可以通过降低采集时的分辨率sessionPreset、降低写入文件时的分辨率(AVVideoWidthKey宽AVVideoHeightKey高)和码率(AVVideoCodecKey)、指定高的FormatProfile(AVVideoProfileLevelKey)等方法来实现，同时也要保证一定的清晰度满足业务的需求， 可以看看这篇文章https://www.jianshu.com/p/4f69c22c6dce 

|![拍摄视频.gif](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频1.gif)|![拍摄照片](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频2.gif)|![横屏视频](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频3.gif)|

*****

|![视频编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频4.gif)|![视频编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频5.gif)|![图片编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频6.gif)|

****

|![图片编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频7.gif)|![图片裁剪](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频8.gif)|


## 4、[人脸检测](https://www.jianshu.com/p/f236dc161a90) 

![人脸识别](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/4、人脸识别.gif)

## 5、[实时滤镜拍摄和导出](https://www.jianshu.com/p/f236dc161a90)

>  主要类: 是由SLAvCaptureTool拆分的 SLAvCaptureSession（采集） + SLAvWriterInput（录制） 两个工具类，方便扩展，录制写入实现的方式也略有不同

![人脸识别](PrviewPicture/5、实时滤镜拍摄.gif)

## 6、[GPUImage框架的使用](https://www.jianshu.com/p/97740cd381f7)

> 效果描述：实时拍摄添加水印和滤镜、本地视频添加水印、GIF图水印

* 遗留问题：一个启动周期内，第一次启动摄像头时打开特慢，之后就特别块，还没找到原因，望知道到的告知一下🤝

![GPUImage框架的使用](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/6、GPUImage.gif)

## 7、VideoToolBox和AudioToolBox音视频编解码

> 请查看本仓库下的 VideoEncoder&Decoder 文件

![音视频编码](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/7、音视频编码.gif)

## 8、[OpenGL ES学习](https://www.jianshu.com/p/9259689cac06)

> 示例描述：
> * 1、GLKit 绘制图片和正方体
> * 2、GLSL 绘制金字塔、颜色纹理混合
> * 3、GLSL 滤镜集合：灰度、旋涡、正方形马赛克、六边形马赛克
> * 4 、GLSL 抖音部分特效：分屏、缩放、抖动、灵魂出窍、毛刺

|![OpenGLES学习.gif](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/8、OpenGLES学习1.gif)|![OpenGLES学习](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/8、OpenGLES学习2.gif)|![OpenGLES学习](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/8、OpenGLES学习3.gif)|

## 9、[LeetCode算法练习](https://github.com/wsl2ls/AlgorithmSet.git)

> [LeetCode算法练习集合(Swift版) ~ 每天一道算法题](https://github.com/wsl2ls/AlgorithmSet.git)  

## 10、[键盘和UIMenuController的并存问题]()

| ![问题描述.gif](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/10、键盘和UIMenuController不能同时出现的问题描述.gif) | ![并存问题解决](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/10、键盘和UIMenuController并存问题解决.gif) |

## 11、iOS Crash防护 

> NSArray/NSMutableArray、NSDictionary/NSMutableDictionary、NSString/NSMutableString、Unrecognized Selector、KVO、KVC 、野指针定位、内存泄漏/循环引用

## 问题说明：

> * 1、小视频拍摄录制失败，主要集中在plus和X系列手机上：可能是由于写入的视频宽高videoSize设置的问题，各位可以先试试这样设置
avCaptureTool.videoSize = CGSizeMake(self.view.width * 0.8, self.view.height * 0.8);
> * 2、iPhoneX/XR系列崩溃，错误代码是pods > pods > FBRetainCycleDetector > fishhook.c 第104行
indirect_symbol_bindings[i] = cur->rebindings[j].replacement： FBRetainCycleDetector 这个是三方库里的，检测内存泄漏的，你可以把 MLeaksFinder 移除，这只是一个辅助调试工具。
> * 3、



## Welcome To Follow Me

>  您的follow和start，是我前进的动力，Thanks♪(･ω･)ﾉ
> * [简书](https://www.jianshu.com/u/e15d1f644bea)
> * [微博](https://weibo.com/5732733120/profile?rightmod=1&wvr=6&mod=personinfo&is_all=1)
> * [掘金](https://juejin.im/user/5c00d97b6fb9a049fb436288)
> * [CSDN](https://blog.csdn.net/wsl2ls)
> * QQ交流群：835303405
> * 微信号：w2679114653

> 欢迎扫描下方二维码关注——奔跑的程序猿iOSer——微信公众号：iOS2679114653 本公众号是一个iOS开发者们的分享，交流，学习平台，会不定时的发送技术干货，源码,也欢迎大家积极踊跃投稿，(择优上头条) ^_^分享自己开发攻城的过程，心得，相互学习，共同进步，成为攻城狮中的翘楚！

![iOS开发进阶之路.jpg](http://upload-images.jianshu.io/upload_images/1708447-c2471528cadd7c86.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 推荐学习资料:

> [Swift从入门到精通](https://ke.qq.com/course/392094?saleToken=1693443&from=pclink)

> [恋上数据结构与算法（一）](https://ke.qq.com/course/385223?saleToken=1887678&from=pclink)

> [恋上数据结构与算法（二）](https://ke.qq.com/course/421398?saleToken=1887679&from=pclink)

> [每周一道算法题](https://ke.qq.com/course/436549?saleToken=1887824&from=pclink)
