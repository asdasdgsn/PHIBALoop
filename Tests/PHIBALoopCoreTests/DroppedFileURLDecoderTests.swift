import Foundation
import XCTest
@testable import PHIBALoopCore

final class DroppedFileURLDecoderTests: XCTestCase {
    func testDecodesFinderFileURLRepresentation() throws {
        let expected = URL(fileURLWithPath: "/tmp/PHIBA Loop/test.gif")
        let data = try XCTUnwrap(expected.absoluteString.data(using: .utf8))

        XCTAssertEqual(try DroppedFileURLDecoder.decode(data), expected)
    }

    func testRejectsNonFileURL() throws {
        let data = try XCTUnwrap("https://example.com/test.gif".data(using: .utf8))

        XCTAssertThrowsError(try DroppedFileURLDecoder.decode(data))
    }
}
