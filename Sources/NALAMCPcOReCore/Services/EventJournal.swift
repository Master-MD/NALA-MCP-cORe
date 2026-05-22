import Foundation

public struct JournalEvent: Codable, Equatable {
    public let id: String
    public let type: String
    public let objectID: String
    public let objectType: String
    public let sourceClient: String
    public let title: String
    public let timestamp: String
    public let metadata: [String: String]
}

public final class EventJournal {
    private let eventsURL: URL

    public init(eventsURL: URL) {
        self.eventsURL = eventsURL
    }

    public func append(_ event: JournalEvent) throws {
        let data = try JSONCoding.compactEncoder.encode(event)
        var line = data
        line.append(0x0A)

        if !FileManager.default.fileExists(atPath: eventsURL.path) {
            try FileManager.default.ensureDirectory(eventsURL.deletingLastPathComponent())
            try Data().write(to: eventsURL)
        }

        let handle = try FileHandle(forWritingTo: eventsURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }
}
