# 应用图标

- `AppIcon.png`：透明底主图，来自用户提供的图片，经内置图像编辑工具抠图。
- `AppIcon.icns`：由主图使用 macOS `sips` 与 `iconutil` 生成，包含 16–1024 像素尺寸。
- 打包脚本将 ICNS 写入应用 Resources，Info.plist 通过 CFBundleIconFile 引用。

图片权利独立于代码的 MIT 许可；随应用提供以供构建和使用，不授予该图片的额外许可。

图像编辑提示词：

> Use case: background-extraction. Edit target: the supplied image. Extract the COMPLETE central blue macOS app icon onto a genuinely transparent background. Remove only the surrounding pale textured rectangular background and its broad cast shadow. Preserve exactly the blue rounded-square plate, both white lightning bolts, diagonal black and white magic wand, curved peeled edge, and the opaque purple/lavender checkerboard artwork inside the upper right corner. The internal checkerboard is part of the artwork, never transparency. Keep original shapes, colors, proportions, orientation and details; no redesign, no text. Center the complete icon on a square canvas, with approximately 10% transparent padding on each side, no clipped corners or wand. Output clean antialiased alpha edges, high resolution suitable for a macOS application icon.
