import CoreGraphics
import Foundation

public struct GIFMetadata: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let frameCount: Int
    public let duration: TimeInterval

    public init(width: Int, height: Int, frameCount: Int, duration: TimeInterval) {
        self.width = width
        self.height = height
        self.frameCount = frameCount
        self.duration = duration
    }
}

public struct GIFFrame: @unchecked Sendable {
    public let image: CGImage
    public let duration: TimeInterval
    public let index: Int
}

public enum GIFDecoderError: LocalizedError {
    case unreadable
    case notGIF
    case empty
    case frameDecodeFailed(Int)

    public var errorDescription: String? {
        switch self {
        case .unreadable: "无法读取这个文件。"
        case .notGIF: "请选择 GIF 动画文件。"
        case .empty: "GIF 中没有可用画面。"
        case let .frameDecodeFailed(index): "无法解码第 \(index + 1) 帧。"
        }
    }
}
