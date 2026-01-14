# Agent Onboarding Prompt Template

Use this prompt to run a comprehensive onboarding session for any project.

## For Tamga Backend Project

```
CRITICAL ONBOARDING SESSION - Learn to Work with This Project

Your task is to thoroughly explore and document how to work with this Django project.
You will save everything you learn so future agents can work effectively.

IMPORTANT: Use 'run' bash tool to explore. Actually test things, don't just read.

PHASE 1: EXPLORATION (30 min)
===============================

1. Understand the project structure
   run find . -type f -name "README*" -o -name "*.md" | head -20
   run cat README.md
   run ls -la
   run find . -maxdepth 2 -type d | head -20

2. Identify the tech stack
   run cat pyproject.toml 2>/dev/null || cat requirements.txt 2>/dev/null || echo "No requirements found"
   run python --version
   run which uv && uv --version || echo "UV not installed"
   run which pytest && pytest --version || echo "pytest not found"
   run which ruff && ruff --version || echo "ruff not found"

3. Explore project structure deeply
   run find . -name "tests" -o -name "test_*" -type f | head -10
   run find . -name "apps" -type d
   run find . -name "interfaces" -type d
   run ls -la apps/ 2>/dev/null | head -10

4. Understand build/test setup
   run uv run pytest --collect-only 2>&1 | head -30
   run uv run ruff check . --select=F 2>&1 | head -10
   run cat .github/workflows/*.yml 2>/dev/null | head -20 || echo "No CI workflows"

PHASE 2: COMMAND DISCOVERY (20 min)
====================================

Test each command and document what it does:

1. Testing
   run uv run pytest --help 2>&1 | head -5
   run uv run pytest -m fast --collect-only 2>&1 | head -10

2. Code Quality
   run uv run ruff check --help 2>&1 | head -5
   run uv run ruff format --help 2>&1 | head -5
   run uv run mypy --help 2>&1 | head -5

3. Database (if applicable)
   run python manage.py --help 2>&1 | head -10
   run python manage.py migrate --help 2>&1 | head -5

4. Development
   run python manage.py runserver --help 2>&1 | head -5

PHASE 3: DOCUMENTATION (30 min)
=================================

Save everything using these commands:

run ctx add-doc <project-id> rule "Test Execution: Use 'uv run pytest' for full test suite. Use 'uv run pytest -m fast' for quick unit tests only." "Test Commands"

run ctx add-doc <project-id> rule "Code Quality: Use 'uv run ruff check .' to find lint issues. Use 'uv run ruff format .' to auto-format code. Use 'uv run mypy .' for type checking." "Linting and Formatting"

run ctx add-doc <project-id> rule "Running Django: Use 'python manage.py migrate' for database migrations. Use 'python manage.py runserver' for development server. Use 'uv run' prefix for packages in pyproject.toml." "Django Commands"

run ctx add-doc <project-id> doc "Project Structure: apps/ contains Django apps with business logic, interfaces/ has DRF API views, project/ contains Django settings, tests/ contains pytest test suite. Config files in config/ and envs/." "Directory Structure"

run ctx add-doc <project-id> doc "Tech Stack: Python 3.12+, Django 5, Django REST Framework, PostgreSQL database, UV for dependency management, pytest for testing, ruff for linting/formatting, mypy for type checking." "Technology Stack"

run ctx add-doc <project-id> note "Development Workflow: 1) Create feature branch 2) Edit code in apps/ 3) Run tests: uv run pytest 4) If tests fail, read error and fix code 5) Re-run tests 6) Format: uv run ruff format . 7) Type check: uv run mypy . 8) Commit with clear message" "Daily Development Workflow"

run ctx add-doc <project-id> note "Adding a Feature: 1) Identify which app needs the feature 2) Add models, views, serializers 3) Create tests first (TDD) 4) Implement feature 5) Run full test suite 6) Update docstrings 7) Commit" "Feature Development Workflow"

run ctx add-doc <project-id> note "Fixing a Bug: 1) Write test that reproduces bug 2) Verify test fails 3) Read code to understand issue 4) Fix the code 5) Verify test passes 6) Run full suite 7) Search for similar patterns 8) Commit with 'fix: ' prefix" "Bug Fixing Workflow"

run ctx add-doc <project-id> note "Testing Strategy: Always run 'uv run pytest' before committing. Use 'uv run pytest -m fast' during development for speed. Tests should be in tests/ directory. Aim for high coverage of critical paths." "Testing Best Practices"

run ctx add-doc <project-id> note "Common Issues & Solutions: 1) 'command not found: uv' - Need to install uv first. 2) 'pytest not found' - Run 'uv sync' to install dependencies. 3) 'ModuleNotFoundError' - Check __init__.py exists and PYTHONPATH is correct. 4) Database errors - Run 'python manage.py migrate' first." "Troubleshooting"

PHASE 4: VERIFICATION
======================

Verify everything was saved:
run ctx list-docs <project-id>

Should see:
- At least 4-5 rules (how to run things)
- At least 2-3 docs (what things are)
- At least 5-6 notes (workflows and troubleshooting)

PHASE 5: EXTENSIONS (if time allows)
======================================

Document any additional patterns you found:

For each additional pattern found:
run ctx add-doc <project-id> note "Pattern Name: description of pattern and why it's used in this project" "Pattern: Pattern Name"

Examples:
- Design patterns used (factory, decorator, etc.)
- API design patterns
- Database query patterns
- Error handling patterns
- Testing patterns
- Configuration management

FINAL: META-DOCUMENTATION
==========================

If you discover something about how agents should work with THIS project:
run ctx add-doc <project-id> rule "Agent Guideline: What agents should know when working with this project" "Agent Guidelines for This Project"

Example:
run ctx add-doc <project-id> rule "When fixing tests: Read the test file first to understand what's being tested. Then read the implementation. The test is the contract, not the source of truth." "Test-Driven Understanding"

SUMMARY
=======

You have now:
✓ Explored the entire project structure
✓ Tested all available tools and commands
✓ Documented everything in ctx database
✓ Created a knowledge base for future agents
✓ Established workflows and best practices

Future agents will automatically load this knowledge when working on the project.
Your work enables them to be productive immediately without learning curve.

Thank you for onboarding this project!
```

