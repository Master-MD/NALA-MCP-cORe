# CODEX MONOREPO INSTRUCTIONS

> [!IMPORTANT]
> **Dear Codex (or any other AI Coding Assistant), please read these instructions carefully before performing any operations on this repository!**

This repository has been restructured into a **Monorepo** to cleanly support both macOS (SwiftUI) and Windows (C# WPF) native applications without conflicts.

## Directory Layout

- `/macOS` - This is your **sole work environment** for the Mac application.
  - Contains `Package.swift`, `Sources/`, `Tests/`, and all macOS-specific scripts (`script/`).
- `/Windows` - Contains the native Windows C# WPF application. **Do not modify anything inside this folder unless specifically instructed!**
- `/.github/workflows` - Contains the automated CI/CD workflows for GitHub Actions (building DMG and ZIP binaries).

## Crucial Safety Guidelines

1. **Scope Restriction:** When editing macOS features, ONLY modify files inside the `/macOS` directory.
2. **Path Safety:** Never assume that the repository root is the Swift package root. The Swift package root is located inside the `/macOS` directory.
3. **No Structure Destructions:** Do not move, rename, or delete the `/macOS` or `/Windows` folders. 
4. **Git Safety:** Always preserve the monorepo structure when staging or committing changes.

Thank you for keeping this repository clean and stable for all platforms!
