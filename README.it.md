<p align="center">
  <img src="macOS/Sources/NALAMCPcOReApp/Resources/AppIcon.png" alt="NALA MCP cORe Icon" width="128" height="128">
</p>

<h1 align="center">NALA-MCP-cORe (Italiano)</h1>

<p align="center">
  <strong>Centro di controllo nativo macOS & Windows per caveau di memoria MCP e database SQLite 100% locali.</strong>
</p>

<p align="center">
  <a href="README.md">English</a> • 
  <a href="README.de.md">Deutsch</a> • 
  <a href="README.fr.md">Français</a>
</p>

---

## 🚀 Download & Installazione Semplice (Per gli utenti finali)

**NON** è necessario compilare questa applicazione o scrivere codice per utilizzarla!

1. Vai alla sezione **[Releases](https://github.com/Master-MD/NALA-MCP-cORe/releases)** sul lato destro di questa pagina GitHub.
2. Scarica il pacchetto per il tuo sistema operativo:
   - **macOS:** Scarica il file `.dmg` (supporta sia Mac Apple Silicon/ARM che Intel).
   - **Windows:** Scarica il file `.zip` o `.exe` (supporta sia Intel/AMD x64 che ARM64).
3. Apri il file scaricato, trascina l'applicazione (macOS) o estrai ed esegui il file `.exe` (Windows), quindi scegli la cartella locale del tuo caveau.

---

## 💡 Che cos'è & L'idea alla base

**NALA-MCP-cORe** è un caveau locale sicuro che funge da "cervello" o nucleo di memoria per client di intelligenza artificiale come Codex, Gemini CLI, Google Antigravity e futuri flussi di lavoro NALA. Memorizza i dati dei progetti, le decisioni, i rapporti sui bug e le sessioni in un database SQLite locale.

### Caratteristiche Principali:
- **Zero-Cloud & 100% Locale:** I tuoi dati non lasciano mai il computer. Nessun account, nessuna API, nessuna chiave cloud necessaria.
- **Multipiattaforma:** Applicazione macOS nativa scritta in SwiftUI e applicazione Windows nativa scritta in C#/WPF.
- **Indicizzazione FTS5 Intelligente:** Ricerca testuale ultra-rapida direttamente all'interno del database.
- **Registro Eventi JSONL:** Un registro sicuro di tutti gli eventi per una totale trasparenza.
- **Lingua del Sistema Automatica:** Rileva automaticamente la lingua del sistema operativo (Italiano, Inglese, Tedesco, Francese).
- **Protezione degli Accessi:** Blocca automaticamente i programmi sconosciuti o i comandi distruttivi.

---

## ❓ FAQ (Domande Frequenti)

### D: Dove vengono memorizzati i miei dati?
I tuoi dati sono memorizzati localmente sul tuo disco rigido nella cartella scelta (es: `~/Library/Application Support/NALA-MCP-cORe/` su Mac o `C:\Users\<Nome>\AppData\Local\NALA-MCP-cORe\` su Windows).

### D: Posso utilizzare cartelle sincronizzate con il cloud?
Sì! L'applicazione supporta cartelle sincronizzate tramite iCloud Drive, Google Drive Desktop, Dropbox o Synology Drive.

---

## 🛠️ Struttura del Monorepo

- `/macOS`: Applicazione SwiftUI nativa per macOS.
- `/Windows`: Applicazione C# WPF nativa per Windows.
- `/.github/workflows`: Pipeline di build automatico CI/CD.
