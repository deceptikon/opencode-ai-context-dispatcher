#!/bin/zsh

# Auto-detect project and load context
autoload -U add-zsh-hook

# Platform detection for date commands
_ctx_platform() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

_ctx_timestamp_days_ago() {
    local days="$1"
    if [[ "$(_ctx_platform)" == "macos" ]]; then
        date -v-${days}d +%s
    else
        date -d "$days days ago" +%s
    fi
}

_ctx_parse_timestamp() {
    local timestamp="$1"
    if [[ "$(_ctx_platform)" == "macos" ]]; then
        date -j -f "%Y-%m-%dT%H:%M:%S%z" "$timestamp" +%s 2>/dev/null || \
        date -j -f "%Y-%m-%dT%H:%M:%S" "${timestamp%+*}" +%s 2>/dev/null || echo "0"
    else
        date -d "$timestamp" +%s 2>/dev/null || echo "0"
    fi
}

function auto_context() {
    if [[ -d ".git" ]]; then
        local project_path=$(pwd)
        local project_id=$(echo -n "$project_path" | shasum -a 256 | cut -d' ' -f1 | cut -c 1-16)

        # Check if project is initialized
        if [[ -f "$HOME/.opencode/context/projects/$project_id/config.json" ]]; then
            export CURRENT_PROJECT="$project_id"

            # Auto-update context if older than 1 day
            local last_indexed=$(jq -r '.last_indexed' "$HOME/.opencode/context/projects/$project_id/config.json")
            local one_day_ago=$(_ctx_timestamp_days_ago 1)
            local indexed_time=$(_ctx_parse_timestamp "$last_indexed")
            
            if [[ "$last_indexed" == "null" ]] || [[ "$indexed_time" -lt "$one_day_ago" ]]; then
                context update "$project_id" >/dev/null 2>&1 &
            fi
        fi
    fi
}
add-zsh-hook chpwd auto_context

# Alias for quick context commands
alias ctx="source $HOME/.opencode/context-dispatcher.zsh && context"
alias ocx="$HOME/.opencode/opencode-with-context"
