# Jira MCP Tools Reference

Tool names and server identifiers vary by Jira MCP implementation. Use the tool names as exposed by the configured server. When the server name is known, reference tools with fully qualified names: `ServerName:tool_name`.

## Common Operations

- **Create issue:** Create an epic, story, or task (summary, description, issue type, optional project key, epic link, story points, labels, etc.).
- **Update issue:** Update an existing issue (fields, status, assignee, etc.).
- **Search issues:** Query issues with JQL (Jira Query Language); results often capped (e.g. 50 per request).

Implementations may also support: add comment, attach file, get epic children, transition issue.

## Server Variants

- **Atlassian Rovo MCP Server** – Cloud-only; OAuth 2.1. Jira Cloud (and Confluence, Compass). [atlassian/atlassian-mcp-server](https://github.com/atlassian/atlassian-mcp-server).
- **Community servers** – Often support Jira Cloud and Jira Server/Data Center, e.g. [cfdude/mcp-jira](https://github.com/cfdude/mcp-jira), [cosmix/jira-mcp](https://github.com/cosmix/jira-mcp). Typically use env vars such as `JIRA_BASE_URL`, `JIRA_API_TOKEN`, `JIRA_USER_EMAIL`.

## When in Doubt

- Prefer the tool names exposed by the configured Jira MCP server (e.g. list tools or check the server’s documentation).
- Use the project key from current context or config when creating issues.
