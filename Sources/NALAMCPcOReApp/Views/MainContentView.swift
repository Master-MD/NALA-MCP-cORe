import NALAMCPcOReCore
import SwiftUI

enum SidebarDestination: String, CaseIterable, Identifiable {
    case status
    case search
    case projects
    case mcpClients
    case permissions
    case database
    case backups
    case restore
    case dumps
    case logs
    case health
    case deepStats
    case flowMonitor
    case settings
    case labsOverview
    case importLab
    case exportLab
    case mongoDBExportLab
    case chromaDBExportLab
    case memPalaceExportLab
    case doclingRAGExportLab
    case nalaBrainSyncLab
    case sshSyncLab
    case cloudFolderExportLab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .status: "Status"
        case .search: "Search"
        case .projects: "Projects"
        case .mcpClients: "MCP Clients"
        case .permissions: "Permissions"
        case .database: "Database"
        case .backups: "Backups"
        case .restore: "Restore"
        case .dumps: "Dumps"
        case .logs: "Logs"
        case .health: "Health"
        case .deepStats: "Deep Stats"
        case .flowMonitor: "Flow Monitor"
        case .settings: "Settings"
        case .labsOverview: "Labs Overview"
        case .importLab: "Import Lab"
        case .exportLab: "Export Lab"
        case .mongoDBExportLab: "MongoDB Export Lab"
        case .chromaDBExportLab: "ChromaDB Export Lab"
        case .memPalaceExportLab: "MemPalace Export Lab"
        case .doclingRAGExportLab: "Docling/RAG Export Lab"
        case .nalaBrainSyncLab: "NALA-bRaiN Sync Lab"
        case .sshSyncLab: "SSH Sync Lab"
        case .cloudFolderExportLab: "Cloud Folder Export Lab"
        }
    }

    var symbol: String {
        switch self {
        case .status: "dot.radiowaves.left.and.right"
        case .search: "magnifyingglass"
        case .projects: "folder"
        case .mcpClients: "terminal"
        case .permissions: "lock.shield"
        case .database: "cylinder.split.1x2"
        case .backups: "externaldrive.badge.timemachine"
        case .restore: "arrow.counterclockwise"
        case .dumps: "square.and.arrow.up"
        case .logs: "doc.text.magnifyingglass"
        case .health: "heart.text.square"
        case .deepStats: "chart.xyaxis.line"
        case .flowMonitor: "point.3.connected.trianglepath.dotted"
        case .settings: "gearshape"
        case .labsOverview: "flask"
        case .importLab: "tray.and.arrow.down"
        case .exportLab: "tray.and.arrow.up"
        case .mongoDBExportLab: "shippingbox"
        case .chromaDBExportLab: "square.grid.3x3"
        case .memPalaceExportLab: "building.columns"
        case .doclingRAGExportLab: "doc.richtext"
        case .nalaBrainSyncLab: "brain"
        case .sshSyncLab: "network"
        case .cloudFolderExportLab: "folder.badge.gearshape"
        }
    }

    static let stableCore: [SidebarDestination] = [
        .status, .search, .projects, .mcpClients, .permissions, .database,
        .backups, .restore, .dumps, .logs, .health, .deepStats, .flowMonitor, .settings
    ]

    static let labs: [SidebarDestination] = [
        .labsOverview, .importLab, .exportLab, .mongoDBExportLab, .chromaDBExportLab,
        .memPalaceExportLab, .doclingRAGExportLab, .nalaBrainSyncLab, .sshSyncLab, .cloudFolderExportLab
    ]
}

struct MainContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: SidebarDestination? = .status

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Stable Core") {
                    ForEach(SidebarDestination.stableCore) { item in
                        Label(item.title, systemImage: item.symbol)
                            .tag(item)
                    }
                }

                Section("Experimental Labs") {
                    ForEach(SidebarDestination.labs) { item in
                        Label(item.title, systemImage: item.symbol)
                            .tag(item)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("NALA")
        } detail: {
            DetailRouter(selection: selection ?? .status)
                .environmentObject(model)
        }
    }
}

struct DetailRouter: View {
    @EnvironmentObject private var model: AppModel
    let selection: SidebarDestination

    var body: some View {
        Group {
            switch selection {
            case .status: StatusView()
            case .search: SearchView()
            case .projects: ManualEntryView()
            case .mcpClients: MCPClientsView()
            case .permissions: PermissionsView()
            case .database: DatabaseView()
            case .backups: BackupsView()
            case .restore: RestoreView()
            case .dumps: DumpsView()
            case .logs: LogsView()
            case .health: HealthView()
            case .deepStats: DeepStatsView()
            case .flowMonitor: FlowMonitorView()
            case .settings: SettingsView()
            case .labsOverview: LabsOverviewView()
            default: PlannedLabView(title: selection.title)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text(model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(model.statusMessage)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}

struct ScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title.bold())
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .navigationTitle(title)
    }
}

struct AdaptiveCardGrid<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 520), spacing: 14)], alignment: .leading, spacing: 14) {
            content
        }
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content
                .font(.callout)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct InfoGrid: View {
    let rows: [(String, String)]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
            ForEach(rows, id: \.0) { label, value in
                GridRow {
                    Text(label)
                        .foregroundStyle(.secondary)
                    Text(value.isEmpty ? "none" : value)
                        .textSelection(.enabled)
                }
            }
        }
    }
}
