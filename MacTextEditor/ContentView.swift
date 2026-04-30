import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var editorController = RichTextEditorController()
    @State private var showAIPanel = false
    @State private var apiKey = KeychainHelper.load(account: KeychainHelper.apiKeyAccount) ?? ""
    @State private var isAILoading = false
    @State private var aiErrorMessage: String?
    @State private var aiHistory: [AIHistoryEntry] = []
    @State private var documentName: String = "Sans titre"
    @State private var showUnsavedAlert = false
    @State private var pendingAction: (() -> Void)?
    @AppStorage("lang") private var langRaw: String = "fr"

    private var lang: AppLanguage { AppLanguage(rawValue: langRaw) ?? .fr }
    private var s: Strings { Strings(langRaw) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                FormattingToolbar(
                    controller: editorController,
                    lang: lang,
                    onNew: confirmIfUnsaved(then: newDocument),
                    onOpen: confirmIfUnsaved(then: openDocument),
                    onSaveAs: saveAsDocument
                )
                Toggle(isOn: $showAIPanel) {
                    Image(systemName: "sparkles")
                        .help(lang == .en ? "AI assistant" : "Activer l'assistant IA")
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
                        onAction: performAIAction,
                        onCustomPrompt: performCustomPrompt,
                        history: aiHistory,
                        onRevert: revertToHistoryEntry,
                        lang: lang
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
        .alert(s.unsavedTitle, isPresented: $showUnsavedAlert) {
            Button(s.discardButton, role: .destructive) {
                pendingAction?()
                pendingAction = nil
            }
            Button(s.cancelButton, role: .cancel) { pendingAction = nil }
        } message: {
            Text(s.unsavedMessage)
        }
    }

    // MARK: - File operations

    private func newDocument() {
        editorController.setAttributedString(NSAttributedString())
        documentName = lang == .en ? "Untitled" : "Sans titre"
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
            showNSAlert(s.errorOpenFile)
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
            showNSAlert(s.errorSaveFile)
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

        let beforeState = editorController.attributedString()
        isAILoading = true
        aiErrorMessage = nil

        Task {
            defer {
                Task { @MainActor in isAILoading = false }
            }
            do {
                let result = try await AIService.perform(action, on: text, apiKey: apiKey, language: lang)
                await MainActor.run {
                    aiHistory.append(AIHistoryEntry(label: action.label(in: lang), beforeState: beforeState))
                    if action == .continuer {
                        editorController.insertAtEnd("\n" + result)
                    } else {
                        editorController.replaceSelection(with: result)
                    }
                }
            } catch AIError.invalidAPIKey {
                await MainActor.run { aiErrorMessage = s.errorInvalidKey }
            } catch AIError.networkError {
                await MainActor.run { aiErrorMessage = s.errorNetwork }
            } catch AIError.emptyResponse {
                await MainActor.run { aiErrorMessage = s.errorEmpty }
            } catch AIError.serverError(let code) {
                await MainActor.run { aiErrorMessage = s.errorServer(code) }
            } catch {
                print("[ContentView] Unexpected error: \(error)")
                await MainActor.run { aiErrorMessage = s.errorServer(-1) }
            }
        }
    }

    private func performCustomPrompt(_ prompt: String) {
        let text = editorController.selectedText() ?? editorController.fullText()
        guard !text.isEmpty else { return }

        let beforeState = editorController.attributedString()
        isAILoading = true
        aiErrorMessage = nil

        Task {
            defer {
                Task { @MainActor in isAILoading = false }
            }
            do {
                let result = try await AIService.performCustom(prompt: prompt, on: text, apiKey: apiKey, language: lang)
                await MainActor.run {
                    let label = prompt.count > 40 ? String(prompt.prefix(40)) + "…" : prompt
                    aiHistory.append(AIHistoryEntry(label: label, beforeState: beforeState))
                    editorController.replaceSelection(with: result)
                }
            } catch AIError.invalidAPIKey {
                await MainActor.run { aiErrorMessage = s.errorInvalidKey }
            } catch AIError.networkError {
                await MainActor.run { aiErrorMessage = s.errorNetwork }
            } catch AIError.emptyResponse {
                await MainActor.run { aiErrorMessage = s.errorEmpty }
            } catch AIError.serverError(let code) {
                await MainActor.run { aiErrorMessage = s.errorServer(code) }
            } catch {
                print("[ContentView] Custom prompt error: \(error)")
                await MainActor.run { aiErrorMessage = s.errorServer(-1) }
            }
        }
    }

    private func revertToHistoryEntry(_ entry: AIHistoryEntry) {
        editorController.setAttributedString(entry.beforeState)
        if let idx = aiHistory.firstIndex(where: { $0.id == entry.id }) {
            aiHistory.removeSubrange(idx...)
        }
    }

    private func showNSAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
