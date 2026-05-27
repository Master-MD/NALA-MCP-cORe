import Foundation

public final class ResourceMonitor {
    public private(set) var samples: [ResourceSample] = []
    public private(set) var totalRequests = 0
    public private(set) var failedRequests = 0
    public private(set) var lastRequestAt: Date?
    private let maxSamples: Int

    public init(maxSamples: Int = 60) {
        self.maxSamples = maxSamples
    }

    public func recordRequest(result: MCPToolStatus, at date: Date = Date()) {
        totalRequests += 1
        if result != .ok {
            failedRequests += 1
        }
        lastRequestAt = date
    }

    public func addSample(_ sample: ResourceSample) {
        samples.append(sample)
        samples = Array(samples.suffix(maxSamples))
    }

    public func summary(pid: Int?, uptimeSeconds: TimeInterval?) -> ResourceMonitorSummary {
        ResourceMonitorSummary(
            pid: pid,
            uptimeSeconds: uptimeSeconds,
            samples: samples,
            totalRequests: totalRequests,
            failedRequests: failedRequests,
            lastRequestAt: lastRequestAt
        )
    }

    public func sampleCurrentProcess() -> ResourceSample {
        let physicalFootprint = currentResidentMemoryMB()
        return ResourceSample(
            timestamp: Date(),
            cpuPercent: 0,
            ramMB: physicalFootprint,
            callsPerMinute: callsPerMinute()
        )
    }

    private func callsPerMinute() -> Double {
        guard let lastRequestAt, Date().timeIntervalSince(lastRequestAt) <= 60 else {
            return 0
        }
        return Double(totalRequests)
    }

    private func currentResidentMemoryMB() -> Double {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-o", "rss=", "-p", "\(ProcessInfo.processInfo.processIdentifier)"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
            return (Double(text) ?? 0) / 1024.0
        } catch {
            return 0
        }
    }
}

public enum MenuBarStateMapper {
    public static func state(serverRunning: Bool, hasError: Bool, hasRecentActivity: Bool) -> MenuBarVisualState {
        if !serverRunning {
            return .stopped
        }
        if hasError {
            return .error
        }
        if hasRecentActivity {
            return .active
        }
        return .warning
    }
}
