import AppKit
import NALAMCPcOReCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct NALAMCPcOReApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()
    @Environment(\.openWindow) private var openWindow
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    var body: some Scene {
        WindowGroup(NALAConstants.appName) {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 620)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Open Vault Folder") {
                    model.openVaultFolder()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .disabled(model.core == nil)
            }
            CommandGroup(replacing: .help) {
                Button("NALA-MCP-cORe Help") {
                    openWindow(id: "nala-help")
                }
                .keyboardShortcut("/", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(model)
                .frame(width: 520)
        }

        Window("NALA-MCP-cORe Help", id: "nala-help") {
            HelpView()
                .frame(minWidth: 760, minHeight: 560)
        }

        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarStatusView()
                .environmentObject(model)
        } label: {
            Label("NALA", systemImage: model.menuBarState().symbolName)
        }
    }
}

private extension MenuBarVisualState {
    var symbolName: String {
        switch self {
        case .healthy: "checkmark.circle"
        case .warning: "exclamationmark.circle"
        case .error: "xmark.octagon"
        case .stopped: "circle"
        case .active: "bolt.circle"
        }
    }
}
