import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(MemoryStore.self) private var memoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var ollamaURLDraft = ""
    @State private var showingResetAlert = false
    @State private var showingMemory = false
    @State private var showingAgentConfig = false
    @State private var showingPrivacy = false

    var body: some View {
        @Bindable var bindableApp = appStore
        NavigationStack {
            Form {
                ollamaSection(bindableApp: $bindableApp)
                appleIntelligenceSection
                memorySection
                agentSection
                appearanceSection(bindableApp: $bindableApp)
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
                Button("Delete All", role: .destructive) {
                    Task { await chatStore.deleteAllConversations() }
                }
            } message: {
                Text("This will permanently delete all conversations and cannot be undone.")
            }
            .sheet(isPresented: $showingMemory) {
                MemoryView()
                    .environment(memoryStore)
            }
            .sheet(isPresented: $showingAgentConfig) {
                AgentConfigView()
                    .environment(chatStore)
            }
            .sheet(isPresented: $showingPrivacy) {
                PrivacyView()
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

    private var memorySection: some View {
        Section {
            Button {
                showingMemory = true
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(memoryStore.isEnabled ? Color.accentColor : Color.secondary)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Memory")
                            .foregroundStyle(.primary)
                        Text(memoryStore.isEnabled
                             ? "\(memoryStore.activeMemories.count) active memor\(memoryStore.activeMemories.count == 1 ? "y" : "ies")"
                             : "Disabled")
                            .font(LumenType.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Label("Intelligence", systemImage: "sparkles")
        } footer: {
            Text("Lumen remembers facts and preferences across all conversations.")
        }
    }

    private var agentSection: some View {
        Section {
            Button {
                showingAgentConfig = true
            } label: {
                HStack {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(chatStore.agentModeEnabled ? Color.accentColor : Color.secondary)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Agent Mode")
                            .foregroundStyle(.primary)
                        Text(chatStore.agentModeEnabled
                             ? "Active — \(AgentToolRegistry.all.count) tools available"
                             : "Disabled")
                            .font(LumenType.caption)
                            .foregroundStyle(chatStore.agentModeEnabled ? Color.accentColor : Color.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } footer: {
            Text("When enabled, Lumen can call tools (calculator, date/time, encoders) mid-conversation.")
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
            Button {
                showingPrivacy = true
            } label: {
                Label("Privacy", systemImage: "lock.shield")
                    .foregroundStyle(.primary)
            }
            Button {
                ReviewRequestManager.shared.requestReviewNow()
            } label: {
                Label("Rate Lumen", systemImage: "star.fill")
                    .foregroundStyle(.primary)
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
        .environment(ChatStore.shared)
        .environment(MemoryStore.shared)
}
