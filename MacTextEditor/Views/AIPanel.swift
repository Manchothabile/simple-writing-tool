import SwiftUI

struct AIHistoryEntry: Identifiable {
    let id = UUID()
    let label: String
    let beforeState: NSAttributedString
}

struct AIPanel: View {
    @Binding var apiKey: String
    @Binding var isLoading: Bool
    var errorMessage: String?
    var onAction: (AIAction) -> Void
    var onCustomPrompt: (String) -> Void
    var history: [AIHistoryEntry]
    var onRevert: (AIHistoryEntry) -> Void
    var lang: AppLanguage

    @State private var customPrompt = ""

    private var s: Strings { Strings(lang.rawValue) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IA · Haiku 4.5")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            SecureField(s.apiKeyPlaceholder, text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            if let error = errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            ForEach(AIAction.allCases, id: \.self) { action in
                Button(action: { onAction(action) }) {
                    Text(action.label(in: lang))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
                .disabled(isLoading || apiKey.isEmpty)
            }

            Divider()

            Text(s.freePromptLabel)
                .font(.caption2)
                .foregroundColor(.secondary)

            TextField(s.freePromptPlaceholder, text: $customPrompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .lineLimit(3...6)
                .disabled(isLoading || apiKey.isEmpty)
                .onSubmit { sendCustomPrompt() }

            Button(action: sendCustomPrompt) {
                Text(s.sendButton)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isLoading || apiKey.isEmpty || customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if isLoading {
                HStack {
                    ProgressView().scaleEffect(0.7)
                    Text(s.loadingLabel).font(.caption2).foregroundColor(.secondary)
                }
            }

            if !history.isEmpty {
                Divider()

                Text(s.historyLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(history.reversed()) { entry in
                            Button(action: { onRevert(entry) }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.caption2)
                                    Text(entry.label)
                                        .font(.caption2)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 6)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 140)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(width: 220)
    }

    private func sendCustomPrompt() {
        let trimmed = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onCustomPrompt(trimmed)
        customPrompt = ""
    }
}
