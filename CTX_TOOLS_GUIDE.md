# Context Tools (ctx) & Agent Tool Access Guide

## The Issue: "invalid Invalid Tool" or Missing ctx Tools

When running `ocx` with a message that requests tool usage, the agent may show:
```
|  invalid  Invalid Tool
```

Or it may try to run commands like `pytest` directly instead of `uv run pytest`.

This occurs because `opencode run` (headless mode) has **severely limited tool access**. Full tool access is only available in:
1. **Interactive TUI mode** (recommended - has full tool support)
2. **With an agent** (using `--agent` flag with proper configuration)

## How Tool Access Works in OpenCode

### Tool Access Matrix

| Mode | Tool Access | When to Use |
|------|------------|------------|
| `opencode <path>` | ✅ Full tools | Interactive coding tasks |
| `opencode run "message"` | ❌ No tools | Simple queries, no tool usage needed |
| `opencode run "message" --agent <name>` | ✅ If agent configured | Automated tasks with tools |
| `ocx <id>` (no message) | ✅ Full tools | Interactive mode with context |
| `ocx <id> "message"` | ❌ No tools | Headless mode - context only |
| `ocx -a <agent> <id> "message"` | ✅ If agent has tools | Agent mode with context |

## Solutions

### Solution 1: Use Interactive Mode with Prompt (Recommended)

Pass your message as a prompt to the interactive TUI, which has full tool access:

```bash
# This starts interactive mode and seeds it with your prompt
# The context is available and agent has full tools
ocx -c full 7e304c6738a8b942 "run unit tests and fix failures"

# Or without specifying context (defaults to full)
ocx 7e304c6738a8b942 "run tests"
```

**This is the key fix!** When you provide a message to `ocx`, it now:
1. ✅ Opens the interactive TUI (not headless mode)
2. ✅ Passes your message as an initial prompt
3. ✅ Injects context automatically
4. ✅ Agent has FULL tool access

In interactive mode, the agent can:
- Execute code and tests
- Run arbitrary commands
- Edit files
- Use the `ctx` command to save working context
- Access all tools natively

### Solution 2: Interactive Mode Without Initial Prompt

Start interactive mode and interact manually:

```bash
# Opens interactive TUI with context available
ocx 7e304c6738a8b942

# Then type your request in the interactive session
# The agent can use all tools from there
```

### Solution 3: Use with Custom Context Mode

Combine the prompt approach with specific context:

```bash
# Run tests with only rules context
ocx -c rules 7e304c6738a8b942 "run tests"

# With only code context  
ocx -c code 7e304c6738a8b942 "analyze the test failures"

# Full context (default)
ocx -c full 7e304c6738a8b942 "run all tests and fix failures"
```

## Testing Tool Access

### Test 1: Run Tests with Auto-Prompt

```bash
ocx 7e304c6738a8b942 "run unit tests"
```

Expected behavior:
- Opens interactive TUI
- Passes "run unit tests" as initial prompt
- Agent can execute tests with full tool access
- See test output in real-time

### Test 2: Test with Different Context Modes

```bash
# Full context + interactive tools + prompt
ocx -c full 7e304c6738a8b942 "run unit tests and fix failures"

# Rules only + interactive tools + prompt
ocx -c rules 7e304c6738a8b942 "what are the project rules?"

# Code + docs + interactive tools
ocx -c docs 7e304c6738a8b942 "explain the architecture"
```

### Test 3: Verify ctx Tools Are Available

In the interactive TUI, agent can now use ctx:

```
# Agent can run and it will work:
run ctx list
run ctx add-doc <id> rule "new rule" "title"
run ctx get-docs <id>
```

## Why Tool Access Differs by Mode

### Interactive Mode (`opencode <path>`)
- Runs the full OpenCode TUI
- Full access to tools, shell commands, file operations
- Best for human-in-the-loop development

### Run Mode (`opencode run "message"`)
- Headless execution
- No tool access by default
- Suitable for simple queries only
- **Cannot** be used for code execution, file operations, etc.

## Command Reference

```bash
# Start interactive with full context (DEFAULT if no message)
ocx <project_id>

# Interactive with specific context mode
ocx -c rules <project_id>
ocx -c code <project_id>
ocx -c docs <project_id>

# Quiet mode (no context summary)
ocx -q <project_id>

# Use specific model
ocx -m opencode/big-pickle <project_id>

# Use specific agent (must have tools configured)
ocx -a my-agent <project_id> "message"

# Help
ocx -h
```

## Workflow Example: Unit Tests with Tools

**The Recommended Way** (NEW):

```bash
# One command - everything you need!
ocx -c full 7e304c6738a8b942 "run unit tests and fix failures"

# What happens:
# 1. Opens interactive TUI (has tool access)
# 2. Injects full context (rules + code + docs)
# 3. Passes "run unit tests and fix failures" as prompt
# 4. Agent can execute:
#    - Run tests: npm test, pytest, uv run pytest, etc.
#    - Read files and understand failures
#    - Edit files to fix issues
#    - Save context with ctx add-doc
# 5. All output visible in real-time
```

**Alternative** (Manual):

```bash
# Start interactive, then type commands manually
ocx -c full 7e304c6738a8b942

# Then in the TUI:
# - Type your request
# - Agent runs with full tools
```

## Troubleshooting

### "Invalid Tool" Error
- You're using `opencode run` mode (headless)
- **Solution**: Use interactive mode instead (`ocx <id>` with no message)

### "No tools available"
- Agent is not configured with tool access
- **Solution**: Either use interactive mode or create an agent with tools

### Context Not Showing
- Context was prepared but not visible in interactive mode
- **Solution**: Reference it explicitly in your prompt, or check `~/.opencode/context/projects/<id>/`

## Recommended Patterns

### Pattern 1: Test Execution with Auto-Fix

```bash
# Run tests and let agent fix failures automatically
ocx -c full <project_id> "run all tests and fix any failures"

# What the agent will do:
# 1. Execute tests (pytest, npm test, etc.)
# 2. See which tests fail
# 3. Read failing test files
# 4. Fix the implementation
# 5. Re-run tests to verify
```

### Pattern 2: Feature Development

```bash
# Develop a feature with full context and tools
ocx -c full <project_id> "implement user authentication endpoint"

# Agent has access to:
# - Project structure and patterns (via context)
# - File editing tools
# - Test execution (run tests continuously)
# - Documentation reading
```

### Pattern 3: Bug Investigation

```bash
# Investigate and fix a reported bug
ocx -c code <project_id> "Debug: users can't log in after password reset. Find and fix the issue."

# Agent can:
# - Read code to understand flow
# - Run tests to understand failure
# - Trace through authentication logic
# - Create/run failing test
# - Fix the bug
# - Verify with tests
```

### Pattern 4: Code Review & Improvements

```bash
# Review code and improve it
ocx -c full <project_id> "review the API endpoints and suggest improvements. Fix any issues you find."

# Full context + code access + tools allows:
# - Understanding project rules
# - Reviewing against standards
# - Testing changes
# - Documentation updates
```

### Pattern 5: Save Context Between Sessions

```bash
# Session 1: Do some work
ocx <project_id> "analyze the codebase"
# In TUI, agent finishes analysis and runs:
#   ctx add-doc <id> note "Key findings: auth is JWT-based, uses async/await..." "Architecture Notes"

# Session 2: Continue from where you left off
ocx <project_id> "based on the architecture notes, implement..."
# Context from previous session is available!
```
