import Foundation
import AppKit
import ZIPFoundation

enum DocumentFormat: String, CaseIterable {
    case txt, rtf, docx

    var fileExtension: String { rawValue }
    var utType: String {
        switch self {
        case .txt: return "public.plain-text"
        case .rtf: return "public.rtf"
        case .docx: return "org.openxmlformats.wordprocessingml.document"
        }
    }
}

enum DocumentError: Error {
    case exportFailed, importFailed, unsupportedFormat
}

enum DocumentManager {
    static func export(_ attrStr: NSAttributedString, as format: DocumentFormat) throws -> Data {
        switch format {
        case .txt:
            guard let data = attrStr.string.data(using: .utf8) else { throw DocumentError.exportFailed }
            return data
        case .rtf:
            let range = NSRange(location: 0, length: attrStr.length)
            guard let data = try? attrStr.data(
                from: range,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) else { throw DocumentError.exportFailed }
            return data
        case .docx:
            return try exportDocx(attrStr)
        }
    }

    static func importFile(data: Data, format: DocumentFormat) throws -> NSAttributedString {
        switch format {
        case .txt:
            guard let str = String(data: data, encoding: .utf8) else { throw DocumentError.importFailed }
            return NSAttributedString(string: str)
        case .rtf:
            guard let attrStr = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) else { throw DocumentError.importFailed }
            return attrStr
        case .docx:
            throw DocumentError.unsupportedFormat
        }
    }

    // MARK: - DOCX export

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml" ContentType="application/xml"/>
      <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
    </Types>
    """

    private static let relsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
    </Relationships>
    """

    private static let wordRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    </Relationships>
    """

    private static func buildDocumentXML(_ attrStr: NSAttributedString) -> String {
        var paragraphsXML = ""
        let fullString = attrStr.string
        var searchStart = fullString.startIndex

        while searchStart < fullString.endIndex {
            let lineEnd = fullString[searchStart...].firstIndex(of: "\n") ?? fullString.endIndex
            let paragraphRange = NSRange(searchStart..<lineEnd, in: fullString)
            let para = attrStr.attributedSubstring(from: paragraphRange)

            var alignVal = "left"
            if para.length > 0,
               let style = para.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                switch style.alignment {
                case .center: alignVal = "center"
                case .right: alignVal = "right"
                case .justified: alignVal = "both"
                default: alignVal = "left"
                }
            }

            var runsXML = ""
            if para.length > 0 {
                para.enumerateAttributes(in: NSRange(location: 0, length: para.length)) { attrs, range, _ in
                    let text = (para.string as NSString).substring(with: range)
                    let escaped = text
                        .replacingOccurrences(of: "&", with: "&amp;")
                        .replacingOccurrences(of: "<", with: "&lt;")
                        .replacingOccurrences(of: ">", with: "&gt;")

                    var rPr = ""
                    if let font = attrs[.font] as? NSFont {
                        if font.fontDescriptor.symbolicTraits.contains(.bold) { rPr += "<w:b/>" }
                        if font.fontDescriptor.symbolicTraits.contains(.italic) { rPr += "<w:i/>" }
                        let sz = Int(font.pointSize * 2)
                        let name = font.familyName ?? "Georgia"
                        rPr += "<w:sz w:val=\"\(sz)\"/>"
                        rPr += "<w:rFonts w:ascii=\"\(name)\" w:hAnsi=\"\(name)\"/>"
                    }
                    if (attrs[.underlineStyle] as? Int).map({ $0 != 0 }) == true {
                        rPr += "<w:u w:val=\"single\"/>"
                    }

                    runsXML += "<w:r>"
                    if !rPr.isEmpty { runsXML += "<w:rPr>\(rPr)</w:rPr>" }
                    runsXML += "<w:t xml:space=\"preserve\">\(escaped)</w:t></w:r>"
                }
            }

            paragraphsXML += "<w:p><w:pPr><w:jc w:val=\"\(alignVal)\"/></w:pPr>\(runsXML)</w:p>"

            if lineEnd < fullString.endIndex {
                searchStart = fullString.index(after: lineEnd)
            } else { break }
        }

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:body>\(paragraphsXML)</w:body>
        </w:document>
        """
    }

    private static func exportDocx(_ attrStr: NSAttributedString) throws -> Data {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let wordDir = tempDir.appendingPathComponent("word")
        let relsDir = tempDir.appendingPathComponent("_rels")
        let wordRelsDir = wordDir.appendingPathComponent("_rels")

        try FileManager.default.createDirectory(at: wordRelsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)

        try contentTypesXML.write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try relsXML.write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try wordRelsXML.write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try buildDocumentXML(attrStr).write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)

        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".docx")
        try FileManager.default.zipItem(at: tempDir, to: zipURL, shouldKeepParent: false)
        let data = try Data(contentsOf: zipURL)

        try? FileManager.default.removeItem(at: tempDir)
        try? FileManager.default.removeItem(at: zipURL)
        return data
    }
}
