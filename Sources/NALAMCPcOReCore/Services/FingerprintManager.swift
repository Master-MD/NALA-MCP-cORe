import Foundation

public final class FingerprintManager {
    public init() {}

    public func fingerprint(for content: String) throws -> Fingerprint {
        let normalized = normalize(content)
        return Fingerprint(
            contentHash: ChecksumManager.sha256String(content),
            normalizedHash: ChecksumManager.sha256String(normalized),
            semanticFingerprint: semanticFingerprint(for: normalized)
        )
    }

    public func normalize(_ content: String) -> String {
        content
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func semanticFingerprint(for normalized: String) -> String {
        let tokens = normalized
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else {
            return ChecksumManager.sha256String("")
        }

        if tokens.count < 3 {
            return ChecksumManager.sha256String(tokens.joined(separator: "|"))
        }

        let shingles = (0...(tokens.count - 3)).map { index in
            tokens[index..<(index + 3)].joined(separator: " ")
        }
        return ChecksumManager.sha256String(shingles.sorted().joined(separator: "|"))
    }
}
