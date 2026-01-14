# OpenCode AI Context Dispatcher

A shell-based context management system for AI coding agents. Automatically indexes your codebase and provides relevant context to AI assistants.

## Features

- Automatic project context indexing and tracking
- **Git-aware indexing**: Automatically respects `.gitignore` rules
- **Expanded exclusions**: Built-in protection against indexing `node_modules`, `.git`, `.next`, `.brv`, and other build/dev noise
- Code structure extraction (functions, classes, methods)
- Git-aware incremental updates
- **Manual documentation support** (rules, docs, notes, prompts)
- Agent-specific context storage and retrieval
- Cross-platform support (Linux/macOS)
- **Integrated semantic search**: ChromaDB + LlamaIndex available directly via `ctx search-v` and `ctx sync-v`
- **Background syncing**: Semantic index automatically updates after reindexing or updates

## Installation

```bash
git clone https://github.com/deceptikon/opencode-ai-context-dispatcher.git
cd opencode-ai-context-dispatcher
./install-context-dispatcher.sh
```

The installer will:
1. Install shell dependencies (`jq`, `ripgrep`)
2. Set up the context dispatcher
3. Optionally install Python dependencies for semantic search

Restart your shell or run:
```bash
source ~/.zshrc
```

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

# 4. Run opencode with context automatically injected
ocx <project_id> "fix the authentication bug"
```

## OpenCode Integration (ocx)

The `ocx` command wraps opencode and automatically injects your project context:

```bash
# Interactive mode (default if no message) - FULL TOOL ACCESS
ocx <project_id>

# With context mode - still interactive with full tools
ocx -c full <project_id>
ocx -c rules <project_id>
ocx -c code <project_id>  
ocx -c docs <project_id>

# Quiet mode (no context summary)
ocx -q <project_id>

# Specify model
ocx -m opencode/big-pickle <project_id>

# Use agent with tools
ocx -a my-agent <project_id> "your task"
```

### Important: Tool Access

**OpenCode agents have tool access by default in INTERACTIVE mode only.**

- ✅ `ocx <id>` → Interactive mode with tools
- ❌ `ocx <id> "message"` → Headless mode without tools
- ✅ `ocx -a <agent> <id> "message"` → Agent mode (if agent has tools)

For tasks requiring tool usage (running tests, executing commands, editing files), use interactive mode. See [CTX_TOOLS_GUIDE.md](./CTX_TOOLS_GUIDE.md) for details.

### What Gets Injected

When you run `ocx`, the AI receives:

| Mode | Rules | Docs | Code | Notes | Prompts |
|------|-------|------|------|-------|---------|
| full | Yes | Yes | Yes | Yes | Yes |
| rules | Yes | - | - | - | - |
| code | - | - | Yes | - | - |
| docs | Yes | Yes | - | - | Yes |

This means your AI assistant automatically knows:
- Your coding standards and rules
- Project architecture and documentation
- Recent code structure and patterns
- Any custom instructions you've added

## Core Commands

### Project Management

```bash
ctx init <path> [name]       # Initialize context for a project
ctx init-agent <project_id>  # Generate AGENTS.md guide in project root
ctx update <project_id>      # Incremental update (git changes)
ctx reindex <project_id>     # Full reindex (respects .gitignore)
ctx list                     # List all managed projects
ctx stats <project_id>       # Show statistics
```


### Semantic Search (Integrated)

Semantic search understands **meaning**, not just keywords. The `ctx` command now provides integrated access to the vector store extension:

```bash
ctx sync-v <project_id>     # Manually sync current project to semantic index
ctx search-v <project_id> "how does auth work?"  # Semantic search for logic
```

*Note: Semantic search is also triggered automatically in the background when you run `ctx reindex` or `ctx update`.*

### Context Retrieval

```bash
ctx get <project_id>              # Get code context
ctx get <project_id> "query"      # Search code context (keyword-based)
ctx get-full <project_id>         # Get everything (code + docs + rules)
```

### Documentation & Rules

Add business logic, rules, documentation, and custom prompts that persist alongside your code context:

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

### Maintenance

```bash
ctx cleanup [days]    # Remove old context (default: 30 days)
ctx help              # Show all commands
```

### 🛠 Maintaining this Project

If you are an agent working on the Context Dispatcher itself, run this to onboard:
```bash
ctx get-full 3da7ab8253e7d441
```
This will load all maintenance rules and architectural knowledge specific to this system.

## Semantic Search with ChromaDB + LlamaIndex

### Why Use Semantic Search?

The shell-based context (`ctx get`) uses **keyword matching** - it finds exact text matches. This works well for:
- Finding specific function names
- Searching for exact error messages
- Locating imports and exports

**Semantic search** (ChromaDB) understands **meaning**, not just keywords. Use it when you want to:

| Use Case | Keyword Search | Semantic Search |
|----------|---------------|-----------------|
| "Find the `handleAuth` function" | Works great | Works |
| "Find code that handles authentication" | Might miss code that uses `login`, `session`, `jwt` | Finds all related code |
| "How does payment processing work?" | Returns nothing useful | Returns relevant code + explanation |
| "Find similar code to this pattern" | Can't do this | Can find conceptually similar code |

### When to Use What

```
Shell-only (ctx get):
├── Fast, no dependencies
├── Good for: exact matches, specific names
└── Example: "find useState", "find class UserService"

ChromaDB (vector_store.py search):
├── Semantic/meaning-based search
├── Good for: conceptual queries, finding related code
└── Example: "code that validates user input", "error handling patterns"

