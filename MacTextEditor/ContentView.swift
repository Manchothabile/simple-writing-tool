import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var editorController = RichTextEditorController()
    @State private var showAIPanel = false
    @State private var apiKey = KeychainHelper.load(account: KeychainHelper.apiKeyAccount) ?? ""
    @State private var isAILoading = false
    @State private var aiErrorMessage: String?
    @State private var documentName: String = "Sans titre"
    @State private var showUnsavedAlert = false
    @State private var pendingAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                FormattingToolbar(
                    controller: editorController,
                    onNew: confirmIfUnsaved(then: newDocument),
                    onOpen: confirmIfUnsaved(then: openDocument),
                    onSaveAs: saveAsDocument
                )
                Toggle(isOn: $showAIPanel) {
                    Image(systemName: "sparkles")
                        .help("Activer l'assistant IA")
                }
                .toggleStyle(.button)
                .padding(.trailing, 12)
            }
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            HStack(spacing: 0) {
                ZStack {
                    Color(NSColor.underPageBackgroundColor)
                    RichTextEditor(controller: editorController)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                }

                if showAIPanel {
                    Divider()
                    AIPanel(
                        apiKey: $apiKey,
                        isLoading: $isAILoading,
                        errorMessage: aiErrorMessage,
                        onAction: performAIAction
                    )
                    .task(id: apiKey) {
                        if apiKey.isEmpty {
                            KeychainHelper.delete(account: KeychainHelper.apiKeyAccount)
                        } else {
                            KeychainHelper.save(apiKey, account: KeychainHelper.apiKeyAccount)
                        }
                    }
                }
            }
        }
        .navigationTitle(documentName + (editorController.hasUnsavedChanges ? " ●" : ""))
        .alert("Document non sauvegardé", isPresented: $showUnsavedAlert) {
            Button("Abandonner les modifications", role: .destructive) {
                pendingAction?()
                pendingAction = nil
            }
            Button("Annuler", role: .cancel) { pendingAction = nil }
        } message: {
            Text("Les modifications non sauvegardées seront perdues.")
        }
    }

    // MARK: - File operations

    private func newDocument() {
        editorController.setAttributedString(NSAttributedString())
        documentName = "Sans titre"
    }

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = DocumentFormat.allCases.compactMap { UTType($0.utType) }
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let ext = url.pathExtension.lowercased()
        guard let format = DocumentFormat(rawValue: ext),
              let data = try? Data(contentsOf: url),
              let attrStr = try? DocumentManager.importFile(data: data, format: format) else {
            showNSAlert("Impossible d'ouvrir ce fichier.")
            return
        }
        editorController.setAttributedString(attrStr)
        documentName = url.deletingPathExtension().lastPathComponent
    }

    private func saveAsDocument() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = documentName
        panel.allowedContentTypes = DocumentFormat.allCases.compactMap { UTType($0.utType) }
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let ext = url.pathExtension.lowercased()
        guard let format = DocumentFormat(rawValue: ext),
              let data = try? DocumentManager.export(editorController.attributedString(), as: format) else {
            showNSAlert("Impossible d'enregistrer le fichier.")
            return
        }
        try? data.write(to: url)
        documentName = url.deletingPathExtension().lastPathComponent
        editorController.hasUnsavedChanges = false
    }

    private func confirmIfUnsaved(then action: @escaping () -> Void) -> () -> Void {
        return {
            if editorController.hasUnsavedChanges {
                pendingAction = action
                showUnsavedAlert = true
            } else {
                action()
            }
        }
    }

    // MARK: - AI

    private func performAIAction(_ action: AIAction) {
        let text = editorController.selectedText() ?? editorController.fullText()
        guard !text.isEmpty else { return }

        isAILoading = true
        aiErrorMessage = nil

        Task {
            defer {
                Task { @MainActor in isAILoading = false }
            }
            do {
                let result = try await AIService.perform(action, on: text, apiKey: apiKey)
                await MainActor.run {
                    if action == .continuer {
                        editorController.insertAtEnd("\n" + result)
                    } else {
                        editorController.replaceSelection(with: result)
                    }
                }
            } catch AIError.invalidAPIKey {
                await MainActor.run { aiErrorMessage = "Clé API invalide." }
            } catch AIError.networkError {
                await MainActor.run { aiErrorMessage = "Erreur réseau. Vérifiez votre connexion." }
            } catch {
                await MainActor.run { aiErrorMessage = "Erreur inattendue." }
            }
        }
    }

    private func showNSAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
