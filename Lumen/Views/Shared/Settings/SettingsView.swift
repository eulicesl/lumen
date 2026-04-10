import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(MemoryStore.self) private var memoryStore
    @Environment(\.dismiss) private var dismiss

    @State private var ollamaLocalURLDraft = ""
    @State private var ollamaLocalTokenDraft = ""
    @State private var ollamaCloudTokenDraft = ""
    @State private var showingResetAlert = false
    @State private var showingMemory = false
    @State private var showingAgentConfig = false
    @State private var showingPrivacy = false
    @State private var isRefreshingOllamaLocal = false
    @State private var isRefreshingOllamaCloud = false

    var body: some View {
        @Bindable var bindableApp = appStore

        NavigationStack {
            Form {
                activeModelSection
                ollamaLocalSection
                ollamaCloudSection
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
                    Button("Done") {
                        persistProviderDraftsIfNeeded()
                        dismiss()
                    }
                    .accessibilityHint("Saves settings changes and closes this screen")
                }
            }
            .onAppear {
                ollamaLocalURLDraft = appStore.ollamaLocalServerURL
                ollamaLocalTokenDraft = appStore.ollamaLocalBearerToken
                ollamaCloudTokenDraft = appStore.ollamaCloudAPIKey
            }
            .onDisappear {
                persistProviderDraftsIfNeeded()
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

    private var activeModelSection: some View {
        Section {
            HStack(spacing: LumenSpacing.sm) {
                ProviderMark(
                    provider: selectedProviderType,
                    size: 18,
                    showsVariantBadge: selectedProviderType != .foundationModels
                )
                .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedProviderTitle)
                        .foregroundStyle(.primary)
                    if let subtitle = selectedModelSubtitle {
                        Text(subtitle)
                            .font(LumenType.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Active model")
            .accessibilityValue(activeModelAccessibilityValue)
        } header: {
            Label("Active Model", systemImage: LumenIcon.model)
        }
    }

    private var ollamaLocalSection: some View {
        Section {
            Toggle(isOn: allowOllamaLocalBinding) {
                providerToggleLabel(
                    provider: .ollamaLocal,
                    title: "Ollama Local",
                    subtitle: "Use a local or self-hosted Ollama server"
                )
            }
            .accessibilityHint("Turns local Ollama model access on or off")

            HStack {
                ProviderMark(provider: .ollamaLocal, size: 18, showsVariantBadge: true)
                    .frame(width: 24)

                TextField("http://localhost:11434", text: $ollamaLocalURLDraft)
                    .accessibilityLabel("Ollama local endpoint")
                    .accessibilityHint("Enter the base URL for your local Ollama server")
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    #endif
                    .onSubmit {
                        Task { await refreshOllamaLocalModels() }
                    }
            }
            .disabled(!appStore.allowOllamaLocal)

            HStack {
                Image(systemName: "key")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                SecureField("Optional bearer token", text: $ollamaLocalTokenDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Ollama local bearer token")
                    .accessibilityHint("Optional authentication for a protected local Ollama endpoint")
            }
            .disabled(!appStore.allowOllamaLocal)

            providerStatusRow(
                label: "Ollama Local status",
                status: modelStore.ollamaLocalConnectionStatus,
                detail: modelStore.ollamaLocalStatusMessage,
                color: localStatusColor,
                iconName: localStatusIconName
            )

            Button {
                Task { await refreshOllamaLocalModels() }
            } label: {
                refreshRow(
                    title: "Refresh Local Models",
                    isRefreshing: modelStore.isLoading || isRefreshingOllamaLocal
                )
            }
            .foregroundStyle(.primary)
            .disabled(!appStore.allowOllamaLocal)
            .accessibilityHint("Refreshes the model list from your local Ollama endpoint")
        } header: {
            providerSectionHeader("Ollama Local", provider: .ollamaLocal)
        } footer: {
            Text("Traffic stays on hardware you control. Default: http://localhost:11434.")
        }
    }

    private var ollamaCloudSection: some View {
        Section {
            Toggle(isOn: allowOllamaCloudBinding) {
                providerToggleLabel(
                    provider: .ollamaCloud,
                    title: "Ollama Cloud",
                    subtitle: "Use hosted models from Ollama"
                )
            }
            .accessibilityHint("Turns Ollama Cloud model access on or off")

            LabeledContent("Endpoint", value: "https://ollama.com/api")

            HStack {
                Image(systemName: "key")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                SecureField("Ollama Cloud API key", text: $ollamaCloudTokenDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Ollama Cloud API key")
                    .accessibilityHint("Required to load and use hosted models from Ollama Cloud")
            }
            .disabled(!appStore.allowOllamaCloud)

            providerStatusRow(
                label: "Ollama Cloud status",
                status: modelStore.ollamaCloudConnectionStatus,
                detail: modelStore.ollamaCloudStatusMessage,
                color: cloudStatusColor,
                iconName: cloudStatusIconName
            )

            Button {
                Task { await refreshOllamaCloudModels() }
            } label: {
                refreshRow(
                    title: "Refresh Cloud Models",
                    isRefreshing: modelStore.isLoading || isRefreshingOllamaCloud
                )
            }
            .foregroundStyle(.primary)
            .disabled(!appStore.allowOllamaCloud)
            .accessibilityHint("Refreshes the hosted model list from Ollama Cloud")
        } header: {
            providerSectionHeader("Ollama Cloud", provider: .ollamaCloud)
        } footer: {
            Text("When enabled, prompts are sent to Ollama's hosted service. Requires an API key.")
        }
    }

    private var appleIntelligenceSection: some View {
        Section {
            HStack {
                ProviderMark(provider: .foundationModels, size: 18)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Intelligence")
                    Text(modelStore.appleIntelligenceAvailable
                        ? "Available on this device"
                        : "Requires supported hardware and iOS 26")
                        .font(LumenType.caption)
                        .foregroundStyle(modelStore.appleIntelligenceAvailable ? .green : .secondary)
                }

                Spacer()

                Image(systemName: modelStore.appleIntelligenceAvailable ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(modelStore.appleIntelligenceAvailable ? .green : .secondary)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Apple Intelligence")
        .accessibilityValue(modelStore.appleIntelligenceAvailable ? "Available on this device" : "Not available on this device")
        .accessibilityHint("Shows whether Apple Intelligence is available for on-device models")
        } header: {
            providerSectionHeader("Apple Intelligence", provider: .foundationModels)
        } footer: {
            Text("Runs entirely on-device. Requests stay on your iPhone.")
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
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Memory")
            .accessibilityValue(memoryAccessibilityValue)
            .accessibilityHint("Opens memory settings")
        } header: {
            Label("Intelligence", systemImage: "sparkles")
        } footer: {
            Text("Save important facts and preferences for future conversations.")
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
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Agent Mode")
            .accessibilityValue(agentModeAccessibilityValue)
            .accessibilityHint("Opens agent mode settings")
        } footer: {
            Text("Allow Lumen to use built-in tools during a conversation.")
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
            .accessibilityLabel("Appearance")
            .accessibilityHint("Choose system, light, or dark appearance")
        } header: {
            Label("Appearance", systemImage: "paintbrush")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.appVersion)
            LabeledContent("Build", value: Bundle.main.buildNumber)

            Link(destination: URL(string: "https://github.com/eulicesl/lumen")!) {
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
                Label("Rate App", systemImage: "star.fill")
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

private extension SettingsView {
    func providerToggleLabel(provider: AIProviderType, title: String, subtitle: String) -> some View {
        HStack(spacing: LumenSpacing.sm) {
            ProviderMark(
                provider: provider,
                size: 18,
                showsVariantBadge: provider != .foundationModels
            )
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(LumenType.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    func providerSectionHeader(_ title: String, provider: AIProviderType) -> some View {
        HStack(spacing: LumenSpacing.xs) {
            ProviderMark(
                provider: provider,
                size: 14,
                showsVariantBadge: provider != .foundationModels
            )
            Text(title)
        }
    }

    func refreshRow(title: String, isRefreshing: Bool) -> some View {
        HStack {
            Image(systemName: "arrow.clockwise")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
            Spacer()
            if isRefreshing {
                ProgressView()
            }
        }
    }

    func providerStatusRow(
        label: String,
        status: ProviderConnectionStatus,
        detail: String?,
        color: Color,
        iconName: String
    ) -> some View {
        HStack(alignment: .top, spacing: LumenSpacing.sm) {
            Image(systemName: iconName)
                .foregroundStyle(color)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Status")
                    .font(LumenType.body)
                Text(status.title)
                    .font(LumenType.caption)
                    .foregroundStyle(color)
                if let detail {
                    Text(detail)
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(status.title)
        .accessibilityHint(detail ?? "Shows the current provider connection status")
    }

    func persistProviderDraftsIfNeeded() {
        persistOllamaLocalURLIfNeeded()

        if ollamaLocalTokenDraft != appStore.ollamaLocalBearerToken {
            appStore.saveOllamaLocalBearerToken(ollamaLocalTokenDraft)
            ollamaLocalTokenDraft = appStore.ollamaLocalBearerToken
        }

        if ollamaCloudTokenDraft != appStore.ollamaCloudAPIKey {
            appStore.saveOllamaCloudAPIKey(ollamaCloudTokenDraft)
            ollamaCloudTokenDraft = appStore.ollamaCloudAPIKey
        }
    }

    func persistOllamaLocalURLIfNeeded() {
        let normalized = ollamaLocalURLDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetURL = normalized.isEmpty ? "http://localhost:11434" : normalized
        guard targetURL != appStore.ollamaLocalServerURL else { return }
        appStore.saveOllamaLocalURL(targetURL)
        ollamaLocalURLDraft = appStore.ollamaLocalServerURL
    }

    func refreshOllamaLocalModels() async {
        isRefreshingOllamaLocal = true
        persistProviderDraftsIfNeeded()
        await modelStore.loadModels()
        isRefreshingOllamaLocal = false
    }

    func refreshOllamaCloudModels() async {
        isRefreshingOllamaCloud = true
        persistProviderDraftsIfNeeded()
        await modelStore.loadModels()
        isRefreshingOllamaCloud = false
    }

    var allowOllamaLocalBinding: Binding<Bool> {
        Binding(
            get: { appStore.allowOllamaLocal },
            set: { enabled in
                persistProviderDraftsIfNeeded()
                appStore.saveAllowOllamaLocal(enabled)
                Task { await modelStore.loadModels() }
            }
        )
    }

    var allowOllamaCloudBinding: Binding<Bool> {
        Binding(
            get: { appStore.allowOllamaCloud },
            set: { enabled in
                persistProviderDraftsIfNeeded()
                appStore.saveAllowOllamaCloud(enabled)
                Task { await modelStore.loadModels() }
            }
        )
    }

    var localStatusColor: Color {
        switch modelStore.ollamaLocalConnectionStatus {
        case .available:
            return .green
        case .checking, .disabled:
            return .secondary
        case .missingCredentials, .unavailable:
            return .orange
        }
    }

    var localStatusIconName: String {
        switch modelStore.ollamaLocalConnectionStatus {
        case .available:
            return "checkmark.circle.fill"
        case .checking:
            return "arrow.trianglehead.clockwise"
        case .disabled:
            return "pause.circle"
        case .missingCredentials:
            return "key.slash"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    var cloudStatusColor: Color {
        switch modelStore.ollamaCloudConnectionStatus {
        case .available:
            return .green
        case .checking, .disabled:
            return .secondary
        case .missingCredentials, .unavailable:
            return .orange
        }
    }

    var cloudStatusIconName: String {
        switch modelStore.ollamaCloudConnectionStatus {
        case .available:
            return "checkmark.circle.fill"
        case .checking:
            return "arrow.trianglehead.clockwise"
        case .disabled:
            return "pause.circle"
        case .missingCredentials:
            return "key.slash"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    var memoryAccessibilityValue: String {
        guard memoryStore.isEnabled else { return "Disabled" }
        let count = memoryStore.activeMemories.count
        return "\(count) active memor\(count == 1 ? "y" : "ies")"
    }

    var agentModeAccessibilityValue: String {
        guard chatStore.agentModeEnabled else { return "Disabled" }
        let toolCount = AgentToolRegistry.all.count
        return "Active with \(toolCount) tool\(toolCount == 1 ? "" : "s") available"
    }

    var selectedModelTitle: String {
        chatStore.currentModel?.displayName ?? "Not selected"
    }

    var selectedProviderTitle: String {
        chatStore.currentModel?.providerType.displayName ?? "None"
    }

    var selectedProviderType: AIProviderType {
        chatStore.currentModel?.providerType ?? .foundationModels
    }

    var selectedModelSubtitle: String? {
        guard let model = chatStore.currentModel else { return nil }
        return model.displayName == model.providerType.displayName ? nil : model.displayName
    }

    var activeModelAccessibilityValue: String {
        if let subtitle = selectedModelSubtitle {
            return "\(selectedProviderTitle). \(subtitle)"
        }
        return selectedProviderTitle
    }
}

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
