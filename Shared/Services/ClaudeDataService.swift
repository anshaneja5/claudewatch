import Foundation

// MARK: - Output Models

struct ParsedSession {
    let sessionId: String
    let projectName: String
    let startTime: Date?
    let durationMinutes: Double?
    let tokenUsage: TokenUsage
    let costUSD: Double
    let messageCount: Int
    let toolCallCount: Int
    let model: String
    let summary: String?
    let firstPrompt: String?
}

struct ParsedDailyStats {
    let date: Date
    let dateString: String
    let sessionCount: Int
    let totalTokenUsage: TokenUsage
    let totalCostUSD: Double
    let totalMessages: Int
    let totalToolCalls: Int
}

struct ParsedUsageLimits {
    let fiveHourPct: Double
    let sevenDayPct: Double
    let fiveHourResetsAt: Date?
    let sevenDayResetsAt: Date?
}

// MARK: - Service

final class ClaudeDataService {

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoWhole: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Public API

    func loadAllSessions() -> [ParsedSession] {
        let files = JSONLParser.findAllSessionFiles()
        var entriesBySession: [String: (projectName: String, entries: [JSONLEntry])] = [:]

        for url in files {
            let entries = JSONLParser.parseSessionFile(at: url)
            let project = JSONLParser.extractProjectName(from: url)
            for entry in entries {
                let sid = entry.sessionId
                if entriesBySession[sid] == nil {
                    entriesBySession[sid] = (project, [])
                }
                entriesBySession[sid]?.entries.append(entry)
            }
        }

        return entriesBySession.map { (sid, value) in
            buildSession(sessionId: sid, projectName: value.projectName, entries: value.entries)
        }.sorted { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) }
    }

    func loadSessionMeta(sessionId: String) -> SessionMeta? {
        SessionMetaParser.loadMeta(sessionId: sessionId)
    }

    func loadLatestUsageLimits() -> ParsedUsageLimits? {
        guard let snapshot = UsageLimitsParser.loadLatestSnapshot() else { return nil }
        return ParsedUsageLimits(
            fiveHourPct: snapshot.data.fiveHourPct ?? 0,
            sevenDayPct: snapshot.data.sevenDayPct ?? 0,
            fiveHourResetsAt: snapshot.data.fiveHourResetsAt.flatMap { parseDate($0) },
            sevenDayResetsAt: snapshot.data.sevenDayResetsAt.flatMap { parseDate($0) }
        )
    }

    func loadDailyStats() -> [ParsedDailyStats] {
        let sessions = loadAllSessions()
        let calendar = Calendar.current
        var byDay: [String: [ParsedSession]] = [:]

        for session in sessions {
            guard let start = session.startTime else { continue }
            let key = DailyStats.makeDateString(from: start)
            byDay[key, default: []].append(session)
        }

        return byDay.map { (dateString, daySessions) in
            var tokens = TokenUsage()
            var cost = 0.0
            var messages = 0
            var tools = 0
            for s in daySessions {
                tokens += s.tokenUsage
                cost += s.costUSD
                messages += s.messageCount
                tools += s.toolCallCount
            }
            let date = calendar.date(from: calendar.dateComponents([.year, .month, .day],
                from: daySessions.first?.startTime ?? .now)) ?? .now

            return ParsedDailyStats(
                date: date, dateString: dateString,
                sessionCount: daySessions.count,
                totalTokenUsage: tokens, totalCostUSD: cost,
                totalMessages: messages, totalToolCalls: tools
            )
        }.sorted { $0.dateString < $1.dateString }
    }

    // MARK: - Private

    private func buildSession(sessionId: String, projectName: String, entries: [JSONLEntry]) -> ParsedSession {
        var totalUsage = TokenUsage()
        var totalCost = 0.0
        var latestModel = "unknown"
        var earliestTime: Date?

        for entry in entries {
            if let raw = entry.message?.usage {
                totalUsage += TokenUsage(raw: raw)
                if let c = entry.costUSD { totalCost += c }
            }
            if let model = entry.message?.model, !model.isEmpty {
                latestModel = model
            }
            if let ts = parseDate(entry.timestamp) {
                if earliestTime == nil || ts < earliestTime! { earliestTime = ts }
            }
        }

        if totalCost == 0 {
            totalCost = CostCalculator.cost(for: latestModel, usage: totalUsage)
        }

        let meta = SessionMetaParser.loadMeta(sessionId: sessionId)
        let startTime = meta?.startTime.flatMap { parseDate($0) } ?? earliestTime
        let messageCount = (meta?.userMessageCount ?? 0) + (meta?.assistantMessageCount ?? entries.count)
        let toolCallCount = meta?.toolCounts?.values.reduce(0, +) ?? 0
        let displayProject = meta?.projectPath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? projectName

        return ParsedSession(
            sessionId: sessionId, projectName: displayProject,
            startTime: startTime, durationMinutes: meta?.durationMinutes,
            tokenUsage: totalUsage, costUSD: totalCost,
            messageCount: messageCount, toolCallCount: toolCallCount,
            model: latestModel, summary: meta?.summary, firstPrompt: meta?.firstPrompt
        )
    }

    private func parseDate(_ string: String) -> Date? {
        ClaudeDataService.isoFractional.date(from: string)
            ?? ClaudeDataService.isoWhole.date(from: string)
    }
}
