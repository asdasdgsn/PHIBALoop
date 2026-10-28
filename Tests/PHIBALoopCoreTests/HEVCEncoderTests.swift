import AVFoundation
import XCTest
@testable import PHIBALoopCore

final class HEVCEncoderTests: XCTestCase {
    func testExportsPlayableHEVCMP4() async throws {
        let source = try GIFDecoderTests().makeGIF(delays: [0.08, 0.12])
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: output)
        }

        try await HEVCEncoder().encode(source: source, destination: output, settings: ConversionSettings())

        let asset = AVURLAsset(url: output)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertEqual(tracks.count, 1)
        let descriptions = try await tracks[0].load(.formatDescriptions)
        XCTAssertEqual(CMFormatDescriptionGetMediaSubType(descriptions[0]), kCMVideoCodecType_HEVC)
        let duration = try await asset.load(.duration)
        XCTAssertEqual(duration.seconds, 0.20, accuracy: 0.04)
    }

    func testExportsPlayableHEVCAlphaMOV() async throws {
        let source = try GIFDecoderTests().makeGIF(delays: [0.08, 0.12])
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: output)
        }
        var settings = ConversionSettings()
        settings.outputFormat = .hevcAlphaMOV
        settings.transparencyMode = .colorKey

        try await HEVCEncoder().encode(source: source, destination: output, settings: settings)

        let asset = AVURLAsset(url: output)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertEqual(tracks.count, 1)
        let descriptions = try await tracks[0].load(.formatDescriptions)
        XCTAssertEqual(CMFormatDescriptionGetMediaSubType(descriptions[0]), kCMVideoCodecType_HEVC)
    }
}
