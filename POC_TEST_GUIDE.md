# PoC Test Guide: Agent Onboarding System

## Quick Summary

**What we're testing**: Can agents learn how a project works, save that knowledge, and future agents use it?

**Where it's saved**: `~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl` (plain JSON Lines)

**Success = 3 tests pass**: Learn → Load → Extend

---

## Test 1: Initial Onboarding (Agent Learns)

### Command
```bash
# Copy script to ~/.opencode first
cp /home/lexx/MyWork/opencode-ai-context-dispatcher/opencode-with-context ~/.opencode/opencode-with-context

# Run onboarding
ocx -c full 7e304c6738a8b942 "CRITICAL ONBOARDING SESSION - Explore and document this Django project

PHASES:
1. EXPLORATION (20 min)
   - Read README
   - Explore directory structure  
   - Identify tech stack (Python, Django, pytest, etc.)
   
2. DISCOVERY (15 min)
   - Test pytest: run uv run pytest --collect-only
   - Test ruff: run uv run ruff check . 2>&1 | head -5
   - Test django: run python manage.py --help 2>&1 | head -10
   - Test migrations: run python manage.py migrate --help 2>&1 | head -5

3. DOCUMENTATION (20 min)
   - Save what you learned with ctx add-doc
   
Example commands to run:
  run ctx add-doc 7e304c6738a8b942 rule 'Test Execution' 'Use: uv run pytest for all tests. uv run pytest -m fast for quick tests'
  run ctx add-doc 7e304c6738a8b942 rule 'Code Quality' 'Use: uv run ruff check . to find issues. uv run ruff format . to fix'
  run ctx add-doc 7e304c6738a8b942 rule 'Django' 'Use: python manage.py migrate for database. python manage.py runserver for dev'
  run ctx add-doc 7e304c6738a8b942 doc 'Project Structure' 'apps/ has business logic, interfaces/ has API, project/ has settings, tests/ has pytest'
  run ctx add-doc 7e304c6738a8b942 note 'Development Workflow' '1) Edit code 2) Run tests: uv run pytest 3) Format: uv run ruff format . 4) Commit'
  run ctx add-doc 7e304c6738a8b942 note 'Troubleshooting' 'pytest not found = run uv sync, ModuleNotFoundError = check __init__.py, Database errors = run migrate'

Document everything you discover!"
```

### Verify Success

```bash
# Check line count BEFORE (baseline)
echo "Before onboarding:"
wc -l ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl

# After agent completes, check growth
echo "After onboarding:"
wc -l ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl

# View new doc titles
echo "New documents saved:"
cat ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl | jq -r '.title' 2>/dev/null | tail -10

# Count by type
echo "Breakdown:"
cat ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl | jq -r '.type' 2>/dev/null | sort | uniq -c
```

### Success Criteria
- ✅ Session completes without errors
- ✅ At least 5 NEW documents added to JSONL
- ✅ Line count increased (e.g., 11 → 25+)
- ✅ Can see rule/doc/note types in output

### Expected Result
```
Before: 11 lines
After: 25+ lines
Types: 4-5 rules, 2-3 docs, 3-4 notes
```

---

## Test 2: Future Agent Loads Context (Agent Uses Knowledge)

### Command
```bash
# Run AFTER Test 1 completes
ocx -c full 7e304c6738a8b942 "Run the test suite and explain what you found. Use the saved testing strategies and tools from onboarding"
```

