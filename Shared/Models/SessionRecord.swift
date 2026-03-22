import SwiftData
import Foundation

@Model
final class SessionRecord {
    var sessionId: String = ""
    var projectName: String = ""
    var projectPath: String = ""
    var startTime: Date = Date.now
    var endTime: Date? = nil
    var durationMinutes: Double = 0
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheCreationTokens: Int = 0
    var cacheReadTokens: Int = 0
    var costUSD: Double = 0
    var messageCount: Int = 0
    var toolCallCount: Int = 0
    var modelName: String = ""
    var summary: String = ""
    var firstPrompt: String = ""
    var isActive: Bool = false

    init() {}

    // MARK: - Computed Properties

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }

    var formattedCost: String {
        String(format: "$%.2f", costUSD)
    }

    var formattedDuration: String {
        let totalMinutes = Int(durationMinutes)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
