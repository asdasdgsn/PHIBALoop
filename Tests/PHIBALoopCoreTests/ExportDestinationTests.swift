import Foundation
import XCTest
@testable import PHIBALoopCore

final class ExportDestinationTests: XCTestCase {
    func testUsesTheExactUserSelectedDirectory() {
        let source = URL(fileURLWithPath: "/input/animation.gif")
        let selectedDirectory = URL(fileURLWithPath: "/Volumes/Exports/My Animations")

        let result = ExportDestination.availableURL(
            source: source,
            directory: selectedDirectory,
            format: .hevcAlphaMOV,
            fileExists: { _ in false }
        )

        XCTAssertEqual(result.deletingLastPathComponent().path, selectedDirectory.path)
        XCTAssertEqual(result.lastPathComponent, "animation.mov")
    }

    func testAddsSuffixWithoutChangingSelectedDirectory() {
        let source = URL(fileURLWithPath: "/input/animation.gif")
        let selectedDirectory = URL(fileURLWithPath: "/tmp/output")

        let result = ExportDestination.availableURL(
            source: source,
            directory: selectedDirectory,
            format: .hevcMP4,
            fileExists: { $0.hasSuffix("animation.mp4") }
        )

        XCTAssertEqual(result.deletingLastPathComponent().path, selectedDirectory.path)
        XCTAssertEqual(result.lastPathComponent, "animation-2.mp4")
    }
}
