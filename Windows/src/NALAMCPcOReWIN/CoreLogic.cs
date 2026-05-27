using System;
using System.IO;
using Microsoft.Data.Sqlite;

namespace NALAMCPcOReWIN;

public class CoreLogic
{
    private string _vaultPath = string.Empty;
    private string _dbPath = string.Empty;
    private string _journalPath = string.Empty;

    public void InitializeVault(string vaultPath)
    {
        _vaultPath = vaultPath;
        _dbPath = Path.Combine(_vaultPath, "nala-mcp-core.sqlite");
        _journalPath = Path.Combine(_vaultPath, "events.jsonl");

        if (!Directory.Exists(_vaultPath))
        {
            Directory.CreateDirectory(_vaultPath);
        }

        using (var connection = new SqliteConnection($"Data Source={_dbPath}"))
        {
            connection.Open();

            // Enable WAL mode
            using (var walCommand = connection.CreateCommand())
            {
                walCommand.CommandText = "PRAGMA journal_mode=WAL;";
                walCommand.ExecuteNonQuery();
            }

            // Create initial tables
            using (var initCommand = connection.CreateCommand())
            {
                initCommand.CommandText = @"
                    CREATE TABLE IF NOT EXISTS projects (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        created_at TEXT NOT NULL
                    );
                    
                    CREATE TABLE IF NOT EXISTS memories (
                        id TEXT PRIMARY KEY,
                        project_id TEXT,
                        content TEXT,
                        created_at TEXT NOT NULL,
                        FOREIGN KEY(project_id) REFERENCES projects(id)
                    );
                ";
                initCommand.ExecuteNonQuery();
            }
        }

        // Initialize JSONL journal if not exists
        if (!File.Exists(_journalPath))
        {
            File.WriteAllText(_journalPath, "{\"event\":\"vault_created\",\"timestamp\":\"" + DateTime.UtcNow.ToString("o") + "\"}\n");
        }
    }
    
    public void AppendEvent(string jsonEvent)
    {
        if (string.IsNullOrEmpty(_journalPath)) return;
        File.AppendAllText(_journalPath, jsonEvent + "\n");
    }
}
