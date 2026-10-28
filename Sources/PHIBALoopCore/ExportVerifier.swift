import AVFoundation
import Foundation

public enum ExportVerificationError: LocalizedError {
    case missingVideo
    case invalidDimensions
    case invalidDuration

    public var errorDescription: String? {
        switch self {
        case .missingVideo: "导出的文件不包含有效视频轨道。"
        case .invalidDimensions: "导出视频尺寸验证失败。"
        case .invalidDuration: "导出视频时长验证失败。"
        }
    }
}

public enum ExportVerifier {
    public static func verify(
        url: URL,
        expectedWidth: Int,
        expectedHeight: Int,
        expectedDuration: TimeInterval
    ) async throws {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ExportVerificationError.missingVideo
        }
        let size = try await track.load(.naturalSize)
        guard Int(abs(size.width)) == expectedWidth, Int(abs(size.height)) == expectedHeight else {
            throw ExportVerificationError.invalidDimensions
        }
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0,
              abs(duration - expectedDuration) <= max(0.08, expectedDuration * 0.08) else {
            throw ExportVerificationError.invalidDuration
        }
    }
}
