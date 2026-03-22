import SwiftUI
import SwiftData
import Charts

struct MenuBarView: View {

    @Query(sort: \DailyStats.date, order: .reverse)
    private var allDailyStats: [DailyStats]

    @Query(sort: \SessionRecord.startTime, order: .reverse)
    private var allSessions: [SessionRecord]

    @Query(sort: \UsageLimitsRecord.lastUpdated, order: .reverse)
    private var limits: [UsageLimitsRecord]

    @State private var isSyncing = false
    @State private var lastSyncDate: Date? = nil
    @State private var selectedTab = 0

    private var todayStats: DailyStats? {
        let today = DailyStats.makeDateString(from: Date())
        return allDailyStats.first { $0.dateString == today }
    }

    private var recentSessions: [SessionRecord] { Array(allSessions.prefix(5)) }
    private var currentLimits: UsageLimitsRecord? { limits.first }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabBar
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    switch selectedTab {
                    case 0: todayTab
                    case 1: allTimeTab
                    case 2: projectsTab
                    case 3: trendsTab
                    default: todayTab
                    }
                }
                .padding(14)
            }
            Divider()
            footer
        }
        .frame(width: 360, height: 580)
        .background(.regularMaterial)
        .task { await triggerSync() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.purple)
            Text("ClaudeWatch")
                .font(.headline).fontWeight(.semibold)
            Spacer()
            Button {
                Task { await triggerSync() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        .rotationEffect(.degrees(isSyncing ? 360 : 0))
                        .animation(
                            isSyncing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default,
                            value: isSyncing
                        )
                    Text(isSyncing ? "Syncing..." : "Sync")
                        .font(.caption).fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(isSyncing ? Color.gray : Color.purple, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSyncing)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "Today", icon: "calendar", tab: 0)
            tabButton(title: "All Time", icon: "infinity", tab: 1)
            tabButton(title: "Projects", icon: "folder.fill", tab: 2)
            tabButton(title: "Trends", icon: "chart.line.uptrend.xyaxis", tab: 3)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
    }

    private func tabButton(title: String, icon: String, tab: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 12))
                Text(title).font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? .purple : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(selectedTab == tab ? Color.purple.opacity(0.1) : .clear,
                        in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Today Tab

    private var todayTab: some View {
        VStack(spacing: 12) {
            todayStatsCard
            tokenBreakdownCard
            rateLimitsSection
            recentSessionsSection
        }
    }

    private var todayStatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Today", systemImage: "calendar")
                .font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)

            HStack(spacing: 0) {
                statCell(icon: "dollarsign.circle.fill", color: .green,
                         value: todayStats.map { String(format: "$%.2f", $0.totalCostUSD) } ?? "$0.00",
                         label: "Cost")
                Divider().frame(height: 36)
                statCell(icon: "terminal.fill", color: .blue,
                         value: "\(todayStats?.sessionCount ?? 0)", label: "Sessions")
                Divider().frame(height: 36)
                statCell(icon: "bubble.left.and.bubble.right.fill", color: .orange,
                         value: "\(todayStats?.messageCount ?? 0)", label: "Messages")
                Divider().frame(height: 36)
                statCell(icon: "character.textbox", color: .purple,
                         value: abbreviate((todayStats?.totalInputTokens ?? 0) + (todayStats?.totalOutputTokens ?? 0)),
                         label: "Tokens")
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var tokenBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Token Breakdown", systemImage: "chart.bar.fill")
                .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)

            let input = todayStats?.totalInputTokens ?? 0
            let output = todayStats?.totalOutputTokens ?? 0
            let cacheWrite = todayStats?.totalCacheCreationTokens ?? 0
            let cacheRead = todayStats?.totalCacheReadTokens ?? 0
            let total = max(input + output + cacheWrite + cacheRead, 1)

            tokenBar(label: "Input", value: input, total: total, color: .blue)
            tokenBar(label: "Output", value: output, total: total, color: .green)
            tokenBar(label: "Cache Write", value: cacheWrite, total: total, color: .purple)
            tokenBar(label: "Cache Read", value: cacheRead, total: total, color: .teal)
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - All Time Tab

    private var allTimeTab: some View {
        VStack(spacing: 12) {
            allTimeStatsCard
            allTimeTokenBreakdown
            allTimeModelsCard
        }
    }

    private var allTimeCost: Double { allDailyStats.reduce(0) { $0 + $1.totalCostUSD } }
    private var allTimeSessions: Int { allDailyStats.reduce(0) { $0 + $1.sessionCount } }
    private var allTimeMessages: Int { allDailyStats.reduce(0) { $0 + $1.messageCount } }
    private var allTimeInput: Int { allDailyStats.reduce(0) { $0 + $1.totalInputTokens } }
    private var allTimeOutput: Int { allDailyStats.reduce(0) { $0 + $1.totalOutputTokens } }
    private var allTimeCacheWrite: Int { allDailyStats.reduce(0) { $0 + $1.totalCacheCreationTokens } }
    private var allTimeCacheRead: Int { allDailyStats.reduce(0) { $0 + $1.totalCacheReadTokens } }
    private var allTimeActiveDays: Int { allDailyStats.count }

    private var allTimeStatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("All Time", systemImage: "infinity")
                .font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)

            HStack(spacing: 0) {
                statCell(icon: "dollarsign.circle.fill", color: .green,
                         value: String(format: "$%.2f", allTimeCost), label: "Total Cost")
                Divider().frame(height: 36)
                statCell(icon: "terminal.fill", color: .blue,
                         value: "\(allTimeSessions)", label: "Sessions")
                Divider().frame(height: 36)
                statCell(icon: "bubble.left.and.bubble.right.fill", color: .orange,
                         value: "\(allTimeMessages)", label: "Messages")
            }

            HStack(spacing: 0) {
                statCell(icon: "character.textbox", color: .purple,
                         value: abbreviate(allTimeInput + allTimeOutput), label: "Tokens")
                Divider().frame(height: 36)
                statCell(icon: "calendar.badge.checkmark", color: .teal,
                         value: "\(allTimeActiveDays)", label: "Active Days")
                Divider().frame(height: 36)
                statCell(icon: "chart.bar.fill", color: .pink,
                         value: allTimeActiveDays > 0 ? String(format: "$%.2f", allTimeCost / Double(allTimeActiveDays)) : "$0",
                         label: "Avg/Day")
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var allTimeTokenBreakdown: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Token Breakdown (All Time)", systemImage: "chart.bar.fill")
                .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)

            let total = max(allTimeInput + allTimeOutput + allTimeCacheWrite + allTimeCacheRead, 1)
            tokenBar(label: "Input", value: allTimeInput, total: total, color: .blue)
            tokenBar(label: "Output", value: allTimeOutput, total: total, color: .green)
            tokenBar(label: "Cache Write", value: allTimeCacheWrite, total: total, color: .purple)
            tokenBar(label: "Cache Read", value: allTimeCacheRead, total: total, color: .teal)
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var allTimeModelsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Models Used", systemImage: "cpu")
                .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)

            let modelGroups = Dictionary(grouping: allSessions) { session -> String in
                let m = session.modelName.lowercased()
                if m.contains("opus") { return "Opus" }
                if m.contains("haiku") { return "Haiku" }
                if m.contains("sonnet") { return "Sonnet" }
                return session.modelName.isEmpty ? "Unknown" : session.modelName
            }

            let sorted = modelGroups.sorted { $0.value.count > $1.value.count }

            ForEach(sorted.prefix(5), id: \.key) { model, sessions in
                HStack {
                    Circle().fill(modelColor(model)).frame(width: 8, height: 8)
                    Text(model).font(.caption).fontWeight(.medium)
                    Spacer()
                    Text("\(sessions.count) sessions").font(.caption2).foregroundStyle(.secondary)
                    Text(String(format: "$%.2f", sessions.reduce(0) { $0 + $1.costUSD }))
                        .font(.caption).fontWeight(.medium).foregroundStyle(.green).monospacedDigit()
                }
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func modelColor(_ model: String) -> Color {
        switch model {
        case "Opus": return .purple
        case "Sonnet": return .orange
        case "Haiku": return .teal
        default: return .gray
        }
    }

    // MARK: - Projects Tab

    private var projectsTab: some View {
        VStack(spacing: 12) {
            projectsBreakdownCard
        }
    }

    private var projectsBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Cost by Project", systemImage: "folder.fill")
                .font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)

            let projectGroups = Dictionary(grouping: allSessions) { $0.projectName }
            let sorted = projectGroups.map { (name: $0.key, sessions: $0.value, cost: $0.value.reduce(0) { $0 + $1.costUSD }) }
                .sorted { $0.cost > $1.cost }
            let maxCost = sorted.first?.cost ?? 1

            if sorted.isEmpty {
                Text("No project data yet").font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
            } else {
                ForEach(sorted.prefix(10), id: \.name) { project in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(project.name.isEmpty ? "Unnamed" : project.name)
                                .font(.caption).fontWeight(.medium).lineLimit(1)
                            Spacer()
                            Text(String(format: "$%.2f", project.cost))
                                .font(.caption).fontWeight(.semibold).foregroundStyle(.green).monospacedDigit()
                        }
                        HStack(spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color.blue.opacity(0.15)).frame(height: 8)
                                    RoundedRectangle(cornerRadius: 3).fill(Color.blue)
                                        .frame(width: max(geo.size.width * (project.cost / maxCost), 4), height: 8)
                                }
                            }
                            .frame(height: 8)
                            Text("\(project.sessions.count) sessions")
                                .font(.caption2).foregroundStyle(.tertiary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        HStack(spacing: 12) {
                            Label("\(project.sessions.reduce(0) { $0 + $1.messageCount }) msgs", systemImage: "message")
                            Label(abbreviate(project.sessions.reduce(0) { $0 + $1.inputTokens + $1.outputTokens }) + " tokens", systemImage: "character.textbox")
                        }
                        .font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                    if project.name != sorted.prefix(10).last?.name { Divider() }
                }
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Trends Tab

    private var trendsTab: some View {
        VStack(spacing: 12) {
            costTrendChart
            dailyCostList
        }
    }

    private struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let cost: Double
        let label: String
    }

    private var last7Days: [DayPoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        let cutoffStr = DailyStats.makeDateString(from: cutoff)
        let stats = allDailyStats.filter { $0.dateString >= cutoffStr }.sorted { $0.dateString < $1.dateString }
        return stats.compactMap { stat in
            guard let date = DateFormatter.menuBarYMD.date(from: stat.dateString) else { return nil }
            return DayPoint(date: date, cost: stat.totalCostUSD, label: stat.dateString)
        }
    }

    private var last30Days: [DayPoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -29, to: Date())!
        let cutoffStr = DailyStats.makeDateString(from: cutoff)
        let stats = allDailyStats.filter { $0.dateString >= cutoffStr }.sorted { $0.dateString < $1.dateString }
        return stats.compactMap { stat in
            guard let date = DateFormatter.menuBarYMD.date(from: stat.dateString) else { return nil }
            return DayPoint(date: date, cost: stat.totalCostUSD, label: stat.dateString)
        }
    }

    private var costTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Daily Cost (Last 7 Days)", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)

            let points = last7Days
            if points.isEmpty {
                Text("Not enough data yet").font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 20)
            } else {
                Chart(points) { point in
                    LineMark(x: .value("Date", point.date, unit: .day), y: .value("Cost", point.cost))
                        .foregroundStyle(Color.purple)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Date", point.date, unit: .day), y: .value("Cost", point.cost))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.purple.opacity(0.3), .clear],
                                           startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", point.date, unit: .day), y: .value("Cost", point.cost))
                        .foregroundStyle(Color.purple).symbolSize(24)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow)).font(.system(size: 9))
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text(String(format: "$%.0f", d)).font(.system(size: 9))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 140)

                // Summary under chart
                HStack(spacing: 0) {
                    let weekTotal = points.reduce(0) { $0 + $1.cost }
                    let weekAvg = points.isEmpty ? 0 : weekTotal / Double(points.count)
                    let weekMax = points.map(\.cost).max() ?? 0

                    miniStat(label: "Total", value: String(format: "$%.2f", weekTotal), color: .green)
                    Divider().frame(height: 24)
                    miniStat(label: "Average", value: String(format: "$%.2f", weekAvg), color: .blue)
                    Divider().frame(height: 24)
                    miniStat(label: "Peak", value: String(format: "$%.2f", weekMax), color: .red)
                }
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var dailyCostList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Daily History (Last 30 Days)", systemImage: "list.bullet")
                .font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)

            let days = allDailyStats
                .sorted { $0.dateString > $1.dateString }
                .prefix(30)

            if days.isEmpty {
                Text("No data yet").font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
            } else {
                ForEach(Array(days), id: \.dateString) { day in
                    HStack {
                        Text(formatDateLabel(day.dateString))
                            .font(.caption).fontWeight(.medium)
                            .frame(width: 70, alignment: .leading)
                        Text("\(day.sessionCount)s")
                            .font(.caption2).foregroundStyle(.secondary).frame(width: 24)
                        Text("\(day.messageCount)m")
                            .font(.caption2).foregroundStyle(.secondary).frame(width: 30)
                        Spacer()
                        Text(abbreviate(day.totalInputTokens + day.totalOutputTokens))
                            .font(.caption2).foregroundStyle(.secondary).monospacedDigit()
                        Text(String(format: "$%.2f", day.totalCostUSD))
                            .font(.caption).fontWeight(.medium).foregroundStyle(.green).monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                    if day.dateString != days.last?.dateString { Divider() }
                }
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Rate Limits

    private var rateLimitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Rate Limits", systemImage: "gauge.with.dots.needle.bottom.50percent")
                .font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)

            if let l = currentLimits {
                rateLimitRow(label: "5-Hour Window", pct: l.fiveHourPercent)
                rateLimitRow(label: "7-Day Window", pct: l.sevenDayPercent)
            } else {
                Text("No rate limit data yet")
                    .font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func rateLimitRow(label: String, pct: Double) -> some View {
        let fraction = min(pct / 100.0, 1.0)
        let color: Color = fraction < 0.6 ? .green : fraction < 0.85 ? .orange : .red
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption).fontWeight(.medium)
                Spacer()
                Text(String(format: "%.1f%%", pct)).font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            ProgressView(value: fraction).tint(color)
        }
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recent Sessions", systemImage: "clock.arrow.circlepath")
                .font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)

            if recentSessions.isEmpty {
                Text("No sessions yet").font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
            } else {
                ForEach(recentSessions, id: \.sessionId) { session in
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill").foregroundStyle(.blue.opacity(0.8)).font(.system(size: 11))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.projectName.isEmpty ? "Unnamed" : session.projectName)
                                .font(.caption).fontWeight(.medium).lineLimit(1)
                            Text(timeAgo(session.startTime)).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(String(format: "$%.3f", session.costUSD))
                            .font(.caption).fontWeight(.medium).foregroundStyle(.green).monospacedDigit()
                    }
                    .padding(.vertical, 2)
                    if session.sessionId != recentSessions.last?.sessionId { Divider() }
                }
            }
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Circle().fill(.green).frame(width: 6, height: 6)
            Text("Auto-sync on").font(.caption2).foregroundStyle(.tertiary)
            Text("·").foregroundStyle(.tertiary)
            Text(lastSyncDate.map { "Synced \(timeAgo($0))" } ?? "Syncing...")
                .font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    // MARK: - Shared Components

    private func statCell(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.system(size: 16))
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func tokenBar(label: String, value: Int, total: Int, color: Color) -> some View {
        let fraction = Double(value) / Double(total)
        return HStack(spacing: 6) {
            Text(label)
                .font(.caption2).foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.15)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: max(geo.size.width * fraction, 2), height: 6)
                }
            }
            .frame(height: 6)
            Text(abbreviate(value))
                .font(.caption2).foregroundStyle(.secondary).monospacedDigit()
                .frame(width: 45, alignment: .trailing)
        }
    }

    // MARK: - Actions & Helpers

    @MainActor
    private func triggerSync() async {
        guard !isSyncing else { return }
        isSyncing = true
        await DataSyncService.shared.syncNow()
        lastSyncDate = Date()
        isSyncing = false
    }

    private func abbreviate(_ value: Int) -> String {
        switch value {
        case 1_000_000...: return String(format: "%.1fM", Double(value) / 1_000_000)
        case 1_000...: return String(format: "%.0fK", Double(value) / 1_000)
        default: return "\(value)"
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let s = -date.timeIntervalSinceNow
        switch s {
        case ..<60: return "just now"
        case ..<3600: return "\(Int(s / 60))m ago"
        case ..<86400: return "\(Int(s / 3600))h ago"
        default: return "\(Int(s / 86400))d ago"
        }
    }

    private func formatDateLabel(_ dateString: String) -> String {
        guard let date = DateFormatter.menuBarYMD.date(from: dateString) else { return dateString }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }
}

extension DateFormatter {
    static let menuBarYMD: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