## Generic Template (for any project)

Replace the project-specific details with your own:

```
CRITICAL ONBOARDING SESSION

Your task: Explore this project thoroughly and document how to work with it.
You will save everything so future agents can work effectively.

PHASES:
1. EXPLORATION: Find structure, tech stack, tools (30 min)
2. DISCOVERY: Test each tool/command (20 min)
3. DOCUMENTATION: Save learnings with ctx add-doc (30 min)
4. VERIFICATION: Verify all was saved (5 min)
5. EXTENSION: Document additional patterns (if time) (15 min)

Key points:
- Use 'run' tool to actually test things
- Document rationale, not just commands
- Save frequently with ctx add-doc
- Include troubleshooting
- Cross-reference between docs
```

## Running the Onboarding

```bash
# Copy the prompt from above (or adjust for your project)

# Run onboarding session
ocx -c full 7e304c6738a8b942 "CRITICAL ONBOARDING SESSION - Learn to Work with This Project

Your task is to thoroughly explore and document...
[paste the full prompt above]
"

# Or save it to a file and reference it:
cat > /tmp/onboarding.txt <<'EOF'
[paste prompt]
EOF

ocx -c full 7e304c6738a8b942 "$(cat /tmp/onboarding.txt)"
```

## Helper Script Usage

After onboarding, agents (or you) can use the helper to quickly document things:

```bash
# Add a rule
./agent-onboarding.sh 7e304c6738a8b942 rule "Test Command" "Use: uv run pytest -m fast"

# Add documentation
./agent-onboarding.sh 7e304c6738a8b942 doc "API Patterns" "All endpoints use JSON-RPC..."

# Add a note
./agent-onboarding.sh 7e304c6738a8b942 note "Cache Strategy" "Uses Redis for session caching..."

# Show checklist
./agent-onboarding.sh 7e304c6738a8b942 checklist

# Verify completeness
./agent-onboarding.sh 7e304c6738a8b942 verify
```

## Why This Works

1. **Agent learns by doing**: Actually runs commands, tests tools
2. **Knowledge is captured**: Saves to ctx database
3. **Future agents inherit**: Automatically loaded with context
4. **Living documentation**: Can be extended in future sessions
5. **Practical wisdom**: Troubleshooting, patterns, workflows
6. **Progressive enhancement**: Each agent can extend the knowledge base

## Expected Outcomes

After onboarding, future agents can:
- ✅ Know exact commands to use for any operation
- ✅ Understand project structure immediately
- ✅ Follow established workflows
- ✅ Troubleshoot common issues
- ✅ Work efficiently without trial-and-error
- ✅ Extend the knowledge base for next agents