### What to Look For
- Agent mentions saved commands: "uv run pytest"
- Agent references test strategy from saved notes
- Agent runs tests efficiently (doesn't ask "how do I run tests?")
- Agent output shows it loaded the context

### Success Criteria
- ✅ Agent uses saved context (mentions "test" or references rules)
- ✅ Agent runs tests with correct command (uv run pytest)
- ✅ No exploration phase (doesn't read README again)
- ✅ Works more efficiently than Test 1

### Expected Behavior
```
Agent: "I'll run the tests as documented: uv run pytest"
(instead of: "Let me check how to run tests...")
```

---

## Test 3: Agent Extends Knowledge (Accumulation)

### Command
```bash
# Run AFTER Test 2 completes
ocx -c full 7e304c6738a8b942 "ONBOARDING EXTEND: Check if there are any new patterns, edge cases, or optimizations we haven't documented yet. Add them."
```

### Verify Success

```bash
# Check line count grew again
wc -l ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl

# View latest additions
tail -15 ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl | jq '.title'
```

### Success Criteria
- ✅ More documents added to JSONL
- ✅ New content is different from Test 1 (advanced patterns, edge cases)
- ✅ Line count increased again

### Expected Result
```
After Test 1: 25 lines
After Test 3: 35+ lines
New content: advanced patterns, edge cases, optimizations
```

---

## Quick Check Commands

Run these anytime to verify state:

```bash
# Current doc count
wc -l ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl

# List all titles
cat ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl | jq -r '.title' 2>/dev/null | sort

# Count by type
cat ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl | jq -r '.type' 2>/dev/null | sort | uniq -c

# Show latest additions
tail -20 ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl | jq '{title, type, timestamp}'

# Search for specific content
cat ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl | jq 'select(.content | contains("pytest"))' 2>/dev/null | head -2
```

---

## Success Matrix

| Metric | Test 1 | Test 2 | Test 3 |
|--------|--------|--------|--------|
| Docs saved | 5+ | 0 (loads) | 5+ |
| Agent explores | Yes | No | Maybe |
| Agent saves context | Yes | - | Yes |
| JSONL grows | Yes | No | Yes |
| Line count | 11→25+ | 25+ | 25+→35+ |

---

## Failure Modes & Fixes

### Agent doesn't save docs
- Check: Agent used `ctx add-doc` command?
- Fix: Include explicit examples in prompt
- Verify: Agent sees "✓ Saved" messages in output

### Future agent doesn't load context
- Check: Context file exists and has content
- Verify: `cat ~/.opencode/context/docs/.../docs.jsonl | wc -l`
- Fix: Ensure `-c full` flag includes docs

### No knowledge accumulation
- Check: Each test added different content?
- Fix: Make Test 3 prompt more specific
- Example: "Find 3 new edge cases not yet documented"

### JSONL file corrupted
- Error: `jq: parse error`
- Fix: Check last few lines: `tail -5 docs.jsonl`
- Cause: Agent saved with newlines in content
- Solution: Pre-sanitize agent output

---

## Timeline

| Phase | Duration | What Happens |
|-------|----------|--------------|
| Test 1 (Learn) | 30-40 min | Agent explores, documents, saves 5-10 docs |
| Review | 5 min | Verify JSONL grew |
| Test 2 (Load) | 10-15 min | Agent runs task using saved context |
| Review | 5 min | Verify agent referenced saved docs |
| Test 3 (Extend) | 20-30 min | Agent extends onboarding, adds more docs |
| Review | 5 min | Verify knowledge accumulated |
| **Total** | **~90 min** | **Complete PoC** |

---

## Success Definition

### PoC Works (Green) ✅
- Test 1: Agent saves 5+ documents
- Test 2: Agent loads and uses context
- Test 3: Agent adds more documents
- JSONL grows progressively: 11 → 25+ → 35+
- Each agent builds on previous knowledge

### PoC Partially Works (Yellow) 🟡
- Agent saves some docs but not consistently
- Context sometimes referenced, sometimes not
- Growth is slower than expected

### PoC Doesn't Work (Red) 🔴
- Agent doesn't save docs or saves only 1-2
- Future agent doesn't reference saved context
- No progressive knowledge accumulation
- JSONL doesn't grow

---

## Next Steps After PoC

### If Green (Works!) ✅
1. Consider adding ChromaDB for semantic search
2. Run onboarding for additional projects
3. Build agent meta-learning pipeline

### If Yellow (Partially) 🟡
1. Debug: Which phase fails?
2. Adjust prompts
3. Ensure ctx add-doc syntax is correct
4. Retry

### If Red (Fails) 🔴
1. Check script installation
2. Verify big-pickle model works
3. Test `ctx add-doc` manually
4. Review JSONL file format

---

## Manual Context Addition (If Agent Doesn't)

If agent won't save context, you can manually add it:

```bash
source ~/.opencode/context-dispatcher.zsh

# Add a rule
add_doc 7e304c6738a8b942 rule "Test Execution: Use 'uv run pytest' for full suite, 'uv run pytest -m fast' for quick tests" "Test Commands"

# Add documentation  
add_doc 7e304c6738a8b942 doc "Project Structure: apps/ (business logic), interfaces/ (API views), project/ (Django settings), tests/ (test suite)" "Directory Layout"

# Add a workflow note
add_doc 7e304c6738a8b942 note "Development Workflow: 1) Edit code 2) Run tests 3) Format code 4) Commit" "Dev Workflow"

# Verify
get_docs 7e304c6738a8b942 rule
```

---

## Go / No-Go Checklist

Before running tests:
- [ ] Script copied to ~/.opencode/opencode-with-context
- [ ] Tamga project initialized (ctx init)
- [ ] big-pickle is default model in ocx script
- [ ] Context file exists: ~/.opencode/context/docs/7e304c6738a8b942/docs.jsonl
- [ ] jq is installed (for verification)

Ready to test:
- [ ] Run Test 1: Initial Onboarding
- [ ] Verify JSONL grew
- [ ] Run Test 2: Load Context
- [ ] Verify agent used saved knowledge
- [ ] Run Test 3: Extend Knowledge
- [ ] Verify progressive accumulation

Success:
- [ ] All 3 tests passed
- [ ] Docs grew from 11 → 25+ → 35+
- [ ] Each agent built on previous knowledge
- [ ] No errors in any session

---

**Ready to run the PoC?** 🚀

Start with Test 1!
