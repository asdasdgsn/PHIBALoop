# PHIBALoop

**把 GIF 动画转换成适合应用与创作使用的 HEVC 视频，支持透明 MOV。**

[English](README.en.md) · [下载预览版](https://github.com/asdasdgsn/PHIBALoop/releases/tag/v1.0.0) · [使用指南](docs/USER_GUIDE.md) · [开发与打包](docs/DEVELOPMENT.md) · [更新日志](CHANGELOG.md)

PHIBALoop 是使用 SwiftUI、AppKit、ImageIO 和 AVFoundation 编写的 macOS 本地转换工具。不需要账户、API 密钥、FFmpeg 或第三方 Swift 包；媒体处理在本机完成，应用代码不包含网络上传或遥测逻辑。

## 主要功能

- 批量添加 GIF，支持 Finder 拖入、文件选择和打开关联文件。
- 动态预览 GIF，查看尺寸和帧数。
- 导出 **HEVC / H.265 MP4** 或 **Apple HEVC Alpha MOV**。
- MOV 支持保留原始透明度，或通过纯色/绿幕抠除生成透明背景。
- 可调抠色容差、边缘柔化和绿色溢色抑制。
- 支持原始尺寸、75%、50% 或自定义尺寸，保留原始帧时序或选择 24/30/60 fps。
- 提供小体积、平衡、高质量三档及重复次数设置。
- 选择实际导出目录，避免覆盖同名文件；提供进度、取消、错误提示与 Finder 定位。
- 转换完成后检查视频轨道、输出尺寸与时长。

## 安装与要求

- 应用最低部署目标：**macOS 13**。
- 当前预编译 DMG：**Apple Silicon / arm64**，已在维护者的 Apple 芯片 Mac 上构建与测试。
- Intel Mac 可尝试源码构建，但尚未验证；HEVC、尤其 HEVC Alpha 的编码可用性取决于设备及系统。
- 当前安装包为**本地临时签名、未经过 Apple 公证的预览版**，系统可能阻止直接打开。需要可公开信任的分发包时，应由维护者完成 Developer ID 签名及公证；也可以自行从源码构建。

从 [v1.0.0 Releases](https://github.com/asdasdgsn/PHIBALoop/releases/tag/v1.0.0) 下载 DMG，打开后将 `PHIBALoop.app` 拖入“应用程序”。请同时阅读该版本的签名状态说明。

## 快速使用

1. 添加或拖入 GIF。
2. 在右侧选择输出格式及参数。
3. 如需透明背景，选择 **HEVC Alpha MOV**，再选择“保留原透明”或“纯色抠除”。
4. 在左下角选择导出文件夹，确认后开始转换。
5. 查看任务状态，并在完成后通过 Finder 定位结果。

MP4 不保存透明通道；将绿色背景的 GIF 选为“保留原透明”也不会自动去掉绿色，需使用“纯色抠除”。[更多说明与常见问题](docs/USER_GUIDE.md)

## 从源码运行

需要带 macOS SDK 的 Xcode，Swift 工具版本至少为 5.9。首次使用需完成 Xcode 的许可与组件安装。

```bash
git clone https://github.com/asdasdgsn/PHIBALoop.git
cd PHIBALoop
swift run
```

也可以在 Xcode 中打开 `Package.swift`，选择 `PHIBALoop` 和本机 Mac 后运行。

```bash
# 完整测试，包含实际视频编码测试
swift test

# Release 构建并生成本地签名 .app
./scripts/package-app.sh
open dist/PHIBALoop.app
```

项目原先位于 PHIBAWeather 工作区的 `PHIBALoop/` 子目录；本仓库是独立发布的源码快照，以上命令均在本仓库根目录执行。[构建、架构、DMG 与公证说明](docs/DEVELOPMENT.md)

## 测试与限制

- 开源发布前在 Apple 芯片 Mac 上通过 **11 项测试**，包括真实 MP4 与 HEVC Alpha MOV 编码。
- GitHub Actions 在 macOS 上检查 9 项不依赖编码器的单元测试、Release 打包和签名完整性；两项真实编码测试应在具备相应编码能力的 Mac 上运行。
- 固定帧率通过重复帧实现，不生成运动插帧，输出时长可能受取整影响。
- 自定义宽高不会自动锁定原始宽高比；不同比例会拉伸画面。视频尺寸会调整为偶数。
- 当前输入仅支持 GIF，无音频轨道，不是通用视频编辑器或 MOV/MP4 转 GIF 工具。
- HEVC Alpha 在部分播放器中可能显示为黑色背景，不能据此单独判断透明通道是否存在。

## 参与与许可

欢迎提交 [问题](https://github.com/asdasdgsn/PHIBALoop/issues) 和 Pull Request。请先阅读 [贡献指南](CONTRIBUTING.md)。安全问题请查看 [安全政策](SECURITY.md)，不要公开上传私密媒体或凭证。

本项目原始代码采用 [MIT License](LICENSE)。Apple 系统框架不包含在本仓库中，并受其各自许可约束；输入素材及输出内容的使用权由使用者自行确认。
