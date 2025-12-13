# Claude Code Changelog

This is the complete changelog for Claude Code, documenting updates from version 0.2.21 through 2.0.69.

## Key Highlights

**Latest (2.0.69):** "Minor bugfixes"

**Recent Major Features:**
- Native VS Code extension with fresh UI redesign
- Plan mode with new Plan subagent for more precise planning
- Thinking mode enabled by default for Opus 4.5
- Claude Code for Desktop application
- Plugin system for extending functionality
- Background agent support for concurrent work
- MCP (Model Context Protocol) server integration
- Custom agents, slash commands, and skills support

**Core Capabilities Added Over Time:**
- "Web search now takes today's date into context"
- Real-time message steering while Claude works
- Conversation resumption and history navigation
- Todo list integration for task organization
- File @-mentions and context management
- Vim mode keybindings
- Image pasting from clipboard
- Bash command execution with permissions management

## Download & Documentation

Users can access Claude Code at https://code.claude.com and https://claude.com/download for desktop versions.

---

## Version History (Highlights)

### 2.0.68
- IME support: composition window now positions correctly at cursor for CJK languages
- Enterprise managed settings support
- Plan mode UX improvements

### 2.0.67
- Non-Latin text word navigation (Cyrillic, Greek, Arabic, Hebrew, Thai, Chinese)
- Consecutive @~/ file reference parsing in CLAUDE.md

### 2.0.64
- Named sessions: /rename, /resume commands
- Auto-compacting made instant
- .claude/rules/ directory support for memory rules
- Skills frontmatter field for auto-loading subagent skills

### 2.0.59+
- --agent CLI flag to override agent settings
- SubAgents can dynamically choose their model
- SubAgents can resume other subagents
- Background agent support

### 2.0.45
- PermissionRequest hooks for auto-approving/denying tool permissions

### 2.0.43
- SubagentStart hook event

### 2.0.41
- prompt-based stop hooks with custom model support

### 2.0.30+
- MCP structuredContent field support
- SSE MCP servers enabled on native builds
- Enterprise managed MCP allowlist/denylist support
