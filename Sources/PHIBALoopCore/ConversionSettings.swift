import CoreGraphics
import Foundation

public enum OutputFormat: String, CaseIterable, Codable, Sendable {
    case hevcMP4
    case hevcAlphaMOV

    public var fileExtension: String {
        switch self {
        case .hevcMP4: "mp4"
        case .hevcAlphaMOV: "mov"
        }
    }

    public var displayName: String {
        switch self {
        case .hevcMP4: "HEVC / H.265 MP4"
        case .hevcAlphaMOV: "HEVC Alpha MOV"
        }
    }
}

public enum TransparencyMode: String, CaseIterable, Codable, Sendable {
    case none
    case preserveAlpha
    case colorKey
}

public enum OutputScale: Codable, Equatable, Sendable {
    case original
    case percentage(Double)
    case custom(width: Int, height: Int)
}

public enum FrameRateMode: Codable, Equatable, Sendable {
    case originalTiming
    case fixed(Int)
}

public enum QualityPreset: String, CaseIterable, Codable, Sendable {
    case compact
    case balanced
    case high

    public var bitsPerPixel: Double {
        switch self {
        case .compact: 0.07
        case .balanced: 0.12
        case .high: 0.20
        }
    }
}

public struct RGBColor: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static let green = RGBColor(red: 0, green: 1, blue: 0)
    public static let white = RGBColor(red: 1, green: 1, blue: 1)
}

public struct ConversionSettings: Codable, Equatable, Sendable {
    public var outputFormat: OutputFormat
    public var transparencyMode: TransparencyMode
    public var keyColor: RGBColor
    public var keyTolerance: Double
    public var edgeSoftness: Double
    public var reduceColorSpill: Bool
    public var opaqueFillColor: RGBColor
    public var outputScale: OutputScale
    public var frameRateMode: FrameRateMode
    public var quality: QualityPreset
    public var repeatCount: Int

    public init(
        outputFormat: OutputFormat = .hevcMP4,
        transparencyMode: TransparencyMode = .none,
        keyColor: RGBColor = .green,
        keyTolerance: Double = 0.18,
        edgeSoftness: Double = 0.08,
        reduceColorSpill: Bool = true,
        opaqueFillColor: RGBColor = .white,
        outputScale: OutputScale = .original,
        frameRateMode: FrameRateMode = .originalTiming,
        quality: QualityPreset = .balanced,
        repeatCount: Int = 1
    ) {
        self.outputFormat = outputFormat
        self.transparencyMode = transparencyMode
        self.keyColor = keyColor
        self.keyTolerance = keyTolerance
        self.edgeSoftness = edgeSoftness
        self.reduceColorSpill = reduceColorSpill
        self.opaqueFillColor = opaqueFillColor
        self.outputScale = outputScale
        self.frameRateMode = frameRateMode
        self.quality = quality
        self.repeatCount = max(1, repeatCount)
    }

    public var effectiveTransparencyMode: TransparencyMode {
        outputFormat == .hevcMP4 ? .none : transparencyMode
    }

    public func outputDimensions(sourceWidth: Int, sourceHeight: Int) -> (width: Int, height: Int) {
        let proposed: (Int, Int)
        switch outputScale {
        case .original:
            proposed = (sourceWidth, sourceHeight)
        case let .percentage(scale):
            proposed = (
                Self.nearestEven(Double(sourceWidth) * scale),
                Self.nearestEven(Double(sourceHeight) * scale)
            )
        case let .custom(width, height):
            proposed = (width, height)
        }
        return (Self.even(max(2, proposed.0)), Self.even(max(2, proposed.1)))
    }

    private static func even(_ value: Int) -> Int {
        value.isMultiple(of: 2) ? value : value - 1
    }

    private static func nearestEven(_ value: Double) -> Int {
        max(2, Int((value / 2).rounded()) * 2)
    }
}
