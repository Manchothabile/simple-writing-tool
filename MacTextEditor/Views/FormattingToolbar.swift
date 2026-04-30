import SwiftUI
import AppKit

struct FormattingToolbar: View {
    @ObservedObject var controller: RichTextEditorController
    var onNew: () -> Void
    var onOpen: () -> Void
    var onSaveAs: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: controller.toggleBold) {
                Image(systemName: "bold").frame(width: 24, height: 24)
            }
            .help("Gras")

            Button(action: controller.toggleItalic) {
                Image(systemName: "italic").frame(width: 24, height: 24)
            }
            .help("Italique")

            Button(action: controller.toggleUnderline) {
                Image(systemName: "underline").frame(width: 24, height: 24)
            }
            .help("Souligné")

            Divider().frame(height: 20)

            Button(action: { NSFontManager.shared.orderFrontFontPanel(nil) }) {
                Image(systemName: "textformat").frame(width: 24, height: 24)
            }
            .help("Police")

            Button(action: controller.decreaseFontSize) {
                Image(systemName: "textformat.size.smaller").frame(width: 24, height: 24)
            }
            .help("Réduire la taille")

            Button(action: controller.increaseFontSize) {
                Image(systemName: "textformat.size.larger").frame(width: 24, height: 24)
            }
            .help("Augmenter la taille")

            Button(action: { NSColorPanel.shared.orderFront(nil) }) {
                Image(systemName: "paintbrush").frame(width: 24, height: 24)
            }
            .help("Couleur du texte")

            Divider().frame(height: 20)

            Button(action: { controller.setAlignment(.left) }) {
                Image(systemName: "text.alignleft").frame(width: 24, height: 24)
            }
            .help("Aligner à gauche")

            Button(action: { controller.setAlignment(.center) }) {
                Image(systemName: "text.aligncenter").frame(width: 24, height: 24)
            }
            .help("Centrer")

            Button(action: { controller.setAlignment(.right) }) {
                Image(systemName: "text.alignright").frame(width: 24, height: 24)
            }
            .help("Aligner à droite")

            Divider().frame(height: 20)

            Button(action: controller.cleanupFormatting) {
                Image(systemName: "paragraphsign").frame(width: 24, height: 24)
            }
            .help("Nettoyer la mise en forme")

            Divider().frame(height: 20)

            Button(action: onNew) {
                Image(systemName: "doc").frame(width: 24, height: 24)
            }
            .help("Nouveau")

            Button(action: onOpen) {
                Image(systemName: "folder").frame(width: 24, height: 24)
            }
            .help("Ouvrir")

            Button(action: onSaveAs) {
                Image(systemName: "square.and.arrow.down").frame(width: 24, height: 24)
            }
            .help("Enregistrer sous…")

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .buttonStyle(.plain)
    }
}
