# Quick Start: Agent Onboarding for Projects

## The Idea

Instead of every agent figuring out how a project works, **one agent onboards the project once**, documents everything, and saves it to ctx. Future agents automatically inherit this knowledge.

## One-Time Setup Per Project

### Step 1: Run Onboarding Session

For **Tamga Backend**:

```bash
ocx -c full 7e304c6738a8b942 "CRITICAL ONBOARDING SESSION - Learn to Work with This Project

Your task is to thoroughly explore and document how to work with this Django project.

PHASES:

1. EXPLORATION (30 min)
- Explore project structure
- Identify tech stack (Python, Django, pytest, etc.)
- Find available tools and commands
- Understand directory layout

2. DISCOVERY (20 min)
- Test each tool: uv, pytest, ruff, mypy, etc.
- See what commands do
- Document exact command syntax

3. DOCUMENTATION (30 min)
- Save findings with: run ctx add-doc 7e304c6738a8b942 rule|doc|note 'title' 'content'
- Document how to run tests
- Document project structure
- Document development workflow
- Document common issues

Key commands:
run ctx add-doc 7e304c6738a8b942 rule 'Test Execution' 'Use: uv run pytest'
run ctx add-doc 7e304c6738a8b942 doc 'Project Structure' 'apps/ has business logic...'
run ctx add-doc 7e304c6738a8b942 note 'Dev Workflow' '1) Edit 2) Test 3) Commit'

EXPECTED OUTPUT:
- 4-5 rules (how to run things)
- 2-3 docs (what things are)
- 5-6 notes (workflows and troubleshooting)
"
```

### Step 2: Agent Explores and Documents

During the session, the agent will:

```
✓ Explore the project
✓ Run commands to test them
✓ Save findings with ctx add-doc
✓ Document workflows
✓ Document troubleshooting
✓ Create a knowledge base
```

### Step 3: Verify Completion

After onboarding completes:

```bash
# Check what was saved
ctx list-docs 7e304c6738a8b942

# View all saved context
ctx get-docs 7e304c6738a8b942
```

## Using Saved Onboarding

### Future Agents Load It Automatically

```bash
# Next agent runs any task
ocx -c full 7e304c6738a8b942 "Fix the login bug"

# This agent automatically has:
✓ How to run tests (from onboarding)
✓ Project structure (from onboarding)
✓ Development workflow (from onboarding)
✓ Troubleshooting guide (from onboarding)
✓ Full code context
✓ Tool access

# Agent can work immediately without learning curve!
```

## Progressive Enhancement

### Session 1 (Initial Onboarding)
Agent 1 documents:
- Basic commands
- Project structure
- Main workflows
- Common issues

### Session 2 (Extension)
Agent 2 loads Agent 1's context, then adds:
- Advanced patterns
- Edge cases discovered
- Optimizations found
- More complex workflows

### Session 3+
Progressive enrichment of the knowledge base.

**Result**: Over time, the ctx database becomes incredibly rich with practical wisdom.

## When to Run Onboarding

| Scenario | Action |
|----------|--------|
| New project added to ctx | Run initial onboarding |
| Agent discovers new pattern | Extend with new note |
| New tool/workflow discovered | Add new rule or doc |
| Common issue found | Add to troubleshooting notes |
| Project changes significantly | Re-run onboarding |

## Using Helper Script

For faster onboarding, use the helper script:

```bash
# Save a rule
./agent-onboarding.sh 7e304c6738a8b942 rule "Test Command" "Use: uv run pytest"

# Save documentation
./agent-onboarding.sh 7e304c6738a8b942 doc "Directory Structure" "apps/ contains business logic..."

# Save a workflow
./agent-onboarding.sh 7e304c6738a8b942 workflow "Development Workflow"
# (Prompts you to describe the workflow)

# Show checklist
./agent-onboarding.sh 7e304c6738a8b942 checklist

# Verify completeness
./agent-onboarding.sh 7e304c6738a8b942 verify
```

## What Gets Documented

### Rules (How to Do Things)
```
✓ How to run tests
✓ How to lint code
✓ How to format code
✓ How to build/deploy
✓ How to run dev server
✓ How to run migrations
✓ Package management
```

### Docs (What Things Are)
```
✓ Project structure
✓ Technology stack
✓ Architecture overview
✓ Configuration files
✓ Design patterns
```

### Notes (Workflows & Troubleshooting)
```
✓ Development workflow
✓ Feature development
✓ Bug fixing process
✓ Testing strategy
✓ Common issues & solutions
✓ Performance tips
✓ Advanced patterns
```

## Complete Example Flow

### Tamga Backend Onboarding

**You run**:
```bash
ocx -c full 7e304c6738a8b942 "CRITICAL ONBOARDING SESSION - Explore and document this Django project"
```

**Agent explores**:
```bash
# In interactive TUI...
run cat README.md
run find . -type f -name "*.py" | head -20
run python --version
run uv --version
run uv run pytest --collect-only
run uv run ruff check .
run python manage.py migrate --help
```

