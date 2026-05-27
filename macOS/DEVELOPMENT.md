# Development

## Requirements

- macOS
- Xcode command line tools
- Swift 6.3 or newer

## Commands

```bash
swift test
swift build
./script/build_and_run.sh --verify
```

Default packaging is side-by-side:

```text
dist/NALA-MCP-cORe-UIStatsPreview.app
```

This avoids replacing a running `dist/NALA-MCP-cORe.app`.

Explicit original-name packaging:

```bash
./script/build_and_run.sh --stable
```

## Structure

```text
Sources/NALAMCPcOReCore/      Stable Core library
Sources/NALAMCPcOReApp/       SwiftUI macOS app
Sources/NALAMCPcOReHelper/    Local helper executable
Tests/NALAMCPcOReCoreTests/   XCTest coverage
script/build_and_run.sh       Build, package, launch
```

## App Bundle

The run script stages:

```text
dist/NALA-MCP-cORe.app
```

It embeds `Sources/NALAMCPcOReApp/Resources/AppIcon.png` as `AppIcon.icns`.

## v0.2 Upgrade Preflight

`UpgradePreflightManager` checks v0.1 vault candidates, verifies expected database/event files, reports active clients, and blocks final migration while clients or the old helper appear active.
