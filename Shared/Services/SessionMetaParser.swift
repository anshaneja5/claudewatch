import Foundation

// MARK: - Data Model

struct SessionMeta: Codable {
    let sessionId: String
    let projectPath: String?
    let startTime: String?
    let durationMinutes: Double?
    let userMessageCount: Int?
    let assistantMessageCount: Int?
    let toolCounts: [String: Int]?
    let inputTokens: Int?
    let outputTokens: Int?
    let firstPrompt: String?
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case projectPath = "project_path"
        case startTime = "start_time"
        case durationMinutes = "duration_minutes"
        case userMessageCount = "user_message_count"
        case assistantMessageCount = "assistant_message_count"
        case toolCounts = "tool_counts"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case firstPrompt = "first_prompt"
        case summary
    }
}

// MARK: - Parser

final class SessionMetaParser {

    private init() {}

    static func loadMeta(sessionId: String) -> SessionMeta? {
        let url = sessionMetaDirectory()
            .appendingPathComponent(sessionId)
            .appendingPathExtension("json")
        return parse(at: url)
    }

    static func loadAllMeta() -> [SessionMeta] {
        let dir = sessionMetaDirectory()
        guard FileManager.default.fileExists(atPath: dir.path),
              let contents = try? FileManager.default.contentsOfDirectory(
                  at: dir,
                  includingPropertiesForKeys: nil,
                  options: [.skipsHiddenFiles]
              ) else { return [] }

        return contents
            .filter { $0.pathExtension == "json" }
            .compactMap { parse(at: $0) }
    }

    private static func parse(at url: URL) -> SessionMeta? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SessionMeta.self, from: data)
    }

    private static func sessionMetaDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("usage-data")
            .appendingPathComponent("session-meta")
    }
}
