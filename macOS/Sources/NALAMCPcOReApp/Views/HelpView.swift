import SwiftUI

enum HelpTopic: String, CaseIterable, Identifiable {
    case quickStart = "quick-start"
    case connectCodex = "connect-codex"
    case connectGemini = "connect-gemini"
    case connectAntigravity = "connect-antigravity"
    case backupRestore = "backup-restore"
    case dumps
    case labs
    case troubleshooting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickStart: "Quick Start"
        case .connectCodex: "Connect Codex"
        case .connectGemini: "Connect Gemini CLI"
        case .connectAntigravity: "Connect Antigravity"
        case .backupRestore: "Backup / Restore"
        case .dumps: "Dumps"
        case .labs: "Labs"
        case .troubleshooting: "Troubleshooting"
        }
    }
}

struct HelpView: View {
    @State private var selection: HelpTopic? = .quickStart

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(HelpTopic.allCases) { topic in
                    Text(topic.title)
                        .tag(topic)
                }
            }
            .navigationTitle("Help")
        } detail: {
            ScrollView {
                Text(load(selection ?? .quickStart))
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
            .navigationTitle(selection?.title ?? "Help")
        }
    }

    private func load(_ topic: HelpTopic) -> String {
        guard let url = Bundle.module.url(forResource: topic.rawValue, withExtension: "md", subdirectory: "Help"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Help topic not available."
        }
        return text
    }
}
