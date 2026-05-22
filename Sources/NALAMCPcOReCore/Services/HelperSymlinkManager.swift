import Foundation

public final class HelperSymlinkManager {
    public let stableHelperURL: URL

    public init(stableHelperURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("bin/nala-mcp-core-helper")) {
        self.stableHelperURL = stableHelperURL
    }

    public func status(buildHelperURL: URL) -> HelperStatus {
        var isDirectory: ObjCBool = false
        let buildExists = FileManager.default.fileExists(atPath: buildHelperURL.path, isDirectory: &isDirectory) && !isDirectory.boolValue
        let stableExists = FileManager.default.fileExists(atPath: stableHelperURL.path, isDirectory: &isDirectory) && !isDirectory.boolValue
        let stableExecutable = stableExists && FileManager.default.isExecutableFile(atPath: stableHelperURL.path)
        return HelperStatus(buildHelperExists: buildExists, stableHelperExists: stableExists, stableHelperExecutable: stableExecutable)
    }

    public func installPlan(realHelperURL: URL) -> HelperSymlinkPlan {
        let binURL = stableHelperURL.deletingLastPathComponent()
        return HelperSymlinkPlan(
            realHelperURL: realHelperURL,
            linkURL: stableHelperURL,
            commands: [
                "mkdir -p \"\(binURL.path)\"",
                "chmod +x \"\(realHelperURL.path)\"",
                "ln -sfn \"\(realHelperURL.path)\" \"\(stableHelperURL.path)\""
            ],
            requiresSudo: false
        )
    }

    public func install(realHelperURL: URL) throws -> HelperSymlinkPlan {
        let plan = installPlan(realHelperURL: realHelperURL)
        try FileManager.default.ensureDirectory(plan.linkURL.deletingLastPathComponent())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: realHelperURL.path)
        if FileManager.default.fileExists(atPath: plan.linkURL.path) {
            try FileManager.default.removeItem(at: plan.linkURL)
        }
        try FileManager.default.createSymbolicLink(at: plan.linkURL, withDestinationURL: realHelperURL)
        return plan
    }
}
