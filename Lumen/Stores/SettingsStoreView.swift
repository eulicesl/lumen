import SwiftUI
import Observation

struct SettingsStoreView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var showsDoneButton: Bool = false

    private var allowOllamaBinding: Binding<Bool> {
        Binding(
            get: { store.allowOllama },
            set: { store.saveAllowOllama($0) }
        )
    }

    private var ollamaURLBinding: Binding<String> {
        Binding(
            get: { store.ollamaServerURL },
            set: { store.saveOllamaURL($0) }
        )
    }

    private var ollamaBearerTokenBinding: Binding<String> {
        Binding(
            get: { store.ollamaBearerToken },
            set: { store.saveOllamaBearerToken($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Apple Intelligence") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apple Intelligence is a built-in feature that provides enhanced privacy and performance benefits.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Text("Available on all supported devices.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Ollama") {
                    Group {
                        Toggle("Allow Ollama", isOn: allowOllamaBinding)

                        TextField("Ollama Server URL", text: ollamaURLBinding)
                            .ollamaTextFieldTraits()

                        SecureField("Bearer Token", text: ollamaBearerTokenBinding)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func settingsGlassCard() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func ollamaTextFieldTraits() -> some View {
        #if os(iOS)
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            .textContentType(.URL)
        #else
        self
        #endif
    }
}
