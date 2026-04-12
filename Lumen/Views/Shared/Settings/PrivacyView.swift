import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            List {
                heroSection
                dataStorageSection
                modelsSection
                permissionsSection
                openSourceSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        Section {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: LumenSpacing.md) {
                        heroIcon
                        heroCopy
                    }
                } else {
                    HStack(spacing: LumenSpacing.md) {
                        heroIcon
                        heroCopy
                    }
                }
            }
            .padding(.vertical, LumenSpacing.sm)
            .accessibilityElement(children: .combine)
        }
    }

    private var dataStorageSection: some View {
        Section {
            privacyRow(
                icon: "internaldrive",
                iconColor: .blue,
                title: "Conversations",
                detail: "Stored only on this device using SwiftData. Never transmitted anywhere."
            )
            privacyRow(
                icon: "brain.head.profile",
                iconColor: .purple,
                title: "Memory",
                detail: "User memories are saved to UserDefaults on this device only."
            )
            privacyRow(
                icon: "gear",
                iconColor: .gray,
                title: "Preferences",
                detail: "App settings saved locally to UserDefaults."
            )
        } header: {
            Label("Your Data", systemImage: "cylinder.fill")
        } footer: {
            Text("This app has no account system or analytics. Your data stays on device unless you enable a network-backed model provider.")
        }
    }

    private var modelsSection: some View {
        Section {
            privacyRow(
                icon: "apple.intelligence",
                iconColor: .orange,
                title: "Apple Intelligence",
                detail: "Runs on device using Foundation Models. Requests stay on device."
            )
            privacyRow(
                icon: "server.rack",
                iconColor: .indigo,
                title: "Ollama Local",
                detail: "Runs on your local network or self-hosted hardware. Traffic stays within infrastructure you control."
            )
            privacyRow(
                icon: "cloud.fill",
                iconColor: .blue,
                title: "Ollama Cloud",
                detail: "Optional hosted provider. When enabled, prompts are sent to Ollama using your API key."
            )
        } header: {
            Label("AI Models", systemImage: "cpu")
        } footer: {
            Text("On-device and hosted providers are optional and under your control.")
        }
    }

    private var permissionsSection: some View {
        Section {
            privacyRow(
                icon: "mic.fill",
                iconColor: .red,
                title: "Microphone",
                detail: "Used only during voice input. Audio is transcribed on device and not stored."
            )
            privacyRow(
                icon: "camera.fill",
                iconColor: .green,
                title: "Camera / Photos / Files",
                detail: "Used only when you attach images or import documents. OCR and text extraction happen on device."
            )
            privacyRow(
                icon: "magnifyingglass",
                iconColor: .teal,
                title: "Spotlight",
                detail: "Conversation titles and previews can be indexed in Spotlight for quick access on this device."
            )
        } header: {
            Label("Permissions", systemImage: "checkmark.shield")
        } footer: {
            Text("All permissions are optional and only used for the stated purpose.")
        }
    }

    private var openSourceSection: some View {
        Section("Open Source") {
            Link(destination: URL(string: "https://github.com/eulicesl/lumen")!) {
                HStack {
                    Label("View Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Row

    private func privacyRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: LumenSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(LumenType.body)
                Text(detail)
                    .font(LumenType.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, LumenSpacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
    }

    private var heroIcon: some View {
        Image(systemName: "lock.shield.fill")
            .font(.largeTitle)
            .foregroundStyle(.green)
            .accessibilityHidden(true)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Privacy by Default")
                .font(.title3.weight(.semibold))
            Text("Your data stays on device unless you choose to use a network-backed model provider.")
                .font(LumenType.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PrivacyView()
}
