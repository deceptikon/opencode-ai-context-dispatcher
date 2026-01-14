#!/bin/bash
# Agent Onboarding Helper Script
# Helps agents document what they learn during onboarding session

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat <<EOF
${BLUE}Agent Onboarding Helper${NC}

Usage: agent-onboarding [OPTIONS] <project-id> <command>

Commands:
  rule <title> <content>      Save a discovered rule (how to run things)
  doc <title> <content>       Save project documentation
  note <title> <content>      Save a workflow or troubleshooting note
  
  workflow <title>            Save a workflow pattern (interactive)
  checklist                   Show onboarding checklist
  verify                      Verify onboarding completeness

Options:
  -q, --quiet                 Suppress output
  -h, --help                  Show this help

Examples:
  agent-onboarding 7e304c6738a8b942 rule "Test Command" "Use: uv run pytest"
  agent-onboarding 7e304c6738a8b942 doc "Directory Structure" "apps/ contains business logic..."
  agent-onboarding 7e304c6738a8b942 note "Dev Workflow" "1. Edit code 2. Run tests 3. Commit"

EOF
}

# Parse arguments
QUIET=false
PROJECT_ID=""
COMMAND=""
TITLE=""
CONTENT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [[ -z "$PROJECT_ID" ]]; then
                PROJECT_ID="$1"
            elif [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            elif [[ -z "$TITLE" ]]; then
                TITLE="$1"
            elif [[ -z "$CONTENT" ]]; then
                CONTENT="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$PROJECT_ID" ]] || [[ -z "$COMMAND" ]]; then
    echo "Error: project-id and command required"
    show_help
    exit 1
fi

# Load context dispatcher
DISPATCHER="$HOME/.opencode/context-dispatcher.zsh"
if [[ ! -f "$DISPATCHER" ]]; then
    echo "Error: Context dispatcher not found at $DISPATCHER"
    exit 1
fi

# Helper function
save_doc() {
    local type=$1
    local title=$2
    local content=$3
    
    zsh -c "
        source '$DISPATCHER'
        add_doc '$PROJECT_ID' '$type' \"$content\" \"$title\"
    " 2>/dev/null || true
}

show_success() {
    if [[ "$QUIET" == "false" ]]; then
        echo -e "${GREEN}✓${NC} Saved: $1"
    fi
}

# Process command
case "$COMMAND" in
    rule)
        if [[ -z "$TITLE" ]] || [[ -z "$CONTENT" ]]; then
            echo "Error: rule requires <title> <content>"
            exit 1
        fi
        save_doc "rule" "$TITLE" "$CONTENT"
        show_success "Rule: $TITLE"
        ;;
    
    doc)
        if [[ -z "$TITLE" ]] || [[ -z "$CONTENT" ]]; then
            echo "Error: doc requires <title> <content>"
            exit 1
        fi
        save_doc "doc" "$TITLE" "$CONTENT"
        show_success "Doc: $TITLE"
        ;;
    
    note)
        if [[ -z "$TITLE" ]] || [[ -z "$CONTENT" ]]; then
            echo "Error: note requires <title> <content>"
            exit 1
        fi
        save_doc "note" "$TITLE" "$CONTENT"
        show_success "Note: $TITLE"
        ;;
    
    workflow)
        if [[ -z "$TITLE" ]]; then
            echo "Error: workflow requires <title>"
            exit 1
        fi
        echo -e "${BLUE}Describe the workflow for: $TITLE${NC}"
        echo "(Type your workflow description, then Ctrl+D when done)"
        CONTENT=$(cat)
        save_doc "note" "$TITLE (Workflow)" "$CONTENT"
        show_success "Workflow: $TITLE"
        ;;
    
    checklist)
        cat <<EOF
${BLUE}Onboarding Checklist for $PROJECT_ID${NC}

Essential (Must Have):
  [ ] How to run tests
  [ ] How to lint/format code
  [ ] How to build (if applicable)
  [ ] Project directory structure
  [ ] Development workflow

Important (Should Have):
  [ ] How to run development server
  [ ] Database commands (if applicable)
  [ ] How to add a new feature
  [ ] Code patterns and conventions
  [ ] Common troubleshooting issues

Nice to Have:
  [ ] Deployment process
  [ ] Performance optimization tips
  [ ] Advanced workflows
  [ ] Architecture overview
  [ ] Contributing guidelines

Verify with: ctx list-docs $PROJECT_ID
EOF
        ;;
    
    verify)
        zsh -c "
            source '$DISPATCHER'
            echo ''
            echo '${BLUE}Onboarding Documentation for $PROJECT_ID${NC}'
            echo ''
            
            echo 'Rules:'
            get_docs '$PROJECT_ID' rule 2>/dev/null | wc -l || echo '0'
            
            echo ''
            echo 'Docs:'
            get_docs '$PROJECT_ID' doc 2>/dev/null | wc -l || echo '0'
            
            echo ''
            echo 'Notes:'
            get_docs '$PROJECT_ID' note 2>/dev/null | wc -l || echo '0'
        " 2>/dev/null || echo "Error verifying context"
        ;;
    
    *)
        echo "Error: Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
