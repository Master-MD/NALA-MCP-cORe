using System.Windows;

namespace NALAMCPcOReWIN;

public partial class MainWindow : Window
{
    private CoreLogic _coreLogic;

    public MainWindow()
    {
        InitializeComponent();
        _coreLogic = new CoreLogic();
        ApplyTranslations();
        LogMessage(Translation.AppStarted);
    }

    private void ApplyTranslations()
    {
        this.Title = Translation.Title;
        TitleTextBlock.Text = Translation.Title;
        DashboardTab.Header = Translation.TabDashboard;
        LogsTab.Header = Translation.TabLogs;
        StatusHeaderTextBlock.Text = Translation.SystemStatus;
        VaultStatusText.Text = Translation.VaultNotSelected;
        SelectVaultButton.Content = Translation.SelectVaultButton;
        StatusTextBlock.Text = Translation.StatusReady;
    }

    private void SelectVault_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog();
        dialog.Title = Translation.SelectVaultTitle;
        
        if (dialog.ShowDialog() == true)
        {
            string path = dialog.FolderName;
            VaultStatusText.Text = $"{Translation.VaultInitialized} {path}";
            _coreLogic.InitializeVault(path);
            LogMessage($"{Translation.VaultInitialized} {path}");
        }
    }

    public void LogMessage(string message)
    {
        string time = System.DateTime.Now.ToString("HH:mm:ss");
        LogsTextBox.AppendText($"[{time}] {message}\n");
        LogsTextBox.ScrollToEnd();
    }
}
