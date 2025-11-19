# Supabase MCP Server Setup for Claude Desktop

## Problem
The HTTP-based Supabase MCP server (`https://mcp.supabase.com/mcp`) doesn't work with Claude Desktop. Claude Desktop requires stdio-based MCP servers with a `command` field.

## Solution: Official Supabase MCP Server

Use the official `@supabase/mcp-server-supabase` package via npx.

### Prerequisites

1. **Get Supabase Personal Access Token**
   - Go to https://supabase.com/dashboard/account/tokens
   - Create a new personal access token
   - Copy the token (starts with `sbp_`)

### Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--access-token",
        "YOUR_PERSONAL_ACCESS_TOKEN_HERE"
      ]
    }
  }
}
```

### Alternative: Environment Variable

For better security, use an environment variable:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest"
      ],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "YOUR_PERSONAL_ACCESS_TOKEN_HERE"
      }
    }
  }
}
```

### Verification

1. Save the config file
2. Restart Claude Desktop
3. Look for the Supabase MCP server in the MCP menu
4. Test by asking Claude to list your Supabase projects

## Available Capabilities

The Supabase MCP server provides:

- **Project Management**: Create, list, and manage Supabase projects
- **Database Operations**: Design tables, generate migrations, query data
- **SQL Execution**: Run SQL queries and reports
- **Branch Management**: Manage database branches
- **Logs & Debugging**: Retrieve logs for troubleshooting

## Read-Only Mode

To restrict to read-only operations:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--read-only"
      ],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "YOUR_TOKEN"
      }
    }
  }
}
```

## Current Status

**NOT CONFIGURED** - Requires personal access token from Supabase dashboard.

The HTTP MCP endpoint has been removed from the config. To enable Supabase MCP:

1. Get your personal access token from https://supabase.com/dashboard/account/tokens
2. Add the configuration above to Claude Desktop config
3. Restart Claude Desktop

## Reference

- Official docs: https://supabase.com/docs/guides/self-hosting/enable-mcp
- Package: https://www.npmjs.com/package/@supabase/mcp-server-supabase
