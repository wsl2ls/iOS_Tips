# [iOS_Tips](https://github.com/wsl2ls/iOS_Tips)
> iOS的一些示例，不定时更新~  

| [简书 ](https://www.jianshu.com/u/e15d1f644bea) | [掘金](https://juejin.im/user/5c00d97b6fb9a049fb436288) |  
| ---- | ---- | 
| [CSDN](https://blog.csdn.net/wsl2ls) | [微博](https://weibo.com/5732733120/profile?rightmod=1&wvr=6&mod=personinfo&is_all=1) |

### 目录 
> 1、[暗黑模式](#1-暗黑模式适配)  
> 2、[AppleID登录应用](#2-AppleID登录应用)  
> 3、[AVFoundation相关](#3-AVFoundation相关)
>> 3.1、AVFoundation 高仿微信相机拍摄和编辑   
>> 3.2、AVFoundation 人脸检测  
>> 3.3、AVFoundation 实时滤镜  
>> 3.4、GPUImage框架的使用  
>> 3.5、VideoToolBox和AudioToolBox音视频编解码  
>> 3.6、AVFoundation 利用摄像头实时识别物体颜色  
>> 3.7、AVFoundation 原生二维码扫描识别和生成

> 4、[OpenGL ES学习](#4-OpenGLES学习)  
> 5、[LeetCode算法练习](#5-LeetCode算法练习)  
> 6、[工作中踩过的坑](#6-工作中踩过的坑)
>> 6.1、键盘和UIMenuController不能同时存在的问题  
>> 6.2、全屏侧滑手势/UIScrollView/UISlider间滑动手势冲突  
>> 6.3、UITableView/UICollectionView获取特定位置的cell  
>> 6.4、UIScrollView视觉差动画  
>> 6.5、iOS 传感器集锦  
>> 6.6、iOS 自定义转场动画  
>> 6.7、二进制重排优化启动速度  
>> 6.8、iOS APM应用性能监控管理(doing)  
>> 6.9、ipa瘦身之扫描无用资源  
>> 6.10、多个UIScrollView嵌套/个人中心页

> 7、[iOS Crash防护](#7-iOSCrash防护)  
> 8、[WKWebView相关](#8-WKWebView相关) 
>> 8.1、WKWebView的使用  
>> 8.2、WKWebView+UITableView混排    
>> 8.3、WKWebView离线缓存功能  
>> 8.4、Html非文本元素替换为原生组件展示  
>> 8.5、UIScrollView实现原理  
>> 8.6、UITableView的实现原理 

> [高质量技术博客集合](iOS_Tips/DarkMode/WorkIssues/高质量技术博客.md)  
> [结尾](#结尾)

 
## 1-暗黑模式适配

![暗黑模式](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/暗黑模式.gif)
  
## 2-AppleID登录应用

* 查看本仓库下的AddingTheSignInWithAppleFlowToYourApp

## 3-AVFoundation相关

#### 3.1-[微信相机拍摄照片、小视频以及编辑功能](https://www.jianshu.com/p/a2a04cabb98d)  
> 效果描述：  
> * 1、自定义相机 拍摄视频和照片
> * 2、切换前后摄像头、调整焦距/设置聚焦点、横屏拍摄
> * 3、视频编辑：涂鸦、gif贴图、文字水印、视频裁剪 、添加背景音乐 
> * 4 、图片编辑：涂鸦、贴图、文字水印、马赛克、图片裁剪

> 主要类：SLAvCaptureTool(音视频采集录制工具)、SLAvEditExport(导出编辑的音视频)。关于视频的压缩问题，可以通过降低采集时的分辨率sessionPreset、降低写入文件时的分辨率(AVVideoWidthKey宽AVVideoHeightKey高)和码率(AVVideoCodecKey)、指定高的FormatProfile(AVVideoProfileLevelKey)等方法来实现，同时也要保证一定的清晰度满足业务的需求， 可以看看这篇文章https://www.jianshu.com/p/4f69c22c6dce 

|![拍摄视频.gif](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频1.gif)|![拍摄照片](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频2.gif)|![横屏视频](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频3.gif)|
| ----  | ----  | ----  |
|![视频编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频4.gif)|![视频编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频5.gif)|![图片编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频6.gif)|
|![图片编辑](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频7.gif)|![图片裁剪](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3、小视频8.gif)|


#### 3.2-[人脸检测](https://www.jianshu.com/p/f236dc161a90) 

![人脸识别](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/4、人脸识别.gif)

#### 3.3-[实时滤镜拍摄和导出](https://www.jianshu.com/p/f236dc161a90)

>  主要类: 是由SLAvCaptureTool拆分的 SLAvCaptureSession（采集） + SLAvWriterInput（录制） 两个工具类，方便扩展，录制写入实现的方式也略有不同

![人脸识别](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/5、实时滤镜拍摄.gif)

#### 3.4-[GPUImage框架的使用](https://www.jianshu.com/p/97740cd381f7)

> 效果描述：实时拍摄添加水印和滤镜、本地视频添加水印、GIF图水印

![GPUImage框架的使用](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/6、GPUImage.gif)

#### 3.5-VideoToolBox和AudioToolBox音视频编解码

> 请查看本仓库下的 VideoEncoder&Decoder 文件

![音视频编码](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/7、音视频编码.gif)

#### 3.6-AVFoundation 利用摄像头实时识别物体颜色 

![音视频编码](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/3.6、拾色器.gif)

#### 3.7-[AVFoundation 原生二维码扫描识别和生成](https://juejin.im/post/5c0e1db651882539c60d0434)

  > 该代码地址在：https://github.com/wsl2ls/ScanQRcode

## 4-OpenGLES学习

> 示例描述：
> * 1、GLKit 绘制图片和正方体
> * 2、GLSL 绘制金字塔、颜色纹理混合
> * 3、GLSL 滤镜集合：灰度、旋涡、正方形马赛克、六边形马赛克
> * 4 、GLSL 抖音部分特效：分屏、缩放、抖动、灵魂出窍、毛刺

|![OpenGLES学习.gif](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/8、OpenGLES学习1.gif)|![OpenGLES学习](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/8、OpenGLES学习2.gif)|![OpenGLES学习](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/8、OpenGLES学习3.gif)|

## 5-LeetCode算法练习

> [LeetCode算法练习集合(Swift版) ~ 每天一道算法题](https://github.com/wsl2ls/AlgorithmSet.git)  

## 6-工作中踩过的坑

#### 6.1-[键盘和UIMenuController的并存问题](https://www.jianshu.com/p/ed1b57c4ecea)  

| ![问题描述.gif](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/10、键盘和UIMenuController不能同时出现的问题描述.gif) | ![并存问题解决](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/10、键盘和UIMenuController并存问题解决.gif) |

#### 6.2-[全屏侧滑手势/UIScrollView/UISlider间滑动手势冲突](https://juejin.im/post/5c0e1e73f265da616413d828)
#### 6.3-[UITableView/UICollectionView获取特定位置的cell](https://juejin.im/post/5c0e1df95188250d2722a3bc)
#### 6.4-[UIScrollView视觉差动画](https://juejin.im/post/5c088b45f265da610e7fe156)  
#### 6.5-[iOS 传感器集锦](https://juejin.im/post/5c088a1051882517165dd15d)  
#### 6.6-[iOS 自定义转场动画](https://juejin.im/post/5c088ba36fb9a049fb43737b)
#### 6.7-[二进制重排优化启动速度](https://juejin.im/post/5ea79839f265da7bba509590)
#### 6.8-[iOS APM应用性能监控管理(doing)]()

> CPU占用率、内存/磁盘使用率、卡顿监控定位、Crash防护、线程数量监控、网络监控(TCP 建立连接时间 、DNS 时间、 SSL时间、首包时间、响应时间 、流量)、ViewController启动耗时监测 、load方法的耗时、方法执行耗时......

#### 6.9、ipa瘦身之扫描无用资源

> 扫描项目中无用的图片、类等文件资源, 此示例主要针对于此项目中的图片资源，其他类型资源实现原理相同。

#### 6.10、多个UIScrollView嵌套/个人中心页

![多个UIScrollView嵌套](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/多个UIScrollView嵌套.gif)

## 7-iOSCrash防护 

>  Crash防护内容涉及 NSArray/NSMutableArray、NSDictionary/NSMutableDictionary、NSString/NSMutableString、Unrecognized Selector、KVO、KVC 、异步线程刷新UI、野指针定位、内存泄漏/循环引用；主要是对常见易错的地方进行容错处理，避免崩溃，并保存出错时的函数调用栈，以方便快速定位代码，主要是利用的runtime和fishook知识。

![iOSCrash防护](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/iOSCrash防护.gif)

## 8-WKWebView相关

> [WKWebView的使用](https://juejin.im/post/5c0e1e2ae51d451d971743a1)、[WKWebView+UITableView混排](https://juejin.im/post/5ed999fd51882542f9389949)、WKWebView离线缓存功能、HTML非文本元素替换为原生组件展示、UIScrollView实现原理、UITableView的实现原理

![WKWebView相关](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/12、WKWebView.gif)

## 结尾

> * 1、主工程就是iOS_Tips下的DarkMode，别怀疑🤣，历史遗留问题😁😀，大部分内容都在里面，run一下就明白了🤝；
> * 2、该demo里面有些功能还没有写博客介绍，后期有时间会补上，不过代码我一般喜欢写注释，所以我相信大家读起来应该也容易理解，建议大家看完之后，自己也可以写写，把整个流程过一遍，也许会比我写的更好哟；
> * 3、[看过的高质量技术博客集合](iOS_Tips/DarkMode/WorkIssues/高质量技术博客.md)，这些博客质量都挺高的，都出自各个大厂、大佬之手，认真看完绝对干活满满；
> * 4、小视频拍摄录制失败，主要集中在plus和X系列手机上：可能是由于写入的视频宽高videoSize设置的问题，各位可以先试试这样设置
avCaptureTool.videoSize = CGSizeMake(self.view.width * 0.8, self.view.height * 0.8);
> * 5、当你编译的时候，XCode出现Unable to load contents of file list 错误，导致出现此原因是pods版本不一致，请更新pods版本或者重新安装。
> * 6、如果发现我简书或掘金上的文章无法查看了，请联系我。


#### Welcome to you 👏 您的follow和start，是我前进的动力，Thanks♪(･ω･)ﾉ 🤝

| [简书 ](https://www.jianshu.com/u/e15d1f644bea) | [掘金](https://juejin.im/user/5c00d97b6fb9a049fb436288) |  QQ交流群 | 微信公众号 |  微信交流群 |
| ---- | ---- | ---- | ---- | ---- |
| [CSDN](https://blog.csdn.net/wsl2ls) | [微博](https://weibo.com/5732733120/profile?rightmod=1&wvr=6&mod=personinfo&is_all=1) | [835303405](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/QQ交流群.png) |  [iOS2679114653](https://github.com/wsl2ls/iOS_TipsPreview/blob/master/PrviewPicture/微信公众号.png) | w2679114653(加我拉入群) |

[回到顶部](#iOS_Tips)

![QQ交流群: 835303405](QQ交流群.png)

> 欢迎扫描下方二维码关注——奔跑的程序猿iOSer——微信公众号：iOS2679114653 本公众号是一个iOS开发者们的分享，交流，学习平台，会不定时的发送技术干货，源码,也欢迎大家积极踊跃投稿，(择优上头条) ^_^分享自己开发攻城的过程，心得，相互学习，共同进步，成为攻城狮中的翘楚！

![奔跑的程序猿iOSer](微信公众号.png)
