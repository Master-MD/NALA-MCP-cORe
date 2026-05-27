<p align="center">
  <img src="macOS/Sources/NALAMCPcOReApp/Resources/AppIcon.png" alt="NALA MCP cORe Icon" width="128" height="128">
</p>

<h1 align="center">NALA-MCP-cORe (Français)</h1>

<p align="center">
  <strong>Centre de contrôle natif macOS & Windows pour les bases de données SQLite et les cœurs de mémoire MCP 100% locaux.</strong>
</p>

<p align="center">
  <a href="README.md">English</a> • 
  <a href="README.de.md">Deutsch</a> • 
  <a href="README.it.md">Italiano</a>
</p>

---

## 🚀 Téléchargement & Installation Facile (Pour les utilisateurs finaux)

Vous n'avez **PAS** besoin de compiler cette application ou d'écrire du code pour l'utiliser !

1. Allez dans la section **[Releases](https://github.com/Master-MD/NALA-MCP-cORe/releases)** sur la droite de cette page GitHub.
2. Téléchargez le fichier adapté à votre système :
   - **macOS :** Téléchargez le fichier `.dmg` (supporte les processeurs Intel et Apple Silicon/ARM).
   - **Windows :** Téléchargez le fichier `.zip` ou `.exe` (supporte Intel/AMD x64 et ARM64).
3. Ouvrez le fichier téléchargé, glissez-déposez l'application (macOS) ou extrayez et lancez le `.exe` (Windows), puis sélectionnez votre dossier de coffre local.

---

## 💡 Qu'est-ce que c'est & L'idée générale

**NALA-MCP-cORe** est un coffre-fort local sécurisé servant de "cerveau" ou de cœur de mémoire pour les clients d'intelligence artificielle comme Codex, Gemini CLI, Google Antigravity, et les futurs flux de travail NALA. Il stocke vos données de projet, décisions, rapports de bogues et sessions de manière sécurisée dans une base de données SQLite locale.

### Fonctionnalités Clés :
- **Zéro-Cloud & 100% Local :** Vos données ne quittent jamais votre ordinateur. Aucun compte, aucune API, aucune clé cloud requis.
- **Multiplateforme :** Application macOS native écrite en SwiftUI et application Windows native écrite en C#/WPF.
- **Indexation FTS5 Intelligente :** Recherche textuelle ultra-rapide directement dans la base de données.
- **Journal d'Événements JSONL :** Un journal infalsifiable de tous les événements pour une transparence totale.
- **Langue du Système Automatique :** Détecte automatiquement la langue de votre système (Français, Anglais, Allemand, Italien).
- **Protection des Accès :** Bloque automatiquement les programmes inconnus ou les commandes destructrices.

---

## ❓ FAQ (Foire Aux Questions)

### Q : Où mes données sont-elles stockées ?
Vos données sont stockées localement sur votre disque dur dans le dossier de votre choix (ex: `~/Library/Application Support/NALA-MCP-cORe/` sur Mac ou `C:\Users\<Nom>\AppData\Local\NALA-MCP-cORe\` sur Windows).

### Q : Puis-je utiliser des dossiers synchronisés avec le cloud ?
Oui ! L'application prend en charge les dossiers synchronisés via iCloud Drive, Google Drive Desktop, Dropbox ou Synology Drive.

---

## 🛠️ Structure du Monorepo

- `/macOS` : Application SwiftUI native pour macOS.
- `/Windows` : Application C# WPF native pour Windows.
- `/.github/workflows` : Pipelines de build automatique CI/CD.
