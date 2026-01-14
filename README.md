# OpenCode AI Context Dispatcher

A shell-based context management system for AI coding agents. Automatically indexes your codebase and provides relevant context to AI assistants.

## Features

- Automatic project context indexing and tracking
- Code structure extraction (functions, classes, methods)
- Git-aware incremental updates
- Agent-specific context storage and retrieval
- Cross-platform support (Linux/macOS)

## Installation

```bash
git clone https://github.com/deceptikon/opencode-ai-context-dispatcher.git
cd opencode-ai-context-dispatcher
./install-context-dispatcher.sh
```

Restart your shell or run:
```bash
source ~/.zshrc
```

### Dependencies

Automatically installed if missing:
- `jq` - JSON processing
- `ripgrep` (`rg`) - Fast content searching

## Usage

### Initialize a project

```bash
ctx init /path/to/project "Project Name"
```

This creates a project ID (hash) that you'll use for other commands.

### Index/Reindex a project

```bash
# Full reindex
ctx reindex <project_id>

# Incremental update (git changes only)
ctx update <project_id>
```

### List managed projects

```bash
ctx list
```

### View project statistics

```bash
ctx stats <project_id>
```

### Get context for a project

```bash
# Get recent context
ctx get <project_id>

# Search context
ctx get <project_id> "search query"
```

### Run opencode with context

```bash
ocx <project_id> "your prompt here"
```

### Agent context management

```bash
# Save agent-specific context
ctx save-agent <agent_name> "context text" [tags]

# Search agent context
ctx search-agent <agent_name> "query"
```

### Cleanup old context

```bash
ctx cleanup [days]  # default: 30 days
```

## Uninstallation

```bash
./uninstall-context-dispatcher.sh
```

## File Structure

```
~/.opencode/
├── context-dispatcher.zsh    # Main dispatcher script
├── context/
│   ├── projects/             # Per-project context
│   │   └── <project_id>/
│   │       ├── config.json   # Project configuration
│   │       └── index.json    # Indexed code chunks
│   ├── agents/               # Agent-specific context logs
│   ├── cache/                # Shared context cache
│   └── logs/                 # System logs
```

## Sample Agent Prompt

You can use this prompt to instruct an AI agent about the context system:

```
You have access to a project context system. The current project context has been 
loaded and contains indexed code structures from the codebase.

Available context commands (via shell):
- `ctx get <project_id>` - Get relevant code context
- `ctx get <project_id> "query"` - Search for specific code patterns
- `ctx stats <project_id>` - View project statistics

The context includes:
- Function and class definitions
- Import/export statements  
- Recent code changes (git-tracked)

Use this context to understand the codebase structure before making changes.
When referencing code, verify against the actual files as context may be summarized.
```

## Configuration

Project configuration is stored in `~/.opencode/context/projects/<id>/config.json`:

```json
{
    "name": "Project Name",
    "path": "/path/to/project",
    "exclude_patterns": ["node_modules", ".git", "dist", "build"],
    "include_extensions": [".js", ".ts", ".py", ".rs", ...],
    "chunk_size": 2000,
    "max_files": 1000
}
```

## Troubleshooting

### Commands not found after sourcing

If `jq` or other commands fail inside functions, the script caches command paths at load time. Re-source the script:

```bash
source ~/.opencode/context-dispatcher.zsh
```

### Index is empty after reindex

Check that your project path exists and contains matching file extensions. View the config:

```bash
cat ~/.opencode/context/projects/<project_id>/config.json
```

### Character encoding errors

The script uses `LC_ALL=C` for grep operations to handle non-ASCII content. If you still see errors, they're usually non-fatal warnings.

## License

MIT
