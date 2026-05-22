import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if model.core == nil {
            FirstLaunchVaultPicker()
        } else {
            MainContentView()
        }
    }
}

struct FirstLaunchVaultPicker: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 18) {
                AppIconView(size: 92)
                VStack(alignment: .leading, spacing: 6) {
                    Text("NALA-MCP-cORe")
                        .font(.largeTitle.bold())
                    Text("Choose where the local memory vault lives.")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Button("Use Recommended App Support Folder") {
                    model.useDefaultVault()
                }
                .keyboardShortcut(.defaultAction)

                Button("Choose Custom Vault Folder") {
                    model.chooseCustomVault()
                }

                Text(model.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(42)
    }
}

struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
        } else {
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.system(size: size * 0.55))
                .frame(width: size, height: size)
        }
    }
}
