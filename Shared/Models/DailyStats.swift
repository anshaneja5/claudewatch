import SwiftData
import Foundation

@Model
final class DailyStats {
    var id: String = UUID().uuidString
    var date: Date = Date.now
    var dateString: String = ""
    var sessionCount: Int = 0
    var messageCount: Int = 0
    var toolCallCount: Int = 0
    var totalInputTokens: Int = 0
    var totalOutputTokens: Int = 0
    var totalCacheCreationTokens: Int = 0
    var totalCacheReadTokens: Int = 0
    var totalCostUSD: Double = 0

    init() {}

    // MARK: - Computed Properties

    var totalTokens: Int {
        totalInputTokens + totalOutputTokens + totalCacheCreationTokens + totalCacheReadTokens
    }

    var formattedCost: String {
        String(format: "$%.2f", totalCostUSD)
    }

    // MARK: - Factory

    static func makeDateString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }
}
