import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import PHIBALoopCore

final class GIFDecoderTests: XCTestCase {
    func testInspectsFrameCountDimensionsAndTiming() throws {
        let url = try makeGIF(delays: [0.08, 0.12])
        defer { try? FileManager.default.removeItem(at: url) }

        let metadata = try GIFDecoder().inspect(url: url)

        XCTAssertEqual(metadata.width, 16)
        XCTAssertEqual(metadata.height, 12)
        XCTAssertEqual(metadata.frameCount, 2)
        XCTAssertEqual(metadata.duration, 0.20, accuracy: 0.01)
    }

    func makeGIF(delays: [Double]) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("gif")
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.gif.identifier as CFString,
            delays.count,
            nil
        ) else { throw GIFDecoderError.unreadable }
        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
        ] as CFDictionary)
        for (index, delay) in delays.enumerated() {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(
                data: nil, width: 16, height: 12, bitsPerComponent: 8, bytesPerRow: 64,
                space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.setFillColor(index.isMultiple(of: 2) ? CGColor(red: 1, green: 0, blue: 0, alpha: 1) : CGColor(red: 0, green: 1, blue: 0, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 12))
            CGImageDestinationAddImage(destination, context.makeImage()!, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFUnclampedDelayTime: delay]
            ] as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { throw GIFDecoderError.unreadable }
        return url
    }
}
