# Generic Onboarding Prompt Template

Use this template for ANY project. Replace `<project-id>` with the actual project ID.

## Usage

```bash
# Get your project ID
ctx list

# Run onboarding with the prompt below (replace <project-id>)
ocx -c full <project-id> "[paste the prompt below]"
```

## Generic Onboarding Prompt

```
CRITICAL ONBOARDING SESSION - Learn to Work with This Project

Your task is to thoroughly explore and document how to work with this project.
You will save everything you learn so future agents can work effectively.

IMPORTANT: Use 'run' bash tool to explore. Actually test things, don't just read.

PHASE 1: EXPLORATION (30 min)
===============================

1. Understand the project structure
   run find . -type f -name "README*" -o -name "*.md" | head -20
   run cat README.md
   run ls -la
   run find . -maxdepth 2 -type d | head -20

2. Identify the tech stack and tools
   run cat pyproject.toml 2>/dev/null || cat requirements.txt 2>/dev/null || cat package.json 2>/dev/null || echo "No package file found"
   run python --version 2>/dev/null || node --version 2>/dev/null || ruby --version 2>/dev/null || echo "No language found"
   run which uv && uv --version || echo "UV not available"
   run which pytest && pytest --version || echo "pytest not available"
   run which npm && npm --version || echo "npm not available"
   run which ruff && ruff --version || echo "ruff not available"

3. Explore project structure deeply
   run find . -name "tests" -o -name "test_*" -o -name "spec_*" -type d | head -10
   run find . -name "src" -o -name "app" -o -name "apps" -type d | head -10
   run ls -la | grep -E "Makefile|package.json|pyproject.toml|go.mod|Cargo.toml" || echo "No build files found"

4. Check for CI/CD and scripts
   run cat .github/workflows/*.yml 2>/dev/null | head -20 || echo "No GitHub Actions"
   run cat .gitlab-ci.yml 2>/dev/null || echo "No GitLab CI"
   run ls scripts/ 2>/dev/null || echo "No scripts directory"
   run cat Makefile 2>/dev/null | head -30 || echo "No Makefile"

PHASE 2: COMMAND DISCOVERY (20 min)
====================================

Test available commands and document them:

1. Build/Run commands
   run make help 2>/dev/null || echo "No make"
   run npm run 2>/dev/null || echo "No npm scripts"
   run python -m --help 2>/dev/null || echo "Check python modules"

2. Test commands
   run which pytest && pytest --co 2>&1 | head -5 || echo "pytest not available"
   run which go && go test ./... -count=1 2>&1 | head -10 || echo "Go not available"
   run which cargo && cargo test --lib 2>&1 | head -5 || echo "Cargo not available"

3. Code quality/linting
   run which ruff && ruff check . 2>&1 | head -5 || echo "ruff not available"
   run which pylint && pylint --version || echo "pylint not available"
   run which eslint && eslint --version 2>/dev/null || echo "eslint not available"

4. Documentation
   run find . -name "*.md" | head -10
   run which sphinx-build && sphinx-build --version 2>/dev/null || echo "Sphinx not available"

PHASE 3: DOCUMENTATION (30 min)
=================================

Save EVERYTHING using ctx add-doc. Replace <project-id> with actual ID.

Based on what you discovered, save the following (customize for your project):

Rule templates (how to RUN things):
  run ctx add-doc <project-id> rule "Testing: [exact command to run all tests. e.g., 'pytest' or 'uv run pytest' or 'npm test']" "Test Execution Command"

  run ctx add-doc <project-id> rule "Code Quality: [exact commands for linting and formatting. e.g., 'ruff check .' and 'ruff format .']" "Code Quality Commands"

  run ctx add-doc <project-id> rule "Building/Running: [exact commands to build and run project. e.g., 'make build' or 'npm run dev' or 'python manage.py runserver']" "Build and Run Commands"

Doc templates (what THINGS are):
  run ctx add-doc <project-id> doc "Project Structure: [describe directory layout - what each folder contains. e.g., 'src/ has source code, tests/ has test suite, etc.']" "Directory Structure"

  run ctx add-doc <project-id> doc "Technology Stack: [list technologies used. e.g., 'Python 3.12, Django 5, PostgreSQL, pytest, ruff']" "Technology Stack"

  run ctx add-doc <project-id> doc "Architecture: [describe how the project is organized. e.g., 'MVC pattern, REST API, microservices, etc.']" "Architecture Overview"

Note templates (WORKFLOWS and troubleshooting):
  run ctx add-doc <project-id> note "Development Workflow: 1) Create branch 2) Make changes 3) Run tests 4) Format code 5) Commit" "Daily Development"

  run ctx add-doc <project-id> note "Testing Strategy: Always run full test suite before committing. Use fast test mode during development if available." "Testing Best Practices"

  run ctx add-doc <project-id> note "Common Issues: [list any common errors you encountered and how to fix them. e.g., 'If pytest not found, run uv sync']" "Troubleshooting"

  run ctx add-doc <project-id> note "Adding Features: [step-by-step guide for adding new feature]" "Feature Development Workflow"

  run ctx add-doc <project-id> note "Bug Fixing: [step-by-step guide for fixing bugs]" "Bug Fixing Workflow"

PHASE 4: VERIFICATION
======================

Verify everything was saved:
  run ctx list-docs <project-id>

Should see:
  - At least 3 rules (commands)
  - At least 2 docs (structure, stack, architecture)
  - At least 3 notes (workflows, best practices, troubleshooting)

PHASE 5: FINAL CHECK
====================

Confirm all ctx add-doc commands executed successfully (look for ✓ messages).
If any failed, re-run them manually.
```

## Tips

1. **Customize based on project type**:
   - Python: pytest, ruff, mypy
   - Node.js: npm, eslint, jest
   - Go: go test, golangci-lint
   - Rust: cargo test, clippy

2. **Actually test commands**: Don't just read documentation, run them
   
3. **Document what you find**: Save exact commands, not general descriptions

4. **Be specific**: Instead of "use tests", save "use pytest -m fast for quick tests"

5. **Include troubleshooting**: Document any errors you encounter and how you fixed them

## Example: For Different Project Types

### Python Django Project
```
run ctx add-doc <id> rule "Testing: uv run pytest for all tests, uv run pytest -m fast for quick tests" "Test Command"
run ctx add-doc <id> rule "Django: python manage.py migrate for migrations, python manage.py runserver for dev server" "Django Commands"
run ctx add-doc <id> doc "Structure: apps/ has Django apps, tests/ has test suite, project/ has settings" "Directory Structure"
```

### Node.js Project
```
run ctx add-doc <id> rule "Testing: npm test for all tests, npm run test:unit for unit tests" "Test Command"
run ctx add-doc <id> rule "Development: npm run dev to start development server, npm run build to build" "Dev Commands"
run ctx add-doc <id> doc "Structure: src/ has source code, tests/ has test suite, dist/ is build output" "Directory Structure"
```

### Go Project
```
run ctx add-doc <id> rule "Testing: go test ./... to run all tests, go test -race to check race conditions" "Test Command"
run ctx add-doc <id> rule "Building: go build to build binary, go run main.go to run" "Build Command"
run ctx add-doc <id> doc "Structure: cmd/ has executables, pkg/ has libraries, internal/ has private code" "Directory Structure"
```

---

**The key**: Discover what's UNIQUE about YOUR project and document it so future agents know exactly what to do!
