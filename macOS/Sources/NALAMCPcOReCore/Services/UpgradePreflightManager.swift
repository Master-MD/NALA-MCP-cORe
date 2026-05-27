import Foundation

public final class UpgradePreflightManager {
    public init() {}

    public func inspectV01Vault(candidates: [URL], activity: [ClientActivity], serverRunning: Bool) throws -> UpgradePreflightReport {
        guard let vault = candidates.first(where: { candidate in
            FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Vault/nala-mcp-core.sqlite").path)
                && FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Vault/events.jsonl").path)
        }) else {
            return UpgradePreflightReport(
                status: .noV01VaultFound,
                vaultURL: nil,
                detectedClients: [],
                instructions: "No v0.1 vault found. Choose a vault manually before upgrading.",
                canInspectWhileRunning: true,
                canMigrateWhileRunning: false
            )
        }

        let recentClients = Array(Set(activity.filter { Date().timeIntervalSince($0.timestamp) <= 600 }.map(\.client))).sorted { $0.rawValue < $1.rawValue }
        if serverRunning || !recentClients.isEmpty {
            let names = recentClients.map(\.rawValue)
            let stopList = names.isEmpty ? "stop connected MCP clients" : names.map { "stop \($0)" }.joined(separator: ", ")
            return UpgradePreflightReport(
                status: .requiresUserStop,
                vaultURL: vault,
                detectedClients: recentClients,
                instructions: "v0.1 data can be inspected while running, but final migration must wait: \(stopList), then stop the old helper.",
                canInspectWhileRunning: true,
                canMigrateWhileRunning: false
            )
        }

        return UpgradePreflightReport(
            status: .ready,
            vaultURL: vault,
            detectedClients: [],
            instructions: "v0.1 vault found and no recent MCP activity detected. Create backup, verify checksums, then run controlled migration.",
            canInspectWhileRunning: true,
            canMigrateWhileRunning: true
        )
    }
}
