# 开发与打包

[返回 README](../README.md)

## 环境与结构

最低部署目标为 macOS 13，Swift Package 工具版本为 5.9。需要可用的 Xcode macOS SDK。发布前本地验证使用 Xcode 27.1、Apple Silicon；较旧工具链和 Intel 尚未逐一验证。

```text
Package.swift
Sources/
  PHIBALoopApp/       SwiftUI/AppKit 窗口、队列、导入与动态预览
  PHIBALoopCore/      GIF 解码、透明处理、HEVC 编码、导出路径与校验
Tests/
  PHIBALoopCoreTests/ 核心单元测试与真实编码测试
Packaging/Info.plist .app 元数据
scripts/package-app.sh
```

项目没有远程 Swift 包依赖，只使用 Apple 系统框架。不要把 SDK、个人 GIF、缓存、导出视频或证书提交到仓库。

## 本地开发

在仓库根目录执行：

```bash
swift run
swift test
swift build -c release
```

或使用 Xcode 打开 `Package.swift`。如果本机安装了多个 Xcode，可为当前命令指定安装路径，不必更改全局选择：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## 测试范围

完整套件包含设置、输出尺寸、Finder URL 解码、GIF 帧时序、目标目录与同名文件处理，以及 MP4/MOV 实际编码测试。

GitHub 托管虚拟机不保证提供与本机相同的编码器，CI 有意跳过两项真实编码集成测试：

```bash
swift test --skip HEVCEncoderTests
```

这不等同于完整验证。修改编码、透明处理或帧时序后，仍需在具备 HEVC 支持的 Mac 上运行 `swift test`，并在实际目标应用中检查透明效果和时长。

## .app 与 DMG

```bash
./scripts/package-app.sh
open dist/PHIBALoop.app
```

脚本会创建 `dist/PHIBALoop.app` 并使用临时本地签名。它不会安装应用，也不会执行 Developer ID 签名、公证或自动上传。

安装包本身是普通 DMG，内含应用与指向 `/Applications` 的快捷入口。可使用 macOS 的磁盘映像工具，将生成的应用与入口放入镜像。DMG 校验通过仅代表映像完整，不代表通过 Apple 公证。

当前预编译包只提供 arm64，不能视为 Universal 或已验证的 Intel 发行版。`swift build` 默认针对运行构建命令的本机架构。

## 对外分发

可信公开分发需要开发者自行准备 Developer ID Application 身份、签名所需权限配置、Hardened Runtime、公证与票据附加流程。身份名称、证书私钥、公证凭证不得写入脚本或提交到 Git；当前脚本不包含这些配置。

当前 v1.0.0 安装包仅作未公证预览。不要通过全局关闭 Gatekeeper 等方式替代正式签名与公证。

## 独立仓库来源

本仓库从 PHIBAWeather 工作区的 PHIBALoop 子项目独立导出，保留工具源码与测试，但不包含天气 App、后台服务、用户媒体、凭证或其 Git 历史。独立导出没有改变运行时功能。
