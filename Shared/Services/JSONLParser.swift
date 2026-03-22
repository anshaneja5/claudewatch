import Foundation

// MARK: - Data Models

struct JSONLEntry: Codable {
    let type: String
    let timestamp: String
    let sessionId: String
    let version: String?
    let requestId: String?
    let costUSD: Double?
    let message: AssistantMessage?
}

struct AssistantMessage: Codable {
    let id: String?
    let model: String?
    let usage: TokenUsageRaw?
}

struct TokenUsageRaw: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int?
    let cacheReadInputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
    }
}

// MARK: - Parser

final class JSONLParser {

    private init() {}

    /// Reads a `.jsonl` file and returns assistant entries that contain token usage.
    static func parseSessionFile(at url: URL) -> [JSONLEntry] {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        var results: [JSONLEntry] = []

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let data = trimmed.data(using: .utf8),
                  let entry = try? decoder.decode(JSONLEntry.self, from: data),
                  entry.type == "assistant",
                  entry.message?.usage != nil else { continue }
            results.append(entry)
        }
        return results
    }

    /// Recursively finds all `.jsonl` files under `~/.claude/projects/`.
    static func findAllSessionFiles() -> [URL] {
        let root = claudeProjectsDirectory()
        guard FileManager.default.fileExists(atPath: root.path),
              let enumerator = FileManager.default.enumerator(
                  at: root,
                  includingPropertiesForKeys: [.isRegularFileKey],
                  options: [.skipsHiddenFiles]
              ) else { return [] }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "jsonl" {
                files.append(fileURL)
            }
        }
        return files
    }

    /// Extracts a human-readable project name from a JSONL file path.
    static func extractProjectName(from url: URL) -> String {
        let components = url.pathComponents
        for i in components.indices.dropLast(2) {
            if components[i] == "projects" {
                let folder = components[i + 1]
                let parts = folder.components(separatedBy: "-").filter { !$0.isEmpty }
                return parts.last ?? folder
            }
        }
        return url.deletingLastPathComponent().lastPathComponent
    }

    private static func claudeProjectsDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("projects")
    }
}
