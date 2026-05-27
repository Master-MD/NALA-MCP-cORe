import Foundation

public final class VaultManager {
    public let paths: VaultPaths

    public init(rootURL: URL) {
        self.paths = VaultPaths(rootURL: rootURL)
    }

    public func initializeDirectories() throws {
        for directory in paths.requiredDirectories {
            try FileManager.default.ensureDirectory(directory)
        }

        for file in [paths.eventsURL, paths.appLogURL, paths.serverLogURL, paths.auditLogURL, paths.fingerprintIndexURL] where !FileManager.default.fileExists(atPath: file.path) {
            try "".write(to: file, atomically: true, encoding: .utf8)
        }

        if !FileManager.default.fileExists(atPath: paths.settingsURL.path) {
            let settings: [String: String] = [
                "version": NALAConstants.version,
                "automaticBackups": "false",
                "backupFrequency": "daily"
            ]
            let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: paths.settingsURL)
        }

        if !FileManager.default.fileExists(atPath: paths.clientsURL.path) {
            let data = try JSONSerialization.data(withJSONObject: NALAConstants.defaultKnownClients, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: paths.clientsURL)
        }

        if !FileManager.default.fileExists(atPath: paths.permissionsURL.path) {
            let permissions = [
                "unknownClients": "deny",
                "destructiveActions": "deny",
                "knownClients": "allow"
            ]
            let data = try JSONSerialization.data(withJSONObject: permissions, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: paths.permissionsURL)
        }
    }
}
