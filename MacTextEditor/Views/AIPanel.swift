import SwiftUI

struct AIPanel: View {
    @Binding var apiKey: String
    @Binding var isLoading: Bool
    var errorMessage: String?
    var onAction: (AIAction) -> Void
    var onCustomPrompt: (String) -> Void

    @State private var customPrompt = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IA · Haiku 4.5")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            SecureField("Clé API Anthropic", text: $apiKey)
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
                    Text(action.label)
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

            Text("Demande libre")
                .font(.caption2)
                .foregroundColor(.secondary)

            TextField("Ex: traduis en anglais…", text: $customPrompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .lineLimit(3...6)
                .disabled(isLoading || apiKey.isEmpty)
                .onSubmit { sendCustomPrompt() }

            Button(action: sendCustomPrompt) {
                Text("Envoyer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isLoading || apiKey.isEmpty || customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if isLoading {
                HStack {
                    ProgressView().scaleEffect(0.7)
                    Text("En cours…").font(.caption2).foregroundColor(.secondary)
                }
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
