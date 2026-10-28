import XCTest
@testable import PHIBALoopCore

final class ConversionSettingsTests: XCTestCase {
    func testOutputExtensionsMatchContainers() {
        XCTAssertEqual(OutputFormat.hevcMP4.fileExtension, "mp4")
        XCTAssertEqual(OutputFormat.hevcAlphaMOV.fileExtension, "mov")
    }

    func testMP4DisablesTransparency() {
        var settings = ConversionSettings()
        settings.transparencyMode = .preserveAlpha
        settings.outputFormat = .hevcMP4

        XCTAssertEqual(settings.effectiveTransparencyMode, .none)
    }

    func testAlphaMOVPreservesTransparencyChoice() {
        var settings = ConversionSettings()
        settings.outputFormat = .hevcAlphaMOV
        settings.transparencyMode = .colorKey

        XCTAssertEqual(settings.effectiveTransparencyMode, .colorKey)
    }

    func testScaledDimensionsAreEven() {
        let settings = ConversionSettings(outputScale: .percentage(0.75))
        XCTAssertEqual(settings.outputDimensions(sourceWidth: 321, sourceHeight: 199).width, 240)
        XCTAssertEqual(settings.outputDimensions(sourceWidth: 321, sourceHeight: 199).height, 150)
    }
}
