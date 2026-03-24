// LumenWidget target only — do NOT add to the main Lumen target.
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Quick Ask widget
// A small interactive widget with a text-prompt-style button that launches Lumen
// and opens a new conversation. Uses AppIntent with openAppWhenRun.

struct QuickAskWidget: Widget {
    let kind = "QuickAskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAskTimelineProvider()) { entry in
            QuickAskWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Ask Lumen")
        .description("Open a new conversation with Lumen right from your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline provider

struct QuickAskEntry: TimelineEntry {
    let date: Date
    let recentTitle: String?
}

struct QuickAskTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAskEntry {
        QuickAskEntry(date: Date(), recentTitle: "What's the capital of France?")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAskEntry) -> Void) {
        let title = WidgetSharedStore.recentConversationTitle
        completion(QuickAskEntry(date: Date(), recentTitle: title))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAskEntry>) -> Void) {
        let title = WidgetSharedStore.recentConversationTitle
        let entry = QuickAskEntry(date: Date(), recentTitle: title)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Widget view

struct QuickAskWidgetView: View {
    let entry: QuickAskEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemSmall {
                smallView
            } else {
                mediumView
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // Small: icon + "Ask Lumen" label + tap anywhere
    private var smallView: some View {
        Button(intent: StartConversationIntent()) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.accent)
                    Spacer()
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.accent)
                }
                Spacer()
                Text("Ask Lumen")
                    .font(.system(size: 16, weight: .semibold))
                Text("New conversation")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // Medium: icon + label on left, recent conversation title on right
    private var mediumView: some View {
        HStack(spacing: 0) {
            Button(intent: StartConversationIntent()) {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.accent)
                    Spacer()
                    Text("Ask Lumen")
                        .font(.system(size: 17, weight: .bold))
                    Text("New conversation")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(12)

            if let title = entry.recentTitle {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Label("Recent", systemImage: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    QuickAskWidget()
} timeline: {
    QuickAskEntry(date: Date(), recentTitle: nil)
}

#Preview(as: .systemMedium) {
    QuickAskWidget()
} timeline: {
    QuickAskEntry(date: Date(), recentTitle: "Explain quantum entanglement simply")
}
