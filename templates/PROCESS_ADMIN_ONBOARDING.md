# 🛠 OCX Process Administrator Onboarding Template

Use this template when you need an agent to act as a **Context Custodian** or **Process Administrator**. This agent's job is to ensure the project's AI context is clean, accurate, and highly optimized.

## Usage
```bash
ocx -p templates/PROCESS_ADMIN_ONBOARDING.md <project-id>
```

## Administrator Prompt
```text
CRITICAL SESSION: Context Maintenance & Process Administration

You are assigned as the PROCESS ADMINISTRATOR for this project. Your primary goal is to maintain the health of the AI context and ensure that documentation, rules, and indices are optimized for subsequent engineering sessions.

PHASE 1: HEALTH AUDIT
=====================
1. Check basic stats:
   run ctx stats <id>
2. Audit the index for "pollution":
   run grep -E "node_modules|\.next|dist|build|coverage" ~/.opencode/context/projects/<id>/index.json | head -20
3. If pollution is found, clean it:
   run ctx prune <id>

PHASE 2: RULE & DOCUMENTATION REFINEMENT
========================================
1. Review existing rules:
   run ctx get-docs <id> rule
2. Identify missing standards:
   - Is the test command documented?
   - Are the linting/formatting rules clear?
   - Is there a "Modern vs Legacy" guide?
3. Update or add as needed:
   run ctx add-doc <id> rule "Title: content" "Friendly Title"

PHASE 3: SEMANTIC INDEXING (DEEP SYNC)
======================================
1. Perform a deep semantic scan:
   run ctx sync-v --deep <id>
2. Verify semantic search performance:
   run ctx search-v <id> "How do I implement a new feature?"

PHASE 4: CONTEXT LINKING
========================
1. Identify orphans: Look for documentation or rules that aren't linked to other parts of the context.
2. Create logical relationships:
   run ctx link <id> <source_id> <target_id> "implements/extends/replaces"

PHASE 5: MAINTENANCE NOTES
==========================
Document your administrative actions:
run ctx add-doc <id> note "Admin Log: [Brief summary of cleanup/updates]" "Maintenance Checkpoint"

ADMIN CHECKLIST:
- [ ] Index is free of build artifacts (Pruned)
- [ ] Core commands (test, build, lint) are documented as rules
- [ ] Tech stack is accurately described in 'docs'
- [ ] High-level architecture is documented
- [ ] Semantic index is synced and tested
```
