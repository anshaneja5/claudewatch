import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct ClaudeWatchEntry: TimelineEntry {
    let date: Date
    let todayCost: Double
    let sessionCount: Int
    let fiveHourPercent: Double
    let isActive: Bool
}

// MARK: - Timeline Provider

struct ClaudeWatchProvider: TimelineProvider {

    func placeholder(in context: Context) -> ClaudeWatchEntry {
        ClaudeWatchEntry(date: .now, todayCost: 2.45, sessionCount: 3, fiveHourPercent: 48, isActive: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClaudeWatchEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClaudeWatchEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ClaudeWatchEntry {
        do {
            let schema = Schema([SessionRecord.self, DailyStats.self, UsageLimitsRecord.self])
            let config = ModelConfiguration(
                "ClaudeWatch",
                schema: schema,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            // Today's stats
            let today = {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f.string(from: Date())
            }()

            let statsDescriptor = FetchDescriptor<DailyStats>(
                predicate: #Predicate { $0.dateString == today }
            )
            let todayStats = try context.fetch(statsDescriptor).first

            // Usage limits
            let limitsDescriptor = FetchDescriptor<UsageLimitsRecord>(
                sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
            )
            let limits = try context.fetch(limitsDescriptor).first

            // Active sessions
            let activeDescriptor = FetchDescriptor<SessionRecord>(
                predicate: #Predicate { $0.isActive == true }
            )
            let hasActive = !(try context.fetch(activeDescriptor)).isEmpty

            return ClaudeWatchEntry(
                date: Date(),
                todayCost: todayStats?.totalCostUSD ?? 0,
                sessionCount: todayStats?.sessionCount ?? 0,
                fiveHourPercent: limits?.fiveHourPercent ?? 0,
                isActive: hasActive
            )
        } catch {
            return ClaudeWatchEntry(date: .now, todayCost: 0, sessionCount: 0, fiveHourPercent: 0, isActive: false)
        }
    }
}

// MARK: - Complication Views

struct AccessoryCircularView: View {
    let entry: ClaudeWatchEntry

    var body: some View {
        Gauge(value: entry.todayCost, in: 0...10) {
            Image(systemName: "dollarsign").font(.system(size: 10, weight: .semibold))
        } currentValueLabel: {
            Text(String(format: "%.2f", entry.todayCost))
                .font(.system(size: 9, weight: .medium).monospacedDigit())
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.todayCost > 8 ? .red : entry.todayCost > 5 ? .orange : .green)
    }
}

struct AccessoryRectangularView: View {
    let entry: ClaudeWatchEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ClaudeWatch").font(.headline).foregroundStyle(.secondary).widgetAccentable()
            Text(String(format: "$%.2f today", entry.todayCost))
                .font(.system(.body, design: .monospaced).weight(.semibold))
            Text(entry.sessionCount == 1 ? "1 session" : "\(entry.sessionCount) sessions")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AccessoryInlineView: View {
    let entry: ClaudeWatchEntry

    var body: some View {
        Text("$\(String(format: "%.2f", entry.todayCost)) | \(entry.sessionCount) sessions")
    }
}

struct AccessoryCornerView: View {
    let entry: ClaudeWatchEntry

    var body: some View {
        Gauge(value: entry.todayCost, in: 0...10) {
            Image(systemName: "dollarsign")
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.todayCost > 8 ? .red : entry.todayCost > 5 ? .orange : .green)
        .widgetLabel {
            Text(String(format: "$%.2f", entry.todayCost))
                .font(.system(.caption2, design: .monospaced).weight(.medium))
        }
    }
}

// MARK: - Widget

struct ClaudeWatchWidget: Widget {
    let kind = "ClaudeWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClaudeWatchProvider()) { entry in
            ClaudeWatchEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ClaudeWatch")
        .description("Track Claude Code usage at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct ClaudeWatchEntryView: View {
    let entry: ClaudeWatchEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: AccessoryCircularView(entry: entry)
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        case .accessoryInline: AccessoryInlineView(entry: entry)
        case .accessoryCorner: AccessoryCornerView(entry: entry)
        default: AccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct ClaudeWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClaudeWatchWidget()
    }
}
