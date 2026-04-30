import XCTest
import AppKit
@testable import MacTextEditor
import ZIPFoundation

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

    func test_docx_produces_data() throws {
        let original = NSAttributedString(string: "Hello docx")
        let data = try DocumentManager.export(original, as: .docx)
        XCTAssertGreaterThan(data.count, 0)
    }

    func test_docx_is_valid_zip() throws {
        let original = NSAttributedString(string: "Test content")
        let data = try DocumentManager.export(original, as: .docx)
        let magic = data.prefix(2)
        XCTAssertEqual(magic, Data([0x50, 0x4B]))
    }

    func test_docx_contains_text() throws {
        let original = NSAttributedString(string: "Unique marker 42")
        let data = try DocumentManager.export(original, as: .docx)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".docx")
        try data.write(to: tempURL)
        let unzipDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: tempURL, to: unzipDir)
        let docXML = try String(contentsOf: unzipDir.appendingPathComponent("word/document.xml"))
        XCTAssertTrue(docXML.contains("Unique marker 42"))
        try? FileManager.default.removeItem(at: tempURL)
        try? FileManager.default.removeItem(at: unzipDir)
    }
}
