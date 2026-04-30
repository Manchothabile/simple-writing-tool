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
        guard range.length > 0 else { return }
        let current = tv.textStorage?.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int
        if current != nil && current != 0 {
            tv.textStorage?.removeAttribute(.underlineStyle, range: range)
        } else {
            tv.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    func setAlignment(_ alignment: NSTextAlignment) {
        guard let tv = textView else { return }
        tv.setAlignment(alignment, range: tv.selectedRange())
    }

    func markUnsaved() { hasUnsavedChanges = true }

    // MARK: - Font size

    func increaseFontSize() { adjustFontSize(by: 1) }
    func decreaseFontSize() { adjustFontSize(by: -1) }

    private func adjustFontSize(by delta: CGFloat) {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        guard range.length > 0 else { return }
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
        guard range.length > 0 else { return }

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
