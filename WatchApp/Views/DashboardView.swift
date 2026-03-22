import SwiftUI
import SwiftData

extension Color {
    static let claudeOrange = Color(red: 0.910, green: 0.482, blue: 0.208)
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

struct DashboardView: View {

    @Query private var todayStats: [DailyStats]
    @Query(filter: #Predicate<SessionRecord> { $0.isActive == true })
    private var activeSessions: [SessionRecord]

    private let dailyBudget: Double = 10.0

    private var todayCost: Double { todayStats.first?.totalCostUSD ?? 0 }
    private var todaySessions: Int { todayStats.first?.sessionCount ?? 0 }
    private var todayMessages: Int { todayStats.first?.messageCount ?? 0 }
    private var todayTokens: Int { todayStats.first?.totalTokens ?? 0 }
    private var isActive: Bool { !activeSessions.isEmpty }

    private var tokensAbbr: String {
        switch todayTokens {
        case 1_000_000...: return String(format: "%.1fM", Double(todayTokens) / 1_000_000)
        case 1_000...: return String(format: "%.0fK", Double(todayTokens) / 1_000)
        default: return "\(todayTokens)"
        }
    }

    private var budgetFraction: Double { min(todayCost / dailyBudget, 1.0) }

    init() {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        _todayStats = Query(filter: #Predicate<DailyStats> { $0.dateString == today })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Active indicator
                if isActive {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 7, height: 7)
                        Text("Active").font(.system(size: 11, weight: .semibold)).foregroundStyle(.green)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.green.opacity(0.15), in: Capsule())
                }

                // Cost gauge
                Gauge(value: budgetFraction) {
                    EmptyView()
                } currentValueLabel: {
                    Text(todayCost, format: .currency(code: "USD"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(Color.claudeOrange)
                } minimumValueLabel: {
                    Text("$0").font(.system(size: 9)).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("$\(Int(dailyBudget))").font(.system(size: 9)).foregroundStyle(.secondary)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [Color.claudeOrange.opacity(0.6), Color.claudeOrange]))
                .frame(width: 100, height: 100)

                Text("Today's Cost").font(.system(size: 11)).foregroundStyle(.secondary)

                // Stats row
                HStack(spacing: 0) {
                    MiniStat(icon: "square.stack.3d.up", value: "\(todaySessions)", label: "Sessions")
                    Divider().frame(height: 28)
                    MiniStat(icon: "message", value: "\(todayMessages)", label: "Msgs")
                    Divider().frame(height: 28)
                    MiniStat(icon: "text.word.spacing", value: tokensAbbr, label: "Tokens")
                }
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Claude")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MiniStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(Color.claudeOrange)
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded))
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
