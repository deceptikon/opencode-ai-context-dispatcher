# Quick Start: Using ctx Tools with OpenCode

## The Problem Was
- `ocx <id> "run tests"` → headless mode → **no tool access** ❌
- Agent couldn't execute tests, edit files, or use `ctx` commands
- Error: `| invalid Invalid Tool`

## The Solution (Updated!)
- `ocx <id> "run tests"` → interactive TUI with tools → **full access** ✅
- Pass your message to `ocx` and it opens interactive mode
- Agent has complete tool access + project context

## Usage

### Run Tests and Fix Failures
```bash
ocx 7e304c6738a8b942 "run unit tests and fix failures"
```
- Opens interactive TUI
- Injects project context  
- Agent can execute `pytest` (or `uv run pytest` with context hint)
- Agent can edit files
- Agent can run tests repeatedly to verify fixes

### With Context Mode
```bash
# Full context (rules + code + docs)
ocx -c full <id> "run tests"

# Just rules
ocx -c rules <id> "what are the project rules?"

# Just code
ocx -c code <id> "analyze the test failures"

# Rules + docs
ocx -c docs <id> "explain the architecture"
```

### Save Working Context Between Sessions
In the interactive TUI, agent can save context:
```
# Agent runs this in the TUI:
run ctx add-doc <project-id> note "Findings: tests pass for auth, fail for payments" "Test Results"

# Next session can reference this:
ocx <id> "based on test results, fix payment logic"
```

## How It Works

1. **You run**: `ocx -c full <id> "run tests and fix"`
2. **Script does**:
   - Loads context from ctx database
   - Builds project documentation
   - Opens interactive OpenCode TUI
   - Passes your message as initial prompt
3. **Agent in TUI**:
   - ✅ Has full tool access
   - ✅ Can execute commands
   - ✅ Can read/edit files
   - ✅ Can use `ctx` tools
   - ✅ Sees project context
4. **Agent runs**:
   - Executes tests
   - Reads failures
   - Fixes code
   - Re-runs tests

## Key Commands

```bash
# Start interactive (no initial message)
ocx <project-id>

# Start interactive with prompt
ocx <project-id> "your task here"

# With specific context mode
ocx -c <mode> <project-id> "task"

# With specific model
ocx -m <model> <project-id> "task"

# List projects
source ~/.opencode/context-dispatcher.zsh
ctx list

# View context
ctx get <project-id>

# NEW: Semantic search
ctx search-v <project-id> "how does auth work?"

# Add rules/notes for next session
ctx add-doc <project-id> rule "Rule text" "Title"
ctx add-doc <project-id> note "Note text" "Title"
```

## When to Use Each Mode

| Task | Command |
|------|---------|
| Run tests | `ocx <id> "run tests and fix failures"` |
| Code review | `ocx -c code <id> "review and improve"` |
| Feature development | `ocx <id> "implement new feature"` |
| Bug fix | `ocx <id> "find and fix the bug"` |
| Architecture discussion | `ocx -c docs <id> "explain architecture"` |

## Troubleshooting

**"Invalid Tool" error?**
- You're in headless mode
- Make sure you're providing a message: `ocx <id> "message"`
- Or just run `ocx <id>` to enter interactive mode manually

**Agent not using context?**
- Context is only visible if you include it in your message
- Make sure context mode includes what you need: `-c full` for everything

**Can't use ctx commands?**
- They're only available in interactive TUI mode
- Make sure you're not in pure headless mode
- Run `ocx <id> "task"` to get interactive + tools

## What's Different Now?

Before: `ocx <id> "message"` → headless mode (no tools)
Now: `ocx <id> "message"` → interactive TUI (full tools!)

The message is passed as a prompt to the interactive TUI, so:
- You get tools
- Agent sees context
- Everything works!
