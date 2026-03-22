import SwiftUI
import SwiftData

struct RateLimitsView: View {

    @Query(sort: \UsageLimitsRecord.lastUpdated, order: .reverse)
    private var limits: [UsageLimitsRecord]

    private var current: UsageLimitsRecord? { limits.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let limit = current {
                    RateLimitGauge(
                        title: "5-Hour",
                        fraction: limit.fiveHourFraction,
                        resetText: limit.fiveHourTimeRemaining
                    )
                    RateLimitGauge(
                        title: "7-Day",
                        fraction: limit.sevenDayFraction,
                        resetText: limit.sevenDayTimeRemaining
                    )
                } else {
                    ContentUnavailableView("No Data", systemImage: "gauge",
                        description: Text("Rate limits appear after your first session."))
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Rate Limits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RateLimitGauge: View {
    let title: String
    let fraction: Double
    let resetText: String?

    private var color: Color {
        switch fraction {
        case ..<0.5: return .green
        case ..<0.8: return .yellow
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)

            Gauge(value: fraction) {
                EmptyView()
            } currentValueLabel: {
                Text(String(format: "%.0f%%", fraction * 100))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [color.opacity(0.5), color]))
            .frame(width: 80, height: 80)

            if let reset = resetText {
                HStack(spacing: 3) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 9)).foregroundStyle(.secondary)
                    Text("Resets in \(reset)").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
