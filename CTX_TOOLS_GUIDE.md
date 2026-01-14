# Context Tools (ctx) & Agent Tool Access Guide

## The Issue: "invalid Invalid Tool"

When running `ocx` with a message that requests tool usage, the agent may show:
```
|  invalid  Invalid Tool
```

This occurs because `opencode run` doesn't grant tool access to the AI agent by default. Tool access is only available in:
1. **Interactive TUI mode** (default, has full tool support)
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

### Solution 1: Use Interactive Mode (Recommended)

Instead of providing a message, let the agent start in interactive TUI with tools:

```bash
# This gives you a full interactive session with tools
ocx 7e304c6738a8b942

# Or specify context mode
ocx -c full 7e304c6738a8b942
```

In interactive mode, you can:
- Execute code
- Run commands
- Use all available tools
- Access the project context

### Solution 2: Use an Agent with Tool Configuration

First, create or use an agent that has tool access configured:

```bash
# List available agents
opencode agent list

# Run ocx with an agent
ocx -a my-agent 7e304c6738a8b942 "Confirm access to ctx tools. Run unit tests..."
```

**Note**: The agent must be configured with tool access. Check your agent configuration.

### Solution 3: Default Behavior Change

The updated `ocx` script now **defaults to interactive mode** when no message is provided:

```bash
# Before: Would error "Message required"
# Now: Starts interactive TUI with tools
ocx 7e304c6738a8b942
```

## Testing Tool Access

### Test 1: Verify Interactive Mode Has Tools

```bash
ocx 7e304c6738a8b942
# In the TUI, try running a command like: run ls
# If tools work, you'll see the output
```

### Test 2: Test with Context Modes

```bash
# Full context + interactive tools
ocx -c full 7e304c6738a8b942

# Rules only + interactive tools
ocx -c rules 7e304c6738a8b942

# Code + docs + interactive tools
ocx -c docs 7e304c6738a8b942
```

### Test 3: Verify Context Is Injected

In interactive mode, check that the context was loaded:

```
Enter prompt: "What are the project rules?"
# Should reference rules from your ctx context
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

```bash
# 1. Start interactive mode with context
ocx -c full 7e304c6738a8b942

# 2. In the interactive TUI, you can now:
# Type: "Run unit tests and fix failures"
# The agent has access to:
# - Execute commands (npm test, pytest, etc.)
# - Read and edit files
# - Use all tools for fixing issues

# 3. Context from your project is available in the AI's knowledge
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

### For Development Tasks
```bash
# Start interactive session with full context
ocx -c full <project_id>
# Chat with context, use tools naturally
```

### For Automated Tasks
```bash
# Create an agent with tool access first
opencode agent create my-tool-agent
# Then use it with ocx
ocx -a my-tool-agent <project_id> "automated task"
```

### For Testing
```bash
# Interactive mode gives best test feedback
ocx -c full <project_id>
# Type: "Run the unit tests in src/tests and fix any failures"
```
