import NALAMCPcOReCore
import SwiftUI

struct BackupsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Backups", subtitle: "Full backup, delta journal copy, manifest, checksums, and ZIP package.") {
            HStack {
                Button("Backup Now", systemImage: "externaldrive.badge.plus") { model.backupNow() }
                Toggle("Automatic Backups", isOn: .constant(false))
                    .disabled(true)
                Text("planned scheduler")
                    .foregroundStyle(.secondary)
            }
            OutputBox(text: model.lastOutput)
        }
    }
}

struct RestoreView: View {
    @EnvironmentObject private var model: AppModel
    @State private var backupPath = ""

    var body: some View {
        ScreenContainer(title: "Restore", subtitle: "Restore always starts with dry-run and checksum verification.") {
            HStack {
                TextField("Full backup folder", text: $backupPath)
                    .textFieldStyle(.roundedBorder)
                Button("Choose", systemImage: "folder") {
                    model.chooseRestoreFolder(currentPath: $backupPath)
                }
                Button("Run Dry-Run", systemImage: "checklist") {
                    model.restoreDryRun(path: backupPath)
                }
                .disabled(backupPath.isEmpty)
            }
            Button("Restore Selected Data - planned safe-mode write step", systemImage: "arrow.counterclockwise") {}
                .disabled(true)
            OutputBox(text: model.lastOutput)
        }
    }
}

struct DumpsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Dumps", subtitle: "NALA Full Dump and NALA-bRaiN Sync export packages.") {
            HStack {
                Button("Export Dump Now", systemImage: "square.and.arrow.up") { model.exportDump() }
                Button("Export NALA-bRaiN Sync", systemImage: "brain") { model.exportBrainSync() }
            }
            OutputBox(text: model.lastOutput)
        }
    }
}

struct LogsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Logs", subtitle: "App, server, and audit logs. Secret-like values are redacted.") {
            Picker("Log", selection: $model.selectedLog) {
                Text("App").tag("app")
                Text("Server").tag("server")
                Text("Audit").tag("audit")
            }
            .pickerStyle(.segmented)
            .frame(width: 360)

            OutputBox(text: model.logText(), minHeight: 360)
        }
    }
}

