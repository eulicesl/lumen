// LumenWidget target only — do NOT add to the main Lumen target.
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Recent Conversations widget (medium + large)
// Shows the 1–3 most recent conversation titles.
// Tapping an entry opens that conversation in the main app via URL deeplink.

struct RecentConversationWidget: Widget {
    let kind = "RecentConversationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentConversationProvider()) { entry in
            RecentConversationWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Conversations")
        .description("See your recent Lumen conversations at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Entry

struct RecentConversationEntry: TimelineEntry {
    let date: Date
    let conversations: [WidgetConversation]
}

struct WidgetConversation: Identifiable, Codable {
    let id: String
    let title: String
    let preview: String
    let updatedAt: Date
}

// MARK: - Shared store (reads from App Group UserDefaults)

enum WidgetSharedStore {
    private static let suiteName = "group.ai.lumen"
    private static let key = "widget.recentConversations"

    static var recentConversationTitle: String? {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key),
              let conversations = try? JSONDecoder().decode([WidgetConversation].self, from: data) else {
            return nil
        }
        return conversations.first?.title
    }

    static var recentConversations: [WidgetConversation] {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key),
              let conversations = try? JSONDecoder().decode([WidgetConversation].self, from: data) else {
            return []
        }
        return Array(conversations.prefix(5))
    }

    static func save(_ conversations: [WidgetConversation]) {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        UserDefaults(suiteName: suiteName)?.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Timeline provider

struct RecentConversationProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentConversationEntry {
        RecentConversationEntry(date: Date(), conversations: [
            WidgetConversation(id: UUID().uuidString, title: "Explain Swift concurrency", preview: "Sure! Swift 6 introduces...", updatedAt: Date()),
            WidgetConversation(id: UUID().uuidString, title: "Recipe ideas for dinner", preview: "Here are 5 quick recipes...", updatedAt: Date().addingTimeInterval(-3600)),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentConversationEntry) -> Void) {
        let convs = WidgetSharedStore.recentConversations
        completion(RecentConversationEntry(date: Date(), conversations: convs))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentConversationEntry>) -> Void) {
        let convs = WidgetSharedStore.recentConversations
        let entry = RecentConversationEntry(date: Date(), conversations: convs)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget view

struct RecentConversationWidgetView: View {
    let entry: RecentConversationEntry
    @Environment(\.widgetFamily) private var family

    private var maxRows: Int { family == .systemLarge ? 5 : 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.horizontal, 14)
            if entry.conversations.isEmpty {
                emptyState
            } else {
                conversationList
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.accent)
            Text("Lumen")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button(intent: StartConversationIntent()) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var conversationList: some View {
        VStack(spacing: 0) {
            ForEach(entry.conversations.prefix(maxRows)) { conversation in
                Link(destination: URL(string: "lumen://conversation/\(conversation.id)")!) {
                    conversationRow(conversation)
                }
                if conversation.id != entry.conversations.prefix(maxRows).last?.id {
                    Divider().padding(.horizontal, 14)
                }
            }
        }
    }

    private func conversationRow(_ conversation: WidgetConversation) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                if !conversation.preview.isEmpty {
                    Text(conversation.preview)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 26))
                .foregroundStyle(.quaternary)
            Text("No conversations yet")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview(as: .systemMedium) {
    RecentConversationWidget()
} timeline: {
    RecentConversationEntry(date: Date(), conversations: [
        WidgetConversation(id: UUID().uuidString, title: "Explain Swift concurrency", preview: "Sure! Swift 6 introduces...", updatedAt: Date()),
        WidgetConversation(id: UUID().uuidString, title: "Recipe ideas for dinner", preview: "Here are 5 quick recipes...", updatedAt: Date().addingTimeInterval(-3600)),
    ])
}

#Preview(as: .systemLarge) {
    RecentConversationWidget()
} timeline: {
    RecentConversationEntry(date: Date(), conversations: [
        WidgetConversation(id: UUID().uuidString, title: "Explain Swift concurrency", preview: "Sure! Swift 6 introduces...", updatedAt: Date()),
        WidgetConversation(id: UUID().uuidString, title: "Recipe ideas for dinner", preview: "Here are 5 quick recipes...", updatedAt: Date().addingTimeInterval(-3600)),
        WidgetConversation(id: UUID().uuidString, title: "Marketing plan for Q2", preview: "Here's a structured plan...", updatedAt: Date().addingTimeInterval(-7200)),
        WidgetConversation(id: UUID().uuidString, title: "JavaScript vs TypeScript", preview: "Great question! TypeScript...", updatedAt: Date().addingTimeInterval(-86400)),
    ])
}
