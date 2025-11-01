+++
date = '2025-11-01T12:43:11+08:00'
draft = false
title = 'Index 0 out of bounds for length 0 不一定是你Android代码有问题'

categories = ["开发碎语", "Android","Wear OS"]

[sitemap]
changefreq = "monthly"
priority = 0.8
+++

## 省流

不是代码问题，而是Android Studio自带的模拟器抽风了  
把qemu进程给kill了后重启模拟器即可  


## 详细描述

### 故事背景

原本正在好好地调试我的Wear OS项目  
在一次运行的时候，突然AS提示运行出错`Index 0 out of bounds for length 0`  
并且没有办法运行，因为当时我新写了个有关数组的代码，理所当然是之前代码出现了问题  

### 没有用的解决方案

于是我重新调试了整个逻辑，结果发现都没有效果  
整个文件IDE都没有报错，但是在运行时就出错，非常奇怪  


我甚至把有关的 Compose 代码全部注释掉，结果毫无用处  
然后我又尝试排查系统组件，因为我都把我弄的石山给撤走了，只能怀疑它了  
我把`AndroidManifest.xml`里能注释的都注释了，把AS给的那些默认的框架代码也注释掉  
程序变成了一个空壳，但是还是报错  


后来在不经意发现 Wear OS 的模拟器是卡死的，同时在AS里面也没办法重启停止  
于是我关闭了AS，并在任务管理器里面把`qemu-system-x86_64.exe`给终止
重启AS后可以重启模拟器，于是就恢复正常了  

### 怀疑的可能

不知道为什么AS的 Android 模拟器老是卡死  
而且不单单指我个例，这次卡死后导致 ADB 通信异常  
AS得了错误的数据，导致报错  
另外还有`Emulator failed to connect within 5 minutes`之类的报错  
也是模拟器的问题  

## 总结与教训

~~所以说这个AS是真史啊~~  

这个报错非常有误导性`Index 0 out of bounds for length 0`  
让人因为是自己的问题，结果只是AS自己找不到模拟器  
以后还是需要真机调试啊