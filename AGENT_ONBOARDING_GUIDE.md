# Agent Onboarding System

## Purpose

Enable agents to **learn how to work with a specific project** in one comprehensive session, then save that knowledge for all future agents to use.

## How It Works

### One-Time Setup Per Project

1. **Run onboarding session**
   ```bash
   ocx -c full <project-id> "ONBOARDING: Learn and document how to work with this project"
   ```

2. **Agent explores and learns**
   - Reads README and documentation
   - Discovers project structure
   - Identifies available tools and commands
   - Tests workflows (running tests, building, linting, etc.)
   - Documents patterns and best practices

3. **Agent saves learnings**
   Using `ctx add-doc` commands, agent saves:
   - **Tools & Commands**: How to run tests, build, lint, etc.
   - **Project Structure**: What each directory contains
   - **Best Practices**: Patterns used in this project
   - **Workflow Examples**: Step-by-step guides for common tasks
   - **Troubleshooting**: Common issues and solutions

4. **Future agents inherit knowledge**
   All subsequent agents automatically load the onboarding context

## What Should Be Documented

### Tools & Commands (RULES)
```
✓ How to run tests
✓ How to build/compile
✓ How to lint/format
✓ How to deploy
✓ Database commands (migrations, seeds, etc.)
✓ Development server startup
✓ Package management
```

### Project Structure (DOCS)
```
✓ Directory layout
✓ File organization
✓ What each module does
✓ Important configuration files
✓ Entry points
```

### Workflows (NOTES)
```
✓ Development workflow (edit → test → commit)
✓ Adding a new feature (step-by-step)
✓ Fixing a bug (investigation → fix → verify)
✓ Code review process
✓ Testing strategy
```

### Troubleshooting (NOTES)
```
✓ Common errors and solutions
✓ Environment setup issues
✓ Dependency problems
✓ Database issues
```

## Example Onboarding Session

For **Tamga Backend** project:

```bash
# 1. Start onboarding
ocx -c full 7e304c6738a8b942 "ONBOARDING: Explore this Django project and document everything"

# In the interactive TUI, agent:

# 2. Explores the project
run ls -la
run cat README.md
run find . -name "*.md" -type f | head -20
run find . -type f -name "requirements*.txt" -o -name "pyproject.toml" -o -name "uv.lock"

# 3. Discovers tools
run uv --version
run python --version
run which pytest
run which ruff
run which mypy

# 4. Tests workflows
run uv run pytest --collect-only 2>&1 | head -20
run uv run ruff check . --select=F 2>&1 | head -20

# 5. Documents findings
run ctx add-doc 7e304c6738a8b942 rule "Test Execution: Use 'uv run pytest' for running tests. Use 'uv run pytest -m fast' for quick unit tests." "Test Execution Commands"

run ctx add-doc 7e304c6738a8b942 rule "Code Quality: Use 'uv run ruff check .' for linting and 'uv run ruff format .' for formatting. Use 'uv run mypy .' for type checking." "Code Quality Commands"

run ctx add-doc 7e304c6738a8b942 doc "Project Structure: apps/ contains business logic, interfaces/ has API definitions, project/ has Django settings, tests/ has pytest suite." "Directory Structure"

run ctx add-doc 7e304c6738a8b942 note "Development Workflow: 1) Create feature branch 2) Make changes in apps/ 3) Run tests: uv run pytest 4) Format: uv run ruff format . 5) Check types: uv run mypy . 6) Commit with clean history" "Development Workflow"

run ctx add-doc 7e304c6738a8b942 note "Testing Strategy: Run 'uv run pytest -m fast' for quick unit tests during development. Run 'uv run pytest' before committing for full suite. Tests are in tests/ directory." "Testing Strategy"

run ctx add-doc 7e304c6738a8b942 note "Common Issues: If pytest not found, ensure uv sync was run. If import errors: check __init__.py files exist. If database errors: uv run python manage.py migrate" "Troubleshooting"

# 6. Session ends - all context is saved
```

## Running Onboarding

### For New Project
```bash
# 1. Initialize project in ctx
ctx init /path/to/project "Project Name"

# 2. Index the codebase
ctx reindex <project-id>

# 3. Run onboarding session
ocx -c full <project-id> "ONBOARDING: Explore this project and document how to work with it"
```

### For Existing Project
```bash
# Just run onboarding to add more learnings
ocx -c full 7e304c6738a8b942 "ONBOARDING: Document any missing workflows or patterns"
```

## Benefits

### For Agents
- Start with deep project knowledge
- Know exact commands to use
- Understand project patterns
- Have troubleshooting guide
- Work more efficiently

### For Humans
- Agents work better (no trial-and-error)
- Consistent workflows across sessions
- Knowledge preserved
- New team members (agents) onboarded faster
- Project documentation updated by AI

### For Projects
- Living documentation
- Best practices documented
- Common issues catalogued
- Workflow standardized
- Knowledge transfer automated

## Checklist for Complete Onboarding

After agent onboarding, verify with:
```bash
ctx list-docs <project-id>
```

Should have:
- [ ] At least 3-5 rules (how to run things)
- [ ] At least 2-3 docs (what things are)
- [ ] At least 3-5 notes (workflows and troubleshooting)
- [ ] Each document has clear, actionable content

## Integration with ocx

The updated `ocx` system automatically:
1. ✅ Loads all saved onboarding context
2. ✅ Presents it to agents
3. ✅ Enables tools for agents to save more
4. ✅ Makes it available to next agents

## Meta-Learning: Agents Teaching Agents

Future agents can extend onboarding:
```bash
ocx -c full <project-id> "ONBOARDING EXTEND: Add more patterns or workflows we discovered"
```

This creates a **learning loop**:
- Agent 1: Onboards, saves context
- Agent 2: Loads context, extends it, saves more
- Agent 3: Loads extended context, improves further
- ...

Over time, the onboarding context becomes **richer and more comprehensive**.

## Example: Progressive Enhancement

### Session 1 (Initial Onboarding)
```
Rules: 5 items (basic commands)
Notes: 3 items (basic workflows)
```

### Session 2 (Extension)
```
Agent reads previous context, then adds:
Rules: 8 items (more edge cases)
Notes: 7 items (advanced workflows, edge cases, optimizations)
```

### Session 3+ 
```
Progressively richer context with:
- Performance tips
- Advanced patterns
- Common edge cases
- Optimization strategies
```

## Getting Started

```bash
# For Tamga Backend (example):
ocx -c full 7e304c6738a8b942 "ONBOARDING: Explore the Django project structure, test execution, code quality tools, and common workflows. Document everything needed for future agents to work effectively."

# Agent will:
# 1. Explore project files
# 2. Test all available tools
# 3. Document findings with ctx add-doc
# 4. Save context for future agents

# Then next agent can:
ocx -c full 7e304c6738a8b942 "Fix the authentication bug in user login"
# Will automatically have onboarding context!
```

## Pro Tips

1. **Be specific in onboarding prompt**
   - List what to explore: "Explore the project structure, test setup, build process, and code quality tools"

2. **Agent should test everything**
   - Don't just read files, actually run commands
   - Discover real behavior, not just intended behavior

3. **Save frequently during onboarding**
   - Use `ctx add-doc` after discovering each major piece

4. **Document rationale, not just commands**
   - "Why use uv run pytest?" → "Because project uses UV for dependency management"
   - Helps future agents understand context

5. **Include troubleshooting**
   - Common errors
   - How to fix them
   - Prevention tips

6. **Cross-reference between docs**
   - Link related rules and notes
   - Create a cohesive knowledge base
