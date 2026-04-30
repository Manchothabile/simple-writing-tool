import SwiftUI
import AppKit

struct RichTextEditor: NSViewRepresentable {
    @ObservedObject var controller: RichTextEditorController

    func makeCoordinator() -> Coordinator { Coordinator(controller) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont(name: "Georgia", size: 16)
        textView.textContainerInset = NSSize(width: 60, height: 40)
        textView.backgroundColor = .white
        textView.isAutomaticSpellingCorrectionEnabled = false

        controller.textView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {}

    final class Coordinator: NSObject, NSTextViewDelegate {
        let controller: RichTextEditorController
        init(_ c: RichTextEditorController) { controller = c }

        func textDidChange(_ notification: Notification) {
            controller.markUnsaved()
        }
    }
}
