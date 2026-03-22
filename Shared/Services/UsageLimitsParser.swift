import Foundation

// MARK: - Data Models

struct RawUsageLimits: Codable {
    let data: RawUsageLimitsData
    let expiresAt: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case expiresAt = "expires_at"
    }
}

struct RawUsageLimitsData: Codable {
    let fiveHourPct: Double?
    let sevenDayPct: Double?
    let fiveHourResetsAt: String?
    let sevenDayResetsAt: String?

    enum CodingKeys: String, CodingKey {
        case fiveHourPct = "five_hour_pct"
        case sevenDayPct = "seven_day_pct"
        case fiveHourResetsAt = "five_hour_resets_at"
        case sevenDayResetsAt = "seven_day_resets_at"
    }
}

// MARK: - Parser

final class UsageLimitsParser {

    private init() {}

    /// Finds the most recently modified usage-limits file and parses it.
    static func loadLatestSnapshot() -> RawUsageLimits? {
        let files = findAllUsageLimitFiles()
        let sorted = files.sorted { a, b in
            let dateA = modDate(a) ?? .distantPast
            let dateB = modDate(b) ?? .distantPast
            return dateA > dateB
        }

        for url in sorted {
            if let snapshot = parse(at: url) {
                return snapshot
            }
        }
        return nil
    }

    static func findAllUsageLimitFiles() -> [URL] {
        let root = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("projects")

        guard FileManager.default.fileExists(atPath: root.path),
              let enumerator = FileManager.default.enumerator(
                  at: root,
                  includingPropertiesForKeys: [.isRegularFileKey],
                  options: [.skipsHiddenFiles]
              ) else { return [] }

        var results: [URL] = []
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.isEmpty,
               fileURL.lastPathComponent.hasSuffix("-usage-limits") {
                results.append(fileURL)
            }
        }
        return results
    }

    private static func parse(at url: URL) -> RawUsageLimits? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(RawUsageLimits.self, from: data)
    }

    private static func modDate(_ url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
