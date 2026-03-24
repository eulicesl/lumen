import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

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
            .navigationBarTitleDisplayMode(.large)
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
            HStack(spacing: LumenSpacing.md) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy First by Design")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Lumen processes everything locally. Nothing is sent to the cloud.")
                        .font(LumenType.body)
                        .foregroundStyle(.secondary)
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
            Text("Lumen has no server, no account system, and no analytics. Your data is only ever on your device.")
        }
    }

    private var modelsSection: some View {
        Section {
            privacyRow(
                icon: "apple.intelligence",
                iconColor: .orange,
                title: "Apple Intelligence",
                detail: "Runs entirely on-device using Apple's Foundation Models framework. Requests never leave the device."
            )
            privacyRow(
                icon: "server.rack",
                iconColor: .indigo,
                title: "Ollama",
                detail: "Runs on your local network (localhost or LAN). Traffic stays within your network and is not routed to the internet."
            )
        } header: {
            Label("AI Models", systemImage: "cpu")
        } footer: {
            Text("No third-party AI APIs (OpenAI, Anthropic, etc.) are used. All inference is local.")
        }
    }

    private var permissionsSection: some View {
        Section {
            privacyRow(
                icon: "mic.fill",
                iconColor: .red,
                title: "Microphone",
                detail: "Used only during active voice input. Audio is transcribed on-device by SFSpeechRecognizer and not stored."
            )
            privacyRow(
                icon: "camera.fill",
                iconColor: .green,
                title: "Camera / Photos",
                detail: "Used only when you choose to attach an image. Images are processed locally for OCR and visual context."
            )
            privacyRow(
                icon: "magnifyingglass",
                iconColor: .teal,
                title: "Spotlight",
                detail: "Conversation titles and previews are indexed in Spotlight for quick access. Index is stored locally on this device."
            )
        } header: {
            Label("Permissions", systemImage: "checkmark.shield")
        } footer: {
            Text("All permissions are optional and only used for the stated purpose.")
        }
    }

    private var openSourceSection: some View {
        Section("Open Source") {
            Link(destination: URL(string: "https://github.com/lumen-ai/lumen")!) {
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

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(LumenType.body)
                Text(detail)
                    .font(LumenType.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, LumenSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(detail)")
    }
}

#Preview {
    PrivacyView()
}
