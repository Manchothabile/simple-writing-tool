import Foundation
import AppKit

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
            throw DocumentError.unsupportedFormat
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
}
