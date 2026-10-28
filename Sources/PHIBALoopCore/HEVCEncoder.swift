import AVFoundation
import CoreImage
import Foundation

public enum HEVCEncoderError: LocalizedError {
    case unsupported
    case cannotCreateWriter
    case cannotCreatePixelBuffer
    case appendFailed
    case writingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupported: "这台 Mac 不支持所选 HEVC 编码格式。"
        case .cannotCreateWriter: "无法创建视频编码器。"
        case .cannotCreatePixelBuffer: "无法创建视频画面缓冲区。"
        case .appendFailed: "写入视频画面失败。"
        case let .writingFailed(message): "视频导出失败：\(message)"
        }
    }
}

public struct HEVCEncoder: Sendable {
    public init() {}

    public func encode(
        source: URL,
        destination: URL,
        settings: ConversionSettings,
        progress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws {
        let work = Task.detached(priority: .userInitiated) {
            try Self.encodeSynchronously(
                source: source,
                destination: destination,
                settings: settings,
                progress: progress
            )
        }
        try await withTaskCancellationHandler {
            try await work.value
        } onCancel: {
            work.cancel()
        }
    }

    private static func encodeSynchronously(
        source: URL,
        destination: URL,
        settings: ConversionSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) throws {
        let decoder = GIFDecoder()
        let metadata = try decoder.inspect(url: source)
        let dimensions = settings.outputDimensions(sourceWidth: metadata.width, sourceHeight: metadata.height)
        let temporary = destination.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).\(settings.outputFormat.fileExtension)")
        defer { try? FileManager.default.removeItem(at: temporary) }

        let writer = try AVAssetWriter(
            outputURL: temporary,
            fileType: settings.outputFormat == .hevcMP4 ? .mp4 : .mov
        )
        let codec: AVVideoCodecType = settings.outputFormat == .hevcMP4 ? .hevc : .hevcWithAlpha
        let estimatedRate = Int(Double(dimensions.width * dimensions.height) * settings.quality.bitsPerPixel * 30)
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: dimensions.width,
            AVVideoHeightKey: dimensions.height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: max(250_000, estimatedRate)]
        ]
        guard writer.canApply(outputSettings: outputSettings, forMediaType: .video) else {
            throw HEVCEncoderError.unsupported
        }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        input.expectsMediaDataInRealTime = false
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: dimensions.width,
            kCVPixelBufferHeightKey as String: dimensions.height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )
        guard writer.canAdd(input) else { throw HEVCEncoderError.cannotCreateWriter }
        writer.add(input)
        guard writer.startWriting() else {
            throw HEVCEncoderError.writingFailed(writer.error?.localizedDescription ?? "未知错误")
        }
        writer.startSession(atSourceTime: .zero)

        let processor = TransparencyProcessor()
        var elapsed = 0.0
        let repeats = max(1, settings.repeatCount)
        let expectedFrames: Int
        switch settings.frameRateMode {
        case .originalTiming:
            expectedFrames = max(1, metadata.frameCount * repeats)
        case let .fixed(rate):
            expectedFrames = max(1, Int((metadata.duration * Double(rate) * Double(repeats)).rounded()))
        }
        var completedFrames = 0
        for _ in 0..<repeats {
            try decoder.forEachFrame(url: source) { frame in
                if Task.isCancelled { throw CancellationError() }
                let image = processor.process(frame.image, settings: settings, outputSize: dimensions)
                let sampleCount: Int
                let sampleDuration: TimeInterval
                switch settings.frameRateMode {
                case .originalTiming:
                    sampleCount = 1
                    sampleDuration = frame.duration
                case let .fixed(rate):
                    sampleCount = max(1, Int((frame.duration * Double(rate)).rounded()))
                    sampleDuration = 1 / Double(max(1, rate))
                }
                for _ in 0..<sampleCount {
                    while !input.isReadyForMoreMediaData {
                        if Task.isCancelled { throw CancellationError() }
                        Thread.sleep(forTimeInterval: 0.002)
                    }
                    var buffer: CVPixelBuffer?
                    guard let pool = adaptor.pixelBufferPool,
                          CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
                          let buffer else {
                        throw HEVCEncoderError.cannotCreatePixelBuffer
                    }
                    processor.render(image, to: buffer)
                    let presentation = CMTime(seconds: elapsed, preferredTimescale: 600)
                    guard adaptor.append(buffer, withPresentationTime: presentation) else {
                        throw HEVCEncoderError.appendFailed
                    }
                    elapsed += sampleDuration
                    completedFrames += 1
                    progress(min(1, Double(completedFrames) / Double(expectedFrames)))
                }
            }
        }
        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(seconds: elapsed, preferredTimescale: 600))
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting { semaphore.signal() }
        semaphore.wait()
        guard writer.status == .completed else {
            throw HEVCEncoderError.writingFailed(writer.error?.localizedDescription ?? "未知错误")
        }
        try FileManager.default.moveItem(at: temporary, to: destination)
    }
}
