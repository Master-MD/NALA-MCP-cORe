import NALAMCPcOReCore
import SwiftUI

struct ConnectionWizardView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: MCPClientKind = .codex

    var body: some View {
        ScreenContainer(title: "MCP Clients", subtitle: "Connection wizard with real state badges and copy-ready configs.") {
            AdaptiveCardGrid {
                ForEach(model.clientStates()) { state in
                    DashboardCard(title: state.client.rawValue, systemImage: icon(for: state.client)) {
                        HStack {
                            Text(state.state.rawValue.uppercased())
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(state.state.badgeColor.opacity(0.18))
                                .foregroundStyle(state.state.badgeColor)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        Text(state.shortStatus)
                            .foregroundStyle(.secondary)
                        InfoGrid(rows: [
                            ("Last seen", state.lastSeen.map { DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .medium) } ?? "none"),
                            ("Last tool", state.lastTool ?? "none"),
                            ("Permission", state.permission.rawValue)
                        ])
                    }
                }
            }

            Picker("Client", selection: $selection) {
                Text("Codex").tag(MCPClientKind.codex)
                Text("Gemini CLI").tag(MCPClientKind.geminiCLI)
                Text("Google Antigravity").tag(MCPClientKind.googleAntigravity)
                Text("Manual STDIO").tag(MCPClientKind.manual)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 760)

            clientDetail
        }
        .onAppear {
            model.refreshResourceSample()
        }
    }

    private var clientDetail: some View {
        let configs = model.clientConfigs()
        let configText = config(for: selection, configs: configs)
        return VStack(alignment: .leading, spacing: 14) {
            DashboardCard(title: "\(selection.rawValue) Setup", systemImage: icon(for: selection)) {
                InfoGrid(rows: [
                    ("Connection state", model.clientStates().first { $0.client == selection }?.state.rawValue ?? "known"),
                    ("Transport", "STDIO"),
                    ("Build helper", model.buildHelperURL.path),
                    ("Stable helper", model.core?.helperSymlinkManager.stableHelperURL.path ?? "not available"),
                    ("Vault path", model.core?.paths.rootURL.path ?? "not available"),
                    ("Working directory", model.projectRootURL.path),
                    ("Config file", selection.configFileLocation),
                    ("Environment", "NALA_MCP_CORE_VAULT=\(model.core?.paths.rootURL.path ?? "")")
                ])

                ViewThatFits(in: .horizontal) {
                    HStack {
                        wizardButtons(configText: configText)
                    }
                    Menu("Connection Actions", systemImage: "ellipsis.circle") {
                        wizardButtons(configText: configText)
                    }
                }
            }

            if selection == .googleAntigravity {
                Text("Antigravity MCP Tools permission screen only allows or denies tools. It does not register the server. Put the server in ~/.gemini/antigravity/mcp_config.json.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            OutputBox(text: configText, minHeight: 260)
        }
    }

    @ViewBuilder
    private func wizardButtons(configText: String) -> some View {
        Button("Copy Config", systemImage: "doc.on.doc") {
            model.copyToClipboard(configText, message: "Copied \(selection.rawValue) config.")
        }
        Button("Copy Command", systemImage: "terminal") {
            let command = model.core?.helperSymlinkManager.stableHelperURL.path ?? model.buildHelperURL.path
            model.copyToClipboard(command, message: "Copied helper command.")
        }
        Button("Install Symlink", systemImage: "link") {
            model.installHelperSymlink()
        }
        Button("Reveal Helper", systemImage: "folder") {
            model.revealHelper()
        }
        Button("Test health_check", systemImage: "checkmark.circle") {
            model.testHelper(client: selection)
        }
    }

    private func config(for client: MCPClientKind, configs: ClientConfigBundle?) -> String {
        guard let configs else { return "Vault is not initialized." }
        switch client {
        case .codex:
            return configs.codexTOML
        case .geminiCLI:
            return configs.geminiJSON + "\n\nNote: ~/.gemini/GEMINI.md is for rules, not MCP server config.\n\n" + configs.ruleSnippet
        case .googleAntigravity:
            return configs.antigravityJSON
        case .manual:
            return configs.manualSTDIO
        case .nalaBrainFuture:
            return "planned v0.3 sync target"
        }
    }

    private func icon(for client: MCPClientKind) -> String {
        switch client {
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .geminiCLI: "sparkles"
        case .googleAntigravity: "a.circle"
        case .manual: "terminal"
        case .nalaBrainFuture: "brain"
        }
    }
}