LlamaIndex (vector_store.py query):
├── RAG - Retrieval Augmented Generation
├── Good for: questions that need synthesized answers
└── Example: "how does the auth flow work?", "explain the API structure"
```

### Setup

```bash
pip install chromadb llama-index llama-index-vector-stores-chroma
```

### Usage

```bash
# Index your project into the vector database
python ~/.opencode/extensions/vector_store.py index <project_id>

# Or index directly from filesystem (better for large projects)
python ~/.opencode/extensions/vector_store.py index-dir <project_id>

# Semantic search - find by meaning
python ~/.opencode/extensions/vector_store.py search <project_id> "authentication logic"
python ~/.opencode/extensions/vector_store.py search <project_id> "database queries" -t code
python ~/.opencode/extensions/vector_store.py search <project_id> "coding standards" -t rule

# RAG query - ask questions, get answers with sources
python ~/.opencode/extensions/vector_store.py query <project_id> "how does the payment flow work?"

# Re-sync after adding new docs
python ~/.opencode/extensions/vector_store.py sync <project_id>

# Check what's indexed
python ~/.opencode/extensions/vector_store.py stats <project_id>
```

### Options

```
-n, --num-results    Number of results (default: 5)
-t, --type           Filter by type (code/rule/doc/note/prompt)
--json               Output as JSON for scripting
```

### Example Workflow

```bash
# 1. Set up project with shell context
ctx init ~/projects/myapp "My App"
ctx reindex abc123

# 2. Add business rules and docs
ctx add-doc abc123 rule "Use dependency injection for all services" "DI Rule"
ctx add-file abc123 doc ./docs/architecture.md "Architecture"

# 3. Index into vector store for semantic search
python ~/.opencode/extensions/vector_store.py index abc123

# 4. Now you can search by meaning
python ~/.opencode/extensions/vector_store.py search abc123 "how to add a new API endpoint"

# 5. Or ask questions
python ~/.opencode/extensions/vector_store.py query abc123 "what patterns does this codebase use for error handling?"
```

## File Structure

```
~/.opencode/
├── context-dispatcher.zsh    # Main script
├── extensions/
│   ├── vector_store.py       # ChromaDB + LlamaIndex extension
│   └── ctx-vector            # Shell wrapper
├── context/
│   ├── projects/<id>/
│   │   ├── config.json       # Project settings
│   │   └── index.json        # Indexed code chunks
│   ├── docs/<id>/
│   │   └── docs.jsonl        # Manual docs/rules/notes
│   ├── vectors/<id>/         # ChromaDB storage
│   ├── agents/               # Agent-specific context
│   ├── cache/                # Shared cache
│   └── logs/                 # System logs
```

## Sample Agent Prompts

### Basic Context Prompt

> **Note**: These are prompt templates for AI agents, not shell commands to run directly.
> Replace `PROJECT_ID` with your actual project ID (use `ctx list` to find it).

```text
You have access to a project context system with code and documentation.

To get context, run these shell commands:
  ctx get-full PROJECT_ID           # Get complete context (code + rules + docs)
  ctx get PROJECT_ID 'query'        # Search for specific patterns  
  ctx get-docs PROJECT_ID rule      # Get project rules only

Always check the rules before making changes. The context includes:
- Project-specific coding rules and standards
- Business logic documentation
- Function and class definitions
- Recent code changes

Verify against actual files as context may be summarized.
```

### System Prompt with Injected Rules

```text
You are an AI coding assistant for this project. Follow these guidelines:

## Project Rules
{output of: ctx get-docs PROJECT_ID rule}

## Architecture Overview  
{output of: ctx get-docs PROJECT_ID doc}

## Code Context
{output of: ctx get PROJECT_ID}

When making changes:
1. Always follow the project rules above
2. Reference the architecture docs for design decisions
3. Check existing code patterns before creating new ones
```

### Interactive Agent with Semantic Search

```text
You have access to a context management system. Available commands:

Keyword Search (fast, exact matches):
  ctx get PROJECT_ID 'query'        # Search code
  ctx get-docs PROJECT_ID rule      # Get rules
  ctx get-full PROJECT_ID           # Everything

Semantic Search (meaning-based, requires ChromaDB):
  python ~/.opencode/extensions/vector_store.py search PROJECT_ID 'query'
  python ~/.opencode/extensions/vector_store.py query PROJECT_ID 'question'

Use keyword search for specific names/patterns.
Use semantic search for conceptual questions like 'how does X work?'

Current project ID: PROJECT_ID
```

## Configuration

Project config (`~/.opencode/context/projects/<id>/config.json`):

```json
{
    "name": "Project Name",
    "path": "/path/to/project",
    "exclude_patterns": ["node_modules", ".git", "dist", "build", ".next", ".brv", ".cache"],
    "include_extensions": [".js", ".ts", ".py", ".rs", ".zsh", ".sh", ".md", ".json"],
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

### jq parse errors

Usually caused by control characters in input. The script now sanitizes inputs automatically. If you have an old corrupted project, remove and re-initialize:
```bash
rm -rf ~/.opencode/context/projects/<project_id>
ctx init /path/to/project "Name"
```

### Character encoding errors during reindex

Non-fatal warnings from files with special characters. The script uses `LC_ALL=C` to handle them.

### ChromaDB/LlamaIndex errors

Ensure dependencies are installed in the OpenCode venv:
```bash
~/.opencode/venv/bin/pip install chromadb llama-index llama-index-vector-stores-chroma
```
If you don't have a venv yet:
```bash
python3 -m venv ~/.opencode/venv
```

## Uninstallation

```bash
./uninstall-context-dispatcher.sh
```

## License

MIT
