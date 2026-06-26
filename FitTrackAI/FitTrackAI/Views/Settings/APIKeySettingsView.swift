import SwiftUI

struct APIKeySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var errorMessage: String?
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Required for photo analysis using \(LLMConfig.bodyFatModel). Your key is stored in the device Keychain.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                if saved {
                    Section {
                        Label("API key saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("API Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveKey() }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let existing = OpenAIConfig.apiKey {
                    apiKey = existing
                }
            }
        }
    }

    private func saveKey() {
        do {
            try OpenAIConfig.saveAPIKey(apiKey)
            saved = true
            errorMessage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    APIKeySettingsView()
}
