import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {

    @Query(sort: \DailyStats.dateString, order: .reverse)
    private var allStats: [DailyStats]

    private var weekStats: [DailyStats] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        let cutoffStr = DateFormatter.yyyyMMdd.string(from: cutoff)
        return allStats.filter { $0.dateString >= cutoffStr }.sorted { $0.dateString < $1.dateString }
    }

    private var weekTotal: Double { weekStats.reduce(0) { $0 + $1.totalCostUSD } }
    private var weekAverage: Double { weekStats.isEmpty ? 0 : weekTotal / Double(weekStats.count) }

    private struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let cost: Double
    }

    private var points: [DayPoint] {
        weekStats.compactMap { stat in
            guard let date = DateFormatter.yyyyMMdd.date(from: stat.dateString) else { return nil }
            return DayPoint(date: date, cost: stat.totalCostUSD)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if points.isEmpty {
                    ContentUnavailableView("No Trends", systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Keep coding to build 7-day history."))
                        .frame(height: 90)
                } else {
                    Chart(points) { point in
                        LineMark(x: .value("Date", point.date, unit: .day), y: .value("Cost", point.cost))
                            .foregroundStyle(Color.claudeOrange)
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Date", point.date, unit: .day), y: .value("Cost", point.cost))
                            .foregroundStyle(
                                LinearGradient(colors: [Color.claudeOrange.opacity(0.35), .clear],
                                               startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", point.date, unit: .day), y: .value("Cost", point.cost))
                            .foregroundStyle(Color.claudeOrange).symbolSize(20)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow)).font(.system(size: 8))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text(d, format: .currency(code: "USD").precision(.fractionLength(0)))
                                        .font(.system(size: 8))
                                }
                            }
                        }
                    }
                    .frame(height: 90)
                }

                Divider()

                HStack(spacing: 0) {
                    SummaryStat(icon: "dollarsign.circle", label: "7-Day Total",
                                value: weekTotal.formatted(.currency(code: "USD").precision(.fractionLength(2))))
                    Divider().frame(height: 32)
                    SummaryStat(icon: "chart.bar", label: "Daily Avg",
                                value: weekAverage.formatted(.currency(code: "USD").precision(.fractionLength(2))))
                }
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SummaryStat: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(Color.claudeOrange)
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Color.claudeOrange)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
