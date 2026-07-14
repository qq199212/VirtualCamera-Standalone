# VirtualCamera 虚拟相机插件
适配 RootHide 越狱 + iOS arm64e 架构 | 音视频同步版

## 功能说明
全局替换系统相机输入，所有App调用相机时都会自动播放指定的本地视频，音画同步，循环播放。

## 核心特性
✅ 音视频同步输出，画面和声音完美匹配
✅ 自动循环播放，无需手动重复
✅ 适配RootHide越狱，arm64e架构，iOS15+全兼容
✅ 纯原生编译，不依赖Theos，编译速度快零依赖

## 使用方法
1. 准备MP4视频（H.264/AAC编码），重命名为 `virtualcam.mp4`
2. 用Filza文件管理器放到手机的 `/var/mobile/Library/` 目录
3. 安装deb插件，重启SpringBoard
4. 打开任意App调用相机，就会播放替换视频

## 编译方法（GitHub Actions自动编译）
1. 将所有文件上传到GitHub公开仓库
2. 提交后自动触发Actions编译，1-2分钟完成
3. 编译完成后在Actions页面的Artifacts下载deb包

## 适配说明
- 架构：iphoneos-arm64e
- 系统：iOS 15.0 ~ 17.x
- 越狱：RootHide 越狱环境
- 依赖：mobilesubstrate（越狱自带）

## 联系方式
Telegram：@MWMWVIP

## 合法使用声明
1. 本插件仅限开发测试和个人合法用途
2. 严禁用于诈骗、人脸伪造、考勤作弊、游戏作弊等违法违规场景
3. 使用本插件产生的一切后果由使用者自行承担
