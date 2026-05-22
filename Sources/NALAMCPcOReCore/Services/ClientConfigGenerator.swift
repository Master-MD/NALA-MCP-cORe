import Foundation

public final class ClientConfigGenerator {
    private let vaultURL: URL
    private let stableHelperURL: URL

    public init(vaultURL: URL, stableHelperURL: URL) {
        self.vaultURL = vaultURL
        self.stableHelperURL = stableHelperURL
    }

    public func configs(projectRoot: URL) -> ClientConfigBundle {
        let helper = stableHelperURL.path
        let vault = vaultURL.path
        let cwd = projectRoot.path

        let codex = """
        [mcp_servers.nala_mcp_core]
        enabled = true
        command = "\(helper)"
        args = []
        cwd = "\(cwd)"
        startup_timeout_sec = 10
        tool_timeout_sec = 60
        default_tools_approval_mode = "prompt"

        [mcp_servers.nala_mcp_core.env]
        NALA_MCP_CORE_VAULT = "\(vault)"
        """

        let gemini = """
        {
          "mcpServers": {
            "nala-mcp-core": {
              "command": "\(helper)",
              "args": [],
              "env": {
                "NALA_MCP_CORE_VAULT": "\(vault)"
              },
              "cwd": "\(cwd)"
            }
          }
        }
        """

        let antigravity = """
        {
          "mcpServers": {
            "NALA-MCP-cORe": {
              "command": "\(helper)",
              "args": [],
              "env": {
                "NALA_MCP_CORE_VAULT": "\(vault)"
              },
              "cwd": "\(cwd)"
            }
          }
        }
        """

        let manual = """
        Name:
        NALA-MCP-cORe

        Transport:
        STDIO

        Command:
        \(helper)

        Arguments:
        empty

        Environment:
        NALA_MCP_CORE_VAULT=\(vault)

        Working directory:
        \(cwd)
        """

        let rules = """
        ## NALA-MCP-cORe Rule

        When working on NALA projects, first check the local NALA-MCP-cORe MCP server for existing project context, decisions, bugs, prompts and session summaries.

        Use:
        - health_check
        - list_projects
        - search_context
        - get_project_brief

        Do not overwrite or delete NALA-MCP-cORe data.
        Prefer adding session summaries, bug reports and decision candidates.
        """

        return ClientConfigBundle(codexTOML: codex, geminiJSON: gemini, antigravityJSON: antigravity, manualSTDIO: manual, ruleSnippet: rules)
    }
}
