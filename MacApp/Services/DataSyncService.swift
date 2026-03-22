import Foundation
import SwiftData

@MainActor
final class DataSyncService {

    static let shared = DataSyncService()
    var modelContainer: ModelContainer?

    private let fileWatcher = FileWatcher()
    private var isWatching = false

    private init() {}

    // MARK: - Public API

    func syncNow() async {
        guard let container = modelContainer else { return }

        do {
            let dataService = ClaudeDataService()

            // Load data off main thread
            let rawSessions = await Task.detached(priority: .utility) {
                dataService.loadAllSessions()
            }.value

            let rawLimits = await Task.detached(priority: .utility) {
                dataService.loadLatestUsageLimits()
            }.value

            let rawDailyStats = await Task.detached(priority: .utility) {
                dataService.loadDailyStats()
            }.value

            // Write to SwiftData
            let context = ModelContext(container)
            context.autosaveEnabled = false

            // Upsert sessions
            for raw in rawSessions {
                let sid = raw.sessionId
                let descriptor = FetchDescriptor<SessionRecord>(
                    predicate: #Predicate { $0.sessionId == sid }
                )
                let record = (try? context.fetch(descriptor))?.first ?? {
                    let r = SessionRecord()
                    context.insert(r)
                    return r
                }()

                record.sessionId = raw.sessionId
                record.projectName = raw.projectName
                record.startTime = raw.startTime ?? .now
                record.durationMinutes = raw.durationMinutes ?? 0
                record.inputTokens = raw.tokenUsage.inputTokens
                record.outputTokens = raw.tokenUsage.outputTokens
                record.cacheCreationTokens = raw.tokenUsage.cacheCreationInputTokens
                record.cacheReadTokens = raw.tokenUsage.cacheReadInputTokens
                record.costUSD = raw.costUSD
                record.messageCount = raw.messageCount
                record.toolCallCount = raw.toolCallCount
                record.modelName = raw.model
                record.summary = raw.summary ?? ""
                record.firstPrompt = raw.firstPrompt ?? ""
            }

            // Upsert daily stats
            for raw in rawDailyStats {
                let ds = raw.dateString
                let descriptor = FetchDescriptor<DailyStats>(
                    predicate: #Predicate { $0.dateString == ds }
                )
                let record = (try? context.fetch(descriptor))?.first ?? {
                    let r = DailyStats()
                    context.insert(r)
                    return r
                }()

                record.date = raw.date
                record.dateString = raw.dateString
                record.sessionCount = raw.sessionCount
                record.messageCount = raw.totalMessages
                record.toolCallCount = raw.totalToolCalls
                record.totalInputTokens = raw.totalTokenUsage.inputTokens
                record.totalOutputTokens = raw.totalTokenUsage.outputTokens
                record.totalCacheCreationTokens = raw.totalTokenUsage.cacheCreationInputTokens
                record.totalCacheReadTokens = raw.totalTokenUsage.cacheReadInputTokens
                record.totalCostUSD = raw.totalCostUSD
            }

            // Upsert usage limits (singleton)
            if let raw = rawLimits {
                let descriptor = FetchDescriptor<UsageLimitsRecord>()
                let record = (try? context.fetch(descriptor))?.first ?? {
                    let r = UsageLimitsRecord()
                    context.insert(r)
                    return r
                }()

                record.fiveHourPercent = raw.fiveHourPct
                record.sevenDayPercent = raw.sevenDayPct
                record.fiveHourResetsAt = raw.fiveHourResetsAt
                record.sevenDayResetsAt = raw.sevenDayResetsAt
                record.lastUpdated = Date()
            }

            try context.save()
            print("[DataSyncService] Sync complete — \(rawSessions.count) sessions")
        } catch {
            print("[DataSyncService] Sync error: \(error)")
        }
    }

    func startWatching() {
        guard !isWatching else { return }
        isWatching = true
        fileWatcher.onChange = { [weak self] in
            Task { await self?.syncNow() }
        }
        fileWatcher.start()
        Task { await syncNow() }
    }

    func stopWatching() {
        fileWatcher.stop()
        isWatching = false
    }
}
