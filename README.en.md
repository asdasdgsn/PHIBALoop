# PHIBALoop

A local macOS GIF-to-HEVC converter with animated previews, batch jobs and HEVC Alpha MOV output.

[简体中文](README.md) · [Preview release](https://github.com/asdasdgsn/PHIBALoop/releases/tag/v1.0.0) · [Development guide](docs/DEVELOPMENT.md)

## Features

- Import GIF files through Finder drag-and-drop or the file picker.
- Export HEVC/H.265 MP4, or Apple HEVC Alpha MOV with transparency.
- Preserve existing alpha or remove a solid-color/green background with tolerance, softness and green-spill controls.
- Adjust size, frame timing, quality and repeat count.
- Choose the actual destination directory, avoid overwriting existing names, monitor progress and cancel jobs.
- Validate the exported video track, dimensions and duration.
- Media processing stays on your Mac. No account, API key, FFmpeg or third-party Swift package is required.

## Requirements and downloads

The deployment target is macOS 13. The current prebuilt DMG targets **Apple Silicon (arm64)**. Intel source builds have not been verified. Encoder support depends on the device and OS.

The preview binary is **ad-hoc signed and not Apple-notarized**. macOS may block it. For a trusted public distribution, Developer ID signing and notarization are still required. Building from source is an alternative.

Download the DMG from [v1.0.0](https://github.com/asdasdgsn/PHIBALoop/releases/tag/v1.0.0), then drag the app into Applications.

## Build and test

Use Xcode with a macOS SDK and Swift tools 5.9 or newer:

```bash
git clone https://github.com/asdasdgsn/PHIBALoop.git
cd PHIBALoop
swift run
swift test
./scripts/package-app.sh
```

The app bundle is written to `dist/PHIBALoop.app`. The full local suite contains 11 tests, including two real encoder integration tests. CI runs nine codec-independent tests and builds/packages the app; run the full suite on a Mac with HEVC support.

## Important limitations

MP4 does not preserve alpha. Keeping alpha cannot remove an already opaque green background; use color keying instead. Fixed frame rates repeat frames rather than interpolate motion. Custom dimensions may stretch the image. Input is GIF-only, with no audio. Some players show a black background for transparent HEVC MOV.

The detailed [user guide](docs/USER_GUIDE.md), [development guide](docs/DEVELOPMENT.md) and [contribution guide](CONTRIBUTING.md) are currently in Chinese. Issues and pull requests in English or Chinese are welcome.

## License

[MIT](LICENSE). Apple SDK/framework licensing and rights to your source media remain separate.
