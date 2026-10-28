# PHIBALoop 1.0.0 · 开源预览版

一个在 Mac 本地运行的 GIF 转 HEVC 工具，现以 MIT 许可证开源。

- 支持批量导入与 GIF 动态预览。
- 导出 HEVC MP4 和带透明通道的 HEVC Alpha MOV。
- 可保留透明背景或进行纯色/绿幕抠除。
- 支持尺寸、帧率、质量与重复次数调整，以及导出进度、取消和输出验证。
- 已包含导出文件夹和 Finder 拖入修复。

## 下载与安装

`PHIBALoop-1.0-AppleSilicon.dmg` 适用于 Apple 芯片 Mac，应用部署目标为 macOS 13。打开 DMG，将 App 拖入“应用程序”。SHA-256 校验文件随安装包提供。

**此预览包仅作本地临时签名，尚未通过 Apple 公证，macOS 可能阻止直接打开。** 它不是 Developer ID 签名发行版，不保证适用于 Intel Mac；也可从本标签源码自行构建。

MP4 不保留透明度。HEVC Alpha 是否正确显示取决于目标播放器或应用；固定帧率不进行运动补帧。
