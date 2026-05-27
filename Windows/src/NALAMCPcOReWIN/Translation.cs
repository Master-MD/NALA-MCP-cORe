using System.Globalization;

namespace NALAMCPcOReWIN;

public static class Translation
{
    private static string _currentLanguage = "en";

    static Translation()
    {
        var culture = CultureInfo.CurrentCulture.TwoLetterISOLanguageName;
        if (culture == "de" || culture == "fr" || culture == "it")
        {
            _currentLanguage = culture;
        }
        else
        {
            _currentLanguage = "en"; // default
        }
    }

    public static string Title => _currentLanguage switch
    {
        "de" => "NALA-MCP-cORe Kontrollzentrum",
        "fr" => "Centre de contrôle NALA-MCP-cORe",
        "it" => "Centro di controllo NALA-MCP-cORe",
        _ => "NALA-MCP-cORe Control Center"
    };

    public static string SystemStatus => _currentLanguage switch
    {
        "de" => "Systemstatus",
        "fr" => "État du système",
        "it" => "Stato del sistema",
        _ => "System Status"
    };

    public static string VaultNotSelected => _currentLanguage switch
    {
        "de" => "Tresor: Nicht ausgewählt",
        "fr" => "Coffre: Non sélectionné",
        "it" => "Caveau: Non selezionato",
        _ => "Vault: Not Selected"
    };

    public static string SelectVaultButton => _currentLanguage switch
    {
        "de" => "Tresor-Pfad wählen...",
        "fr" => "Choisir le chemin...",
        "it" => "Scegli il percorso...",
        _ => "Select Vault Location..."
    };

    public static string SelectVaultTitle => _currentLanguage switch
    {
        "de" => "Tresor-Ordner auswählen",
        "fr" => "Sélectionner le dossier du coffre",
        "it" => "Seleziona la cartella del caveau",
        _ => "Select Vault Folder"
    };

    public static string TabDashboard => _currentLanguage switch
    {
        "de" => "Dashboard",
        "fr" => "Tableau de bord",
        "it" => "Pannello",
        _ => "Dashboard"
    };

    public static string TabLogs => _currentLanguage switch
    {
        "de" => "Protokolle (Logs)",
        "fr" => "Journaux (Logs)",
        "it" => "Registri (Logs)",
        _ => "Logs"
    };
    
    public static string StatusReady => _currentLanguage switch
    {
        "de" => "Bereit",
        "fr" => "Prêt",
        "it" => "Pronto",
        _ => "Ready"
    };

    public static string AppStarted => _currentLanguage switch
    {
        "de" => "Anwendung gestartet.",
        "fr" => "Application démarrée.",
        "it" => "Applicazione avviata.",
        _ => "Application started."
    };

    public static string VaultInitialized => _currentLanguage switch
    {
        "de" => "Tresor initialisiert unter: ",
        "fr" => "Coffre initialisé sous: ",
        "it" => "Caveau inizializzato sotto: ",
        _ => "Vault initialized at: "
    };
}
