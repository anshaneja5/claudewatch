import SwiftData
import Foundation

@Model
final class UsageLimitsRecord {
    var id: String = UUID().uuidString
    var fiveHourPercent: Double = 0
    var sevenDayPercent: Double = 0
    var fiveHourResetsAt: Date? = nil
    var sevenDayResetsAt: Date? = nil
    var lastUpdated: Date = Date.now

    init() {}

    // MARK: - Computed Properties

    var fiveHourFraction: Double { fiveHourPercent / 100.0 }
    var sevenDayFraction: Double { sevenDayPercent / 100.0 }

    var fiveHourFormatted: String {
        String(format: "%.1f%%", fiveHourPercent)
    }

    var sevenDayFormatted: String {
        String(format: "%.1f%%", sevenDayPercent)
    }

    var fiveHourTimeRemaining: String? {
        guard let reset = fiveHourResetsAt else { return nil }
        let seconds = reset.timeIntervalSinceNow
        guard seconds > 0 else { return nil }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "< 1m"
    }

    var sevenDayTimeRemaining: String? {
        guard let reset = sevenDayResetsAt else { return nil }
        let seconds = reset.timeIntervalSinceNow
        guard seconds > 0 else { return nil }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "< 1m"
    }
}
