import CryptoKit
import Foundation

public enum ChecksumManager {
    public static func sha256String(_ string: String) -> String {
        sha256Data(Data(string.utf8))
    }

    public static func sha256Data(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256File(_ url: URL) throws -> String {
        try sha256Data(Data(contentsOf: url))
    }

    public static func writeChecksums(for rootURL: URL, to checksumsURL: URL) throws {
        let lines = try checksums(for: rootURL)
            .map { "\($0.value)  \($0.key)" }
            .joined(separator: "\n")
        try (lines + "\n").write(to: checksumsURL, atomically: true, encoding: .utf8)
    }

    public static func checksums(for rootURL: URL) throws -> [String: String] {
        let manager = FileManager.default
        let rootPath = rootURL.resolvingSymlinksInPath().path
        guard let enumerator = manager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return [:]
        }

        var output: [String: String] = [:]
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            let filePath = fileURL.resolvingSymlinksInPath().path
            let relative = filePath.hasPrefix(rootPath + "/")
                ? String(filePath.dropFirst(rootPath.count + 1))
                : fileURL.lastPathComponent
            guard relative != "checksums.sha256", !relative.hasSuffix(".zip") else { continue }
            output[relative] = try sha256File(fileURL)
        }
        return output.sorted { $0.key < $1.key }.reduce(into: [:]) { result, item in
            result[item.key] = item.value
        }
    }
}