struct HealthView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Health", subtitle: "Core health check for database, index, user, and access posture.") {
            if let health = model.health {
                InfoGrid(rows: [
                    ("Database", health.databaseStatus),
                    ("Journal mode", health.journalMode),
                    ("FTS5", health.ftsReady ? "ready" : "missing"),
                    ("External access", health.externalAccess),
                    ("User", health.currentUser),
                    ("Vault", health.vaultPath)
                ])
            }
            Button("Refresh Health", systemImage: "arrow.clockwise") {
                model.reloadHealth()
            }
        }
        .onAppear { model.reloadHealth() }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            Form {
                Section("General") {
                    Text("Version \(model.health?.version ?? "0.1.0")")
                    Toggle("Start NALA-MCP-cORe at login", isOn: Binding(
                        get: { model.startAtLogin },
                        set: { model.setStartAtLogin($0) }
                    ))
                    Toggle("Start hidden at login - planned", isOn: .constant(false))
                        .disabled(true)
                    Toggle("Show menu bar icon", isOn: Binding(
                        get: { model.showMenuBarIcon },
                        set: { model.setShowMenuBarIcon($0) }
                    ))
                    Picker("Default page on launch", selection: .constant("Status")) {
                        Text("Status").tag("Status")
                    }
                }

                Section("Vault") {
                    Text(model.core?.paths.rootURL.path ?? "not initialized")
                        .textSelection(.enabled)
                    Button("Open Vault Folder", systemImage: "folder") { model.openVaultFolder() }
                    Button("Change Vault Folder - requires stopped server and backup", systemImage: "arrow.triangle.2.circlepath") {}
                        .disabled(true)
                    Button("Verify Vault", systemImage: "checkmark.seal") { model.reloadHealth() }
                    Button("Rebuild Search Index - planned", systemImage: "magnifyingglass") {}
                        .disabled(true)
                }

                Section("Server") {
                    Text("Transport: stdio")
                    Text("Host: 127.0.0.1 only")
                    Text("Helper: \(model.core?.helperSymlinkManager.stableHelperURL.path ?? "not available")")
                        .textSelection(.enabled)
                    Button("Install Helper Symlink", systemImage: "link") { model.installHelperSymlink() }
                    Button("Reveal Helper", systemImage: "folder") { model.revealHelper() }
                    Button("Test Helper", systemImage: "checkmark.circle") { model.testHelper() }
                }

                Section("MCP Connections") {
                    Text("Codex, Gemini CLI, Antigravity, and Manual STDIO configs are available in MCP Clients.")
                    Button("Copy Codex Config", systemImage: "doc.on.doc") {
                        if let config = model.clientConfigs()?.codexTOML {
                            model.copyToClipboard(config, message: "Copied Codex config.")
                        }
                    }
                }

                Section("Permissions") {
                    Text("Known client policies: allow read/search/add candidate writes")
                    Text("Unknown client policy: deny")
                    Text("Destructive operations: disabled")
                    Toggle("Ask before decision candidate - planned", isOn: .constant(false))
                        .disabled(true)
                    Toggle("Ask before import - planned", isOn: .constant(false))
                        .disabled(true)
                }

                Section("Monitoring") {
                    Picker("Monitoring interval", selection: Binding(
                        get: { model.monitoringInterval },
                        set: { model.setMonitoringInterval($0) }
                    )) {
                        Text("off").tag("off")
                        Text("5 sec").tag("5 sec")
                        Text("10 sec").tag("10 sec")
                        Text("30 sec").tag("30 sec")
                    }
                    Toggle("Show CPU chart", isOn: .constant(true))
                    Toggle("Show RAM chart", isOn: .constant(true))
                    Toggle("Show MCP calls chart", isOn: .constant(true))
                }

                Section("Menu Bar") {
                    Toggle("Show menu bar icon", isOn: Binding(
                        get: { model.showMenuBarIcon },
                        set: { model.setShowMenuBarIcon($0) }
                    ))
                    Picker("Menu bar text", selection: Binding(
                        get: { model.showMenuBarMetric },
                        set: { model.setShowMenuBarMetric($0) }
                    )) {
                        Text("Icon only").tag("icon")
                        Text("CPU").tag("cpu")
                        Text("RAM").tag("ram")
                        Text("Request pulse").tag("pulse")
                    }
                }

                Section("Backups") {
                    Toggle("Automatic backups - planned scheduler", isOn: .constant(false))
                        .disabled(true)
                    Text("Frequency: hourly / daily / weekly planned")
                    Button("Backup Now", systemImage: "externaldrive") { model.backupNow() }
                }

                Section("Dumps") {
                    Toggle("Include markdown", isOn: .constant(true))
                    Toggle("Include JSONL", isOn: .constant(true))
                    Toggle("Include NALA-bRaiN package", isOn: .constant(true))
                    Button("Export Dump Now", systemImage: "square.and.arrow.up") { model.exportDump() }
                }

                Section("Labs") {
                    Toggle("Enable labs section", isOn: .constant(true))
                    Text("Labs use sandbox copies only.")
                    Button("Create Sandbox Check", systemImage: "flask") { model.createLabSandbox() }
                }

                Section("Advanced") {
                    Button("Rebuild Database Indexes - planned", systemImage: "arrow.clockwise") {}
                        .disabled(true)
                    Button("Vacuum Database - requires confirmation, planned", systemImage: "cylinder") {}
                        .disabled(true)
                    Button("Export Diagnostics Bundle - planned", systemImage: "shippingbox") {}
                        .disabled(true)
                    Button("Reset Window Layout - planned", systemImage: "rectangle.3.group") {}
                        .disabled(true)
                }
            }
            .padding()
        }
    }
}

struct LabsOverviewView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Labs Overview", subtitle: "Experimental features run on sandbox snapshots, never the live vault.") {
            Button("Create Sandbox Check", systemImage: "flask") {
                model.createLabSandbox()
            }
            ForEach(ExperimentalFeatureRegistry.features) { feature in
                HStack {
                    Text(feature.name)
                    Spacer()
                    Text(feature.state)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            OutputBox(text: model.lastOutput)
        }
    }
}

struct PlannedLabView: View {
    let title: String

    var body: some View {
        ScreenContainer(title: title, subtitle: "Planned experimental lab. Disabled in v0.1 unless isolated sandbox support is explicitly added.") {
            Label("planned", systemImage: "pause.circle")
                .foregroundStyle(.secondary)
            Button("Run \(title) - planned") {}
                .disabled(true)
        }
    }
}

struct OutputBox: View {
    let text: String
    var minHeight: CGFloat = 100

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? "No output yet." : text)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .frame(minHeight: minHeight)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
