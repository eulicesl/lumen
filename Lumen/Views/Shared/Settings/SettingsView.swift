import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(\.dismiss) private var dismiss
    @State private var ollamaURLDraft = ""
    @State private var showingResetAlert = false

    var body: some View {
        @Bindable var bindableApp = appStore
        NavigationStack {
            Form {
                ollamaSection(bindableApp: bindableApp)
                appleIntelligenceSection
                appearanceSection(bindableApp: bindableApp)
                aboutSection
                dangerSection
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                ollamaURLDraft = appStore.ollamaServerURL
            }
            .alert("Reset Conversations", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset All", role: .destructive) {}
            } message: {
                Text("This will permanently delete all conversations. This action cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private func ollamaSection(bindableApp: Bindable<AppStore>) -> some View {
        Section {
            HStack {
                Image(systemName: LumenIcon.ollama)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                TextField("http://localhost:11434", text: bindableApp.ollamaServerURL)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    #endif
                    .onSubmit { Task { await modelStore.loadModels() } }
            }
            Button {
                Task { await modelStore.loadModels() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text("Refresh Models")
                    Spacer()
                    if modelStore.isLoading {
                        ProgressView()
                    } else {
                        Text("\(modelStore.ollamaModelCount) available")
                            .font(LumenType.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Label("Ollama Server", systemImage: LumenIcon.ollama)
        } footer: {
            Text("Ollama must be running on your local network. Default is http://localhost:11434")
        }
    }

    private var appleIntelligenceSection: some View {
        Section {
            HStack {
                Image(systemName: LumenIcon.appleIntelligence)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Intelligence")
                    Text(modelStore.appleIntelligenceAvailable
                         ? "Available on this device"
                         : "Not available — requires iPhone 15 Pro or later with iOS 26")
                        .font(LumenType.caption)
                        .foregroundStyle(modelStore.appleIntelligenceAvailable ? .green : .secondary)
                }
                Spacer()
                Image(systemName: modelStore.appleIntelligenceAvailable ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(modelStore.appleIntelligenceAvailable ? .green : .secondary)
            }
        } header: {
            Label("Apple Intelligence", systemImage: LumenIcon.appleIntelligence)
        } footer: {
            Text("Runs entirely on-device. No data leaves your iPhone.")
        }
    }

    private func appearanceSection(bindableApp: Bindable<AppStore>) -> some View {
        Section {
            Picker("Appearance", selection: bindableApp.colorSchemePreference) {
                Text("System").tag(AppColorScheme.system)
                Text("Light").tag(AppColorScheme.light)
                Text("Dark").tag(AppColorScheme.dark)
            }
            .pickerStyle(.segmented)
        } header: {
            Label("Appearance", systemImage: "paintbrush")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.appVersion)
            LabeledContent("Build", value: Bundle.main.buildNumber)
            Link(destination: URL(string: "https://github.com/lumen-ai/lumen")!) {
                Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
    }

    private var dangerSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                Label("Delete All Conversations", systemImage: LumenIcon.trash)
            }
        }
    }
}

// MARK: - Bundle helpers

private extension Bundle {
    var appVersion: String { infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    var buildNumber: String { infoDictionary?["CFBundleVersion"] as? String ?? "1" }
}

#Preview {
    SettingsView()
        .environment(AppStore.shared)
        .environment(ModelStore.shared)
}
