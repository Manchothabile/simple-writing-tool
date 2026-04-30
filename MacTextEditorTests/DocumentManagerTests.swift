import XCTest
import AppKit
@testable import MacTextEditor

final class DocumentManagerTests: XCTestCase {

    func test_txt_roundtrip() throws {
        let original = NSAttributedString(string: "Hello world\nSecond line")
        let data = try DocumentManager.export(original, as: .txt)
        let loaded = try DocumentManager.importFile(data: data, format: .txt)
        XCTAssertEqual(loaded.string, "Hello world\nSecond line")
    }

    func test_rtf_roundtrip() throws {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Georgia", size: 16)!,
            .foregroundColor: NSColor.black
        ]
        let original = NSAttributedString(string: "Bold test", attributes: attrs)
        let data = try DocumentManager.export(original, as: .rtf)
        let loaded = try DocumentManager.importFile(data: data, format: .rtf)
        XCTAssertEqual(loaded.string, "Bold test")
    }

    func test_txt_export_strips_formatting() throws {
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 14)]
        let original = NSAttributedString(string: "Styled text", attributes: attrs)
        let data = try DocumentManager.export(original, as: .txt)
        let str = String(data: data, encoding: .utf8)
        XCTAssertEqual(str, "Styled text")
    }
}
