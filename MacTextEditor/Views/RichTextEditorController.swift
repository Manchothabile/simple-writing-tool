import AppKit
import Combine

final class RichTextEditorController: ObservableObject {
    weak var textView: NSTextView?
    @Published var hasUnsavedChanges = false

    // MARK: - Read

    func attributedString() -> NSAttributedString {
        textView?.attributedString() ?? NSAttributedString()
    }

    func selectedText() -> String? {
        guard let tv = textView else { return nil }
        let range = tv.selectedRange()
        guard range.length > 0 else { return nil }
        return (tv.string as NSString).substring(with: range)
    }

    func fullText() -> String { textView?.string ?? "" }

    // MARK: - Write

    func setAttributedString(_ attrStr: NSAttributedString) {
        textView?.textStorage?.setAttributedString(attrStr)
        hasUnsavedChanges = false
    }

    @discardableResult
    func replaceSelection(with text: String) -> NSRange {
        guard let tv = textView else { return NSRange(location: 0, length: 0) }
        let insertLocation = tv.selectedRange().location
        tv.insertText(text, replacementRange: tv.selectedRange())
        let inserted = NSRange(location: insertLocation, length: (text as NSString).length)
        highlightRange(inserted)
        return inserted
    }

    @discardableResult
    func insertAtEnd(_ text: String) -> NSRange {
        guard let tv = textView, let storage = tv.textStorage else { return NSRange(location: 0, length: 0) }
        let insertLocation = storage.length
        tv.insertText(text, replacementRange: NSRange(location: insertLocation, length: 0))
        let inserted = NSRange(location: insertLocation, length: (text as NSString).length)
        highlightRange(inserted)
        return inserted
    }

    func highlightRange(_ range: NSRange, duration: TimeInterval = 2.5) {
        guard let tv = textView, let lm = tv.layoutManager, range.length > 0 else { return }
        lm.setTemporaryAttributes(
            [.backgroundColor: NSColor.systemYellow.withAlphaComponent(0.4)],
            forCharacterRange: range
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let tv = self?.textView, let lm = tv.layoutManager else { return }
            lm.removeTemporaryAttribute(.backgroundColor, forCharacterRange: range)
        }
    }

    // MARK: - Formatting

    func toggleBold() {
        applyFontTrait(.boldFontMask)
    }

    func toggleItalic() {
        applyFontTrait(.italicFontMask)
    }

    func toggleUnderline() {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        if range.length == 0 {
            let current = tv.typingAttributes[.underlineStyle] as? Int
            if current != nil && current != 0 {
                tv.typingAttributes.removeValue(forKey: .underlineStyle)
            } else {
                tv.typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            return
        }
        let current = tv.textStorage?.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int
        if current != nil && current != 0 {
            tv.textStorage?.removeAttribute(.underlineStyle, range: range)
        } else {
            tv.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    func setAlignment(_ alignment: NSTextAlignment) {
        guard let tv = textView else { return }
        var range = tv.selectedRange()
        if range.length == 0 {
            range = (tv.string as NSString).paragraphRange(for: range)
        }
        tv.setAlignment(alignment, range: range)
    }

    func cleanupFormatting() {
        guard let storage = textView?.textStorage else { return }
        let patterns: [(String, String)] = [
            ("[ \\t]+\\n", "\n"),   // trailing whitespace before newline
            ("\\n{3,}", "\n\n"),    // 3+ consecutive newlines → 2
        ]
        for (pattern, replacement) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: storage.string, range: NSRange(location: 0, length: storage.length)).reversed()
            for match in matches {
                storage.replaceCharacters(in: match.range, with: replacement)
            }
        }
        hasUnsavedChanges = true
    }

    func markUnsaved() { hasUnsavedChanges = true }

    // MARK: - Font size

    func increaseFontSize() { adjustFontSize(by: 1) }
    func decreaseFontSize() { adjustFontSize(by: -1) }

    private func adjustFontSize(by delta: CGFloat) {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        if range.length == 0 {
            let current = (tv.typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let newFont = NSFont(descriptor: current.fontDescriptor, size: max(6, current.pointSize + delta)) ?? current
            tv.typingAttributes[.font] = newFont
            return
        }
        tv.textStorage?.enumerateAttribute(.font, in: range) { value, subRange, _ in
            guard let font = value as? NSFont else { return }
            let newFont = NSFont(descriptor: font.fontDescriptor, size: max(6, font.pointSize + delta)) ?? font
            tv.textStorage?.addAttribute(.font, value: newFont, range: subRange)
        }
    }

    // MARK: - Private

    private func applyFontTrait(_ trait: NSFontTraitMask) {
        guard let tv = textView else { return }
        let range = tv.selectedRange()

        if range.length == 0 {
            let current = (tv.typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let symbolicTrait: NSFontDescriptor.SymbolicTraits = trait == .boldFontMask ? .bold : .italic
            let hasTrait = current.fontDescriptor.symbolicTraits.contains(symbolicTrait)
            let newFont = hasTrait
                ? NSFontManager.shared.convert(current, toNotHaveTrait: trait)
                : NSFontManager.shared.convert(current, toHaveTrait: trait)
            tv.typingAttributes[.font] = newFont
            return
        }

        var hasTrait = false
        if let font = tv.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            hasTrait = font.fontDescriptor.symbolicTraits.contains(
                trait == .boldFontMask ? .bold : .italic
            )
        }

        tv.textStorage?.enumerateAttribute(.font, in: range) { value, subRange, _ in
            guard let font = value as? NSFont else { return }
            let newFont = hasTrait
                ? NSFontManager.shared.convert(font, toNotHaveTrait: trait)
                : NSFontManager.shared.convert(font, toHaveTrait: trait)
            tv.textStorage?.addAttribute(.font, value: newFont, range: subRange)
        }
    }
}
