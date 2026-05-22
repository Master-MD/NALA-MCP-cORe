import Foundation

enum CoreClock {
    static func nowString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    static func pathTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}

enum JSONCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let compactEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static let decoder = JSONDecoder()
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func sqliteEscapedFTSQuery() -> String {
        split(whereSeparator: { $0.isWhitespace })
            .map { token in
                let escaped = String(token).replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\""
            }
            .joined(separator: " ")
    }
}

extension FileManager {
    func ensureDirectory(_ url: URL) throws {
        try createDirectory(at: url, withIntermediateDirectories: true)
    }

    func recreateDirectory(_ url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
        try createDirectory(at: url, withIntermediateDirectories: true)
    }
}
