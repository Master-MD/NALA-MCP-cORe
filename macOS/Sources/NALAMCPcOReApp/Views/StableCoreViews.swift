import NALAMCPcOReCore
import SwiftUI

struct StatusView: View {
    var body: some View {
        StatusDashboardView()
    }
}

struct SearchView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var project = ""

    var body: some View {
        ScreenContainer(title: "Search", subtitle: "Indexed SQLite FTS5 search_context surface.") {
            HStack {
                TextField("Query", text: $query)
                    .textFieldStyle(.roundedBorder)
                TextField("Project", text: $project)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                Button("Search", systemImage: "magnifyingglass") {
                    model.search(query: query, project: project)
                }
                .keyboardShortcut(.defaultAction)
            }

            ForEach(model.searchResults) { result in
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.title)
                        .font(.headline)
                    Text("[\(result.objectType)] \(result.projectName) - \(result.sourceClient) - \(result.source)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(result.content)
                        .textSelection(.enabled)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct ManualEntryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var kind: ManualEntryKind = .memory
    @State private var project = "General"
    @State private var title = ""
    @State private var content = ""
    @State private var severity = "medium"

    var body: some View {
        ScreenContainer(title: "Projects", subtitle: "Manual project, memory, decision, bug, and session summary entry.") {
            Picker("Type", selection: $kind) {
                ForEach(ManualEntryKind.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 640)

            TextField("Project", text: $project)
                .textFieldStyle(.roundedBorder)
            TextField(kind == .project ? "Project name" : "Title", text: $title)
                .textFieldStyle(.roundedBorder)
            if kind == .bug {
                TextField("Severity", text: $severity)
                    .textFieldStyle(.roundedBorder)
            }
            TextEditor(text: $content)
                .font(.body)
                .frame(minHeight: 180)
                .scrollContentBackground(.hidden)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button("Save Entry", systemImage: "tray.and.arrow.down.fill") {
                model.addEntry(kind: kind, project: project, title: title, content: content, severity: severity)
                title = ""
                content = ""
            }
            .buttonStyle(.borderedProminent)

            ProjectListView()
        }
    }
}

struct ProjectListView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Projects")
                .font(.headline)
            ForEach((try? model.core?.listProjects()) ?? []) { project in
                HStack {
                    Text(project.name)
                    Spacer()
                    Text(project.updatedAt)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

struct MCPClientsView: View {
    var body: some View {
        ConnectionWizardView()
    }
}

struct PermissionsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Permissions", subtitle: "Allow / ask / deny policy for local MCP tools.") {
            InfoGrid(rows: [
                ("Known clients", "read/search/add/export allowed"),
                ("Unknown clients", "deny"),
                ("Destructive actions", "deny in v0.1"),
                ("delete_memory", model.core?.permissionManager.decision(client: "Codex", action: .deleteMemory).rawValue ?? ""),
                ("overwrite_decision", model.core?.permissionManager.decision(client: "Codex", action: .overwriteDecision).rawValue ?? ""),
                ("remote_execute", model.core?.permissionManager.decision(client: "Codex", action: .remoteExecute).rawValue ?? "")
            ])
        }
    }
}

struct DatabaseView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Database", subtitle: "SQLite WAL database, FTS5 index, and canonical tables.") {
            InfoGrid(rows: model.tableCounts().map { ($0.0, "\($0.1)") })
        }
    }
}
