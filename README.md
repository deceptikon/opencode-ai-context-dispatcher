# OpenCode AI Context Dispatcher

A shell-based context management system for AI coding agents. Automatically indexes your codebase and provides relevant context to AI assistants.

## Features

- Automatic project context indexing and tracking
- Code structure extraction (functions, classes, methods)
- Git-aware incremental updates
- **Manual documentation support** (rules, docs, notes, prompts)
- Agent-specific context storage and retrieval
- Cross-platform support (Linux/macOS)
- **Optional: ChromaDB + LlamaIndex integration for semantic search**

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

## Quick Start

```bash
# 1. Initialize a project
ctx init /path/to/project "My Project"
# Returns: <project_id>

# 2. Index the codebase
ctx reindex <project_id>

# 3. Add business rules/docs
ctx add-doc <project_id> rule "Always use TypeScript strict mode" "TS Strict"
ctx add-doc <project_id> doc "API uses REST with JSON responses" "API Docs"

# 4. Get full context for AI
ctx get-full <project_id>
```

## Usage

### Project Management

```bash
ctx init <path> [name]      # Initialize a new project
ctx update <project_id>     # Incremental update (git changes)
ctx reindex <project_id>    # Full reindex
ctx list                    # List all projects
ctx stats <project_id>      # Show statistics
```

### Context Retrieval

```bash
ctx get <project_id>              # Get code context
ctx get <project_id> "query"      # Search code context
ctx get-full <project_id>         # Get everything (code + docs + rules)
```

### Documentation & Rules

Add business logic, rules, documentation, and custom prompts:

```bash
# Add inline content
ctx add-doc <project_id> <type> "content" [title]

# Types: rule, doc, note, prompt
ctx add-doc abc123 rule "All API endpoints must validate input" "Input Validation"
ctx add-doc abc123 doc "The auth system uses JWT tokens" "Auth Overview"
ctx add-doc abc123 note "TODO: Refactor the user service" "Refactor Note"
ctx add-doc abc123 prompt "You are a senior developer..." "System Prompt"

# Add from file (great for longer docs)
ctx add-file <project_id> <type> <file_path> [title]
ctx add-file abc123 doc ./docs/architecture.md "Architecture"
ctx add-file abc123 rule ./CODING_STANDARDS.md "Coding Standards"

# Manage documents
ctx list-docs <project_id>           # List all docs
ctx list-docs <project_id> rule      # List only rules
ctx get-docs <project_id>            # Get all doc contents
ctx get-docs <project_id> rule       # Get only rules
ctx edit-doc <project_id> <doc_id>   # Edit in $EDITOR
ctx rm-doc <project_id> <doc_id>     # Remove a doc
```

### Agent Context

```bash
ctx save-agent <name> <text> [tags]  # Save agent-specific context
ctx search-agent <name> [query]      # Search agent context
```

### Run OpenCode with Context

```bash
ocx <project_id> "your prompt here"
```

### Maintenance

```bash
ctx cleanup [days]    # Remove old context (default: 30 days)
ctx help              # Show all commands
```

## Uninstallation

```bash
./uninstall-context-dispatcher.sh
```

## Vector Search Extension (ChromaDB + LlamaIndex)

For semantic search capabilities, use the Python extension:

### Setup

```bash
pip install chromadb llama-index llama-index-vector-stores-chroma
```

### Usage

```bash
# Index project into ChromaDB
python extensions/vector_store.py index <project_id>

# Semantic search
python extensions/vector_store.py search <project_id> "how does auth work"

# Search with LlamaIndex (better answers)
python extensions/vector_store.py search-llama <project_id> "explain the API structure"

# Get stats
python extensions/vector_store.py stats <project_id>

# Sync after adding new docs
python extensions/vector_store.py sync <project_id>
```

### Options

```bash
-n, --num-results    Number of results (default: 5)
-t, --type           Filter by type (code/rule/doc/note/prompt)
--json               Output as JSON
```

## File Structure

```
~/.opencode/
├── context-dispatcher.zsh
├── context/
│   ├── projects/<project_id>/
│   │   ├── config.json       # Project settings
│   │   └── index.json        # Indexed code chunks
│   ├── docs/<project_id>/
│   │   └── docs.jsonl        # Manual docs/rules/notes
│   ├── vectors/<project_id>/ # ChromaDB storage (if using extension)
│   ├── agents/               # Agent-specific context
│   ├── cache/                # Shared cache
│   └── logs/                 # System logs
```

## Sample Agent Prompts

### Basic Context Prompt

```
You have access to a project context system with code and documentation.

To get context, use these commands:
- `ctx get-full <project_id>` - Get complete context (code + rules + docs)
- `ctx get <project_id> "query"` - Search for specific patterns
- `ctx get-docs <project_id> rule` - Get project rules only

Always check the rules before making changes. The context includes:
- Project-specific coding rules and standards
- Business logic documentation
- Function and class definitions
- Recent code changes

Verify against actual files as context may be summarized.
```

### System Prompt with Rules

```
You are an AI coding assistant for this project. Follow these guidelines:

## Project Rules
{output of: ctx get-docs <project_id> rule}

## Architecture Overview  
{output of: ctx get-docs <project_id> doc}

## Code Context
{output of: ctx get <project_id>}

When making changes:
1. Always follow the project rules above
2. Reference the architecture docs for design decisions
3. Check existing code patterns before creating new ones
```

### Interactive Agent Prompt

```
You have access to a context management system. Available commands:

Project Context:
- ctx get-full PROJECT_ID     # Complete context
- ctx get PROJECT_ID "query"  # Search code

Documentation:
- ctx get-docs PROJECT_ID rule   # Project rules
- ctx get-docs PROJECT_ID doc    # Documentation
- ctx list-docs PROJECT_ID       # List all docs

Use these to gather context before making changes. Always check rules first.
Current project ID: {project_id}
```

## Configuration

Project config (`~/.opencode/context/projects/<id>/config.json`):

```json
{
    "name": "Project Name",
    "path": "/path/to/project",
    "exclude_patterns": ["node_modules", ".git", "dist", "build"],
    "include_extensions": [".js", ".ts", ".py", ".rs"],
    "chunk_size": 2000,
    "max_files": 1000
}
```

## Troubleshooting

### Commands not found after sourcing

Re-source the script:
```bash
source ~/.opencode/context-dispatcher.zsh
```

### Index is empty after reindex

Check project path and file extensions:
```bash
cat ~/.opencode/context/projects/<project_id>/config.json
```

### Character encoding errors

Non-fatal warnings from files with special characters. The script uses `LC_ALL=C` to handle them.

### ChromaDB errors

Ensure dependencies are installed:
```bash
pip install chromadb llama-index llama-index-vector-stores-chroma
```

## License

MIT