**Agent documents**:
```bash
run ctx add-doc 7e304c6738a8b942 rule "Test Suite: Use 'uv run pytest' for all tests. Use 'uv run pytest -m fast' for quick unit tests. Tests in tests/ directory." "Test Commands"

run ctx add-doc 7e304c6738a8b942 rule "Code Quality: Run 'uv run ruff check .' to find issues. Run 'uv run ruff format .' to auto-format. Run 'uv run mypy .' for type checking." "Linting & Formatting"

run ctx add-doc 7e304c6738a8b942 rule "Django: Run 'python manage.py migrate' for database migrations. Run 'python manage.py runserver' to start dev server. Always use 'uv run' for packages." "Django Commands"

run ctx add-doc 7e304c6738a8b942 doc "Project Layout: apps/ (business logic), interfaces/ (API), project/ (Django settings), tests/ (pytest), config/ (configuration), envs/ (environment files)." "Directory Structure"

run ctx add-doc 7e304c6738a8b942 doc "Tech Stack: Python 3.12, Django 5, DRF, PostgreSQL, UV (package manager), pytest (testing), ruff (lint/format), mypy (type checking)." "Technology Stack"

run ctx add-doc 7e304c6738a8b942 note "Development: 1) Edit code 2) Run tests: uv run pytest 3) Format: uv run ruff format . 4) Type check: uv run mypy . 5) Commit" "Development Workflow"

run ctx add-doc 7e304c6738a8b942 note "Bug Fixing: 1) Create test that reproduces bug 2) Verify test fails 3) Read code 4) Fix bug 5) Verify test passes 6) Run full suite 7) Commit with 'fix:' prefix" "Bug Fixing Process"

run ctx add-doc 7e304c6738a8b942 note "Testing: Always run full suite before committing. Use pytest -m fast during dev for speed. Aim for high coverage of critical paths. Place tests in tests/." "Testing Strategy"

run ctx add-doc 7e304c6738a8b942 note "Issues: 1) pytest not found = run 'uv sync' 2) ModuleNotFoundError = check __init__.py 3) Database errors = run migrations 4) Import issues = check PYTHONPATH" "Troubleshooting"
```

**Session ends**. Context is saved.

**Next agent runs**:
```bash
ocx -c full 7e304c6738a8b942 "Fix the authentication bug in the login endpoint"
```

**Next agent immediately has**:
- How to run tests
- Project structure
- Development workflow
- Troubleshooting guide
- Full tool access

**Result**: Works efficiently, no learning curve! 🚀

## Benefits

### For Agents
- ✅ Know exactly how to work with project
- ✅ No trial and error
- ✅ Can follow established patterns
- ✅ Know how to troubleshoot
- ✅ Work more efficiently

### For Projects
- ✅ Living documentation
- ✅ Best practices preserved
- ✅ Knowledge transfer automated
- ✅ Consistent workflows
- ✅ New agents onboarded faster

### For Teams
- ✅ AI agents work better together
- ✅ Knowledge compounds over time
- ✅ Progressive improvements
- ✅ Less human micromanagement
- ✅ Better AI assistance overall

## Getting Started

### For Tamga Backend (Right Now!)

```bash
# Copy the prompt from AGENT_ONBOARDING_PROMPT.md

# Run it
ocx -c full 7e304c6738a8b942 "CRITICAL ONBOARDING SESSION

[paste prompt from AGENT_ONBOARDING_PROMPT.md]
"

# After it completes, verify:
ctx list-docs 7e304c6738a8b942
```

### For Any Other Project

```bash
# 1. Initialize project
ctx init /path/to/project "Project Name"

# 2. Index it
ctx reindex <project-id>

# 3. Run onboarding
ocx -c full <project-id> "CRITICAL ONBOARDING SESSION

Explore this project thoroughly and document how to work with it.

PHASES:
1. EXPLORATION: Find structure, tech stack, tools (30 min)
2. DISCOVERY: Test each tool/command (20 min)
3. DOCUMENTATION: Save learnings with ctx add-doc (30 min)
4. VERIFICATION: Verify all was saved (5 min)

Key: Use 'run' to actually test. Save frequently with ctx add-doc.
"
```

## FAQ

**Q: How long does onboarding take?**
A: ~1.5-2 hours of agent time for initial comprehensive onboarding.

**Q: Can multiple agents onboard?**
A: Yes! Each can extend previous onboarding. Creates richer knowledge base.

**Q: What if project changes?**
A: Run onboarding again or just add new notes with agent-onboarding.sh

**Q: Do agents actually save context?**
A: Yes, if you include `ctx add-doc` commands in the onboarding prompt.

**Q: Can I manually add context?**
A: Yes! Use `ctx add-doc` directly or the agent-onboarding.sh script.

**Q: Does it work for all project types?**
A: Yes! Adjust the onboarding prompt for your project type.

## Next Steps

1. Run onboarding for Tamga Backend (use AGENT_ONBOARDING_PROMPT.md)
2. Verify context was saved with `ctx list-docs`
3. Next agent will automatically load it
4. Over time, knowledge base becomes incredibly rich
5. Future agents can extend it further

**You've created a system where agents teach agents!** 🎓
