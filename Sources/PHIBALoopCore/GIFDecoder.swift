import ImageIO
import UniformTypeIdentifiers

public struct GIFDecoder: Sendable {
    public init() {}

    public func inspect(url: URL) throws -> GIFMetadata {
        let source = try imageSource(url: url)
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { throw GIFDecoderError.empty }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw GIFDecoderError.unreadable
        }
        let duration = (0..<count).reduce(0) { $0 + frameDuration(index: $1, source: source) }
        return GIFMetadata(width: width, height: height, frameCount: count, duration: duration)
    }

    public func firstFrame(url: URL) throws -> CGImage {
        let source = try imageSource(url: url)
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw GIFDecoderError.empty
        }
        return image
    }

    public func forEachFrame(
        url: URL,
        _ body: (GIFFrame) throws -> Void
    ) throws {
        let source = try imageSource(url: url)
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { throw GIFDecoderError.empty }
        for index in 0..<count {
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                throw GIFDecoderError.frameDecodeFailed(index)
            }
            try body(GIFFrame(image: image, duration: frameDuration(index: index, source: source), index: index))
        }
    }

    private func imageSource(url: URL) throws -> CGImageSource {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw GIFDecoderError.unreadable
        }
        guard CGImageSourceGetType(source) as String? == UTType.gif.identifier else {
            throw GIFDecoderError.notGIF
        }
        return source
    }

    private func frameDuration(index: Int, source: CGImageSource) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }
        let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gif[kCGImagePropertyGIFDelayTime] as? Double
        return max(unclamped ?? clamped ?? 0.1, 0.02)
    }
}
