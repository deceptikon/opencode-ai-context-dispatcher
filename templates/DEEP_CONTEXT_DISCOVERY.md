# 🔍 Deep Context Discovery Prompt

Use this prompt when you need to go beyond basic structure and understand complex relationships, hidden patterns, and architectural decisions.

## Usage
```bash
ocx -p templates/DEEP_CONTEXT_DISCOVERY.md <project-id>
```

## Discovery Prompt
```text
CRITICAL ANALYSIS SESSION - Deep Architectural Discovery

Your goal is to uncover the "hidden" context of this project. Move beyond file lists and explore the logic, dependencies, and decisions.

PHASE 1: DEPENDENCY GRAPH & ENTRY POINTS
========================================
1. Map the entry points:
   - What are the main binaries/scripts?
   - How does the application boot?
   - Document in: ctx add-doc <id> doc "Entry Points: [list and describe]" "System Entry Points"

2. Analyze dependencies:
   - Identify 3-5 core libraries. What is their role?
   - Are there any unusual or custom dependencies?
   - Document in: ctx add-doc <id> doc "Core Dependencies: [library -> purpose]" "Tech Stack Deep Dive"

PHASE 2: DATA FLOW & STATE
==========================
1. Trace a single data flow:
   - Choose a core feature (e.g., User Login, Data Processing).
   - Trace it from API/CLI entry to Database/Storage.
   - Document in: ctx add-doc <id> note "Data Flow: [Step-by-step trace of Feature X]" "Workflow: Core Logic"

2. Identify State Management:
   - Where is the "truth" stored? (DB, Cache, Memory, Global Store)
   - How is it accessed and modified?

PHASE 3: PATTERN RECOGNITION (The "How" and "Why")
==================================================
1. Find common coding patterns:
   - Error handling: try/except, result objects, middleware?
   - Concurrency: async/await, threads, workers?
   - Testing: mocks, fixtures, integration DBs?
   - Document in: ctx add-doc <id> rule "Pattern: [Description of pattern]" "Project Pattern: [Name]"

2. Look for "Legacy" vs "Modern" code:
   - Are there multiple ways of doing the same thing?
   - Which one is the current standard?
   - Document in: ctx add-doc <id> note "Code Standards: Use [Modern Way] instead of [Legacy Way]" "Modernization Guide"

PHASE 4: LINKING CONTEXT
========================
For each discovery, identify related files:
- If a 'doc' describes a service, find its main implementation and its main test.
- Use: ctx link <id> <source_doc_id> <target_doc_id> "implements/tests"

SUMMARY TASK
============
Create a "Mental Map" of the project:
1. What is the most complex part of the code?
2. What part is most fragile (breaks easily)?
3. What is the "Golden Path" for adding a new feature?
```
