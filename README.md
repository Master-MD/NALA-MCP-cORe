<p align="center">
  <img src="macOS/Sources/NALAMCPcOReApp/Resources/AppIcon.png" alt="NALA MCP cORe Icon" width="128" height="128">
</p>

<h1 align="center">NALA-MCP-cORe</h1>

<p align="center">
  <strong>Native macOS & Windows Control Center for local-only MCP memory and SQLite database vaults.</strong>
</p>

<p align="center">
  <a href="README.de.md">Deutsch</a> • 
  <a href="README.fr.md">Français</a> • 
  <a href="README.it.md">Italiano</a>
</p>

---

## 🚀 Easy Download & Installation (For End Users)

You do **NOT** need to compile this app or write code to use it! 

1. Go to the **[Releases](https://github.com/Master-MD/NALA-MCP-cORe/releases)** section on the right side of this GitHub page.
2. Download the package for your operating system:
   - **macOS:** Download the `.dmg` file (supports both Apple Silicon/ARM and Intel Macs).
   - **Windows:** Download the `.zip` or `.exe` file (supports both Intel/AMD x64 and ARM64).
3. Open the downloaded file, drag & drop (macOS) or extract and run the `.exe` (Windows), and choose your local vault folder.

---

## 💡 What It Does & The Idea Behind It

**NALA-MCP-cORe** is a local-only central vault that acts as the "brain" or memory core for AI clients like Codex, Gemini CLI, Google Antigravity, and future NALA workflows. It stores project memories, decisions, bug reports, and sessions securely in a local SQLite vault.

### Core Features:
- **Zero-Cloud & 100% Local:** Your data never leaves your computer. No accounts, no APIs, no server keys required.
- **Cross-Platform:** Native macOS app written in SwiftUI & Native Windows app written in C#/WPF.
- **Smart FTS5 Indexing:** Ultra-fast context searching using SQLite full-text search.
- **JSONL Event Journal:** An append-only log of all events for complete transparency and future audit trails.
- **Auto-i18n:** Detects your operating system's language automatically (English, German, French, Italian).
- **Unknown Client Blocking:** Rejects connections and modifications from unrecognized tools.

---

## 📸 In-App Screenshots

### macOS App
*Beautiful dark mode native macOS Control Center showing CPU, RAM, active clients, and connection wizards.*
<p align="center">
  <img src="macOS/Sources/NALAMCPcOReApp/Resources/AppIcon.png" alt="macOS Screenshot Placeholder" width="400">
</p>

### Windows App
*Native WPF dashboard on Windows showing status, vault picker, and real-time logs.*
<p align="center">
  <img src="macOS/Sources/NALAMCPcOReApp/Resources/AppIcon.png" alt="Windows Screenshot Placeholder" width="400">
</p>

---

## ❓ FAQ (Frequently Asked Questions)

### Q: Where is my data stored?
Your data is stored completely locally in a folder you choose during the first launch (e.g. `~/Library/Application Support/NALA-MCP-cORe/` on Mac or `C:\Users\<Name>\AppData\Local\NALA-MCP-cORe\` on Windows).

### Q: Can I use it with cloud-synced folders?
Yes! The Vault picker supports folders synced via iCloud Drive, Google Drive Desktop, Dropbox, or Synology Drive.

### Q: Why is my connection denied?
By default, the core uses strict permission policies. Unknown clients or destructive tools are automatically blocked to keep your database safe.

---

## 🛠️ Monorepo Directory Structure

This repository is structured as a Monorepo:
- `/macOS`: Contains the native macOS SwiftUI app bundle and target files.
- `/Windows`: Contains the native Windows C# WPF app.
- `/.github/workflows`: Contains the automated CI/CD pipelines.

---

## 🏗️ Developer Section (How to Compile)

### macOS (Swift)
```bash
cd macOS
swift test
./script/build_and_run.sh --stable
```

### Windows (.NET 8.0)
```cmd
cd Windows
dotnet build src/NALAMCPcOReWIN/NALAMCPcOReWIN.csproj -c Release
dotnet run --project src/NALAMCPcOReWIN/NALAMCPcOReWIN.csproj
```
