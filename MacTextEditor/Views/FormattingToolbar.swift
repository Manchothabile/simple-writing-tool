import SwiftUI
import AppKit

private struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.14 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.07), value: configuration.isPressed)
    }
}

struct FormattingToolbar: View {
    @ObservedObject var controller: RichTextEditorController
    var lang: AppLanguage
    var onNew: () -> Void
    var onOpen: () -> Void
    var onSaveAs: () -> Void

    @AppStorage("lang") private var langRaw: String = "fr"

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: controller.toggleBold) {
                Image(systemName: "bold").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Bold" : "Gras")

            Button(action: controller.toggleItalic) {
                Image(systemName: "italic").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Italic" : "Italique")

            Button(action: controller.toggleUnderline) {
                Image(systemName: "underline").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Underline" : "Souligné")

            Divider().frame(height: 20)

            Button(action: { NSFontManager.shared.orderFrontFontPanel(nil) }) {
                Image(systemName: "textformat").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Font" : "Police")

            Button(action: controller.decreaseFontSize) {
                Image(systemName: "textformat.size.smaller").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Decrease size" : "Réduire la taille")

            Button(action: controller.increaseFontSize) {
                Image(systemName: "textformat.size.larger").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Increase size" : "Augmenter la taille")

            Button(action: { NSColorPanel.shared.orderFront(nil) }) {
                Image(systemName: "paintbrush").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Text color" : "Couleur du texte")

            Divider().frame(height: 20)

            Button(action: { controller.setAlignment(.left) }) {
                Image(systemName: "text.alignleft").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Align left" : "Aligner à gauche")

            Button(action: { controller.setAlignment(.center) }) {
                Image(systemName: "text.aligncenter").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Center" : "Centrer")

            Button(action: { controller.setAlignment(.right) }) {
                Image(systemName: "text.alignright").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Align right" : "Aligner à droite")

            Divider().frame(height: 20)

            Button(action: controller.cleanupFormatting) {
                Image(systemName: "paragraphsign").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Clean up formatting" : "Nettoyer la mise en forme")

            Divider().frame(height: 20)

            Button(action: onNew) {
                Image(systemName: "doc").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "New" : "Nouveau")

            Button(action: onOpen) {
                Image(systemName: "folder").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Open" : "Ouvrir")

            Button(action: onSaveAs) {
                Image(systemName: "square.and.arrow.down").frame(width: 24, height: 24)
            }
            .help(lang == .en ? "Save as…" : "Enregistrer sous…")

            Spacer()

            if !version.isEmpty {
                Text("v\(version)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.trailing, 6)
            }

            Button(action: { langRaw = lang == .en ? "fr" : "en" }) {
                Text(lang == .en ? "FR" : "EN")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 28, height: 20)
            }
            .buttonStyle(ToolbarButtonStyle())
            .padding(.horizontal, 4)
            .background(Color.primary.opacity(0.07))
            .cornerRadius(5)
            .help(lang == .en ? "Switch to French" : "Passer en anglais")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .buttonStyle(ToolbarButtonStyle())
    }
}
