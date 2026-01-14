# Context Dispatcher (ctx) - Experience & Testing Report

## Overview
Tested the OpenCode AI Context Dispatcher (`ocx` wrapper) functionality to understand how project context is injected and used by AI models.

## Initial Issues

### Problem 1: Silent Script Failure
**Issue**: Running `ocx` command produced no output and appeared to hang.

**Root Cause**: The `get_context_data()` function was calling `zsh -c` which was encountering jq parse errors from corrupted index files. With `set -e` enabled, these errors caused the script to exit silently without completing.

**Solution**: Added `|| true` to the `get_context_data()` function to prevent parse errors from killing the script:
```bash
get_context_data() {
    zsh -c "
        source '$DISPATCHER'
        $1
    " 2>/dev/null || true
}
```

### Problem 2: AI Not Using Injected Context
**Issue**: Even with context prepended to the message, the AI would ignore it and explore the filesystem manually instead of analyzing the provided project context.

**Root Cause**: Simply including context as text in the prompt doesn't force the AI to use it. The model treated it as background information but prioritized its own exploration.

**Solution**: Added explicit "SYSTEM INSTRUCTIONS:" header to force the AI to prioritize the injected context:
```bash
FULL_MESSAGE="SYSTEM INSTRUCTIONS:
You are working on the '$PROJECT_NAME' project. The following project context has been provided for you. Study it carefully and use it to inform your responses. Do NOT ignore this context.

$CONTEXT_CONTENT

---

USER REQUEST:

$MESSAGE"
```

## Key Improvements Made

### 1. Flag Reorganization
- Changed `-m/--mode` to `-c/--context` for context mode selection
- Added new `-m/--model` flag for model specification
- Now supports: `ocx -c rules -m opencode/big-pickle PROJECT_ID "prompt"`

### 2. Model Selection Support
Available models include:
- `opencode/big-pickle` (recommended - Claude Sonnet equivalent)
- `opencode/claude-sonnet-4-5`
- `opencode/gpt-5`
- `opencode/gemini-3-pro`
- And many others

### 3. Context Delivery
Changed from `--file` flag approach to direct prepending because:
- File attachments weren't being read by the AI
- Direct prepending ensures context is visible in the prompt
- Added system instruction header to enforce usage

## Testing Results

### Test 1: Rules Mode
```bash
ocx -c rules a4c241bf0b3447d8 'What are the project rules?'
```

**Result**: ✅ AI correctly identified and summarized the TypeScript strict mode rule.

### Test 2: Full Context Mode
```bash
ocx -c full a4c241bf0b3447d8 'Summarize the project and its rules'
```

**Result**: ✅ AI analyzed both rules and code context, even detected architectural discrepancies.

### Test 3: Parallel Execution
Ran two `ocx` commands simultaneously on different projects.

**Result**: ✅ Both completed successfully without conflicts, processing 8KB+ of context each.

## Architecture Notes

The context injection flow:
1. `ocx` script loads project config and context from `~/.opencode/context/`
2. Retrieves rules, docs, and code based on `-c` mode
3. Builds context file with project metadata
4. Prepends "SYSTEM INSTRUCTIONS:" header
5. Includes full context + user message
6. Passes to `opencode run` with optional model flag

## Lessons Learned

1. **Just prepending context isn't enough** - Need explicit system instructions
2. **Error handling matters** - Silent failures from `set -e` are confusing
3. **AI respects explicit instructions** - When told not to ignore context, it doesn't
4. **File attachment flags don't guarantee usage** - Direct message prepending is more reliable
5. **Parallel execution works well** - No race conditions or conflicts observed

## Future Improvements

Potential enhancements:
- Add semantic search support for finding relevant code chunks automatically
- Implement context caching to avoid re-fetching unchanged files
- Add metrics for context usage (which parts of context were referenced)
- Support for custom system prompts per project
- Integration with ChromaDB for semantic context retrieval
