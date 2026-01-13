#!/bin/zsh
# Context Dispatcher v1.0 for AI Agents

CONTEXT_ROOT="$HOME/.opencode/context"
PROJECTS_DIR="$CONTEXT_ROOT/projects"
AGENTS_DIR="$CONTEXT_ROOT/agents"
CACHE_DIR="$CONTEXT_ROOT/cache"
LOG_FILE="$CONTEXT_ROOT/logs/context.log"

# Ensure directories exist
mkdir -p {$PROJECTS_DIR,$AGENTS_DIR,$CACHE_DIR,$CONTEXT_ROOT/logs}

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}
PLATFORM=$(detect_platform)

# Cross-platform stat: get modification time
get_mtime() {
    local file="$1"
    if [[ "$PLATFORM" == "macos" ]]; then
        stat -f "%m" "$file" 2>/dev/null || echo "0"
    else
        stat -c "%Y" "$file" 2>/dev/null || echo "0"
    fi
}

# Cross-platform stat: get file size
get_fsize() {
    local file="$1"
    if [[ "$PLATFORM" == "macos" ]]; then
        stat -f "%z" "$file" 2>/dev/null || echo "0"
    else
        stat -c "%s" "$file" 2>/dev/null || echo "0"
    fi
}

# Cross-platform date: get timestamp from N days ago
get_timestamp_days_ago() {
    local days="$1"
    if [[ "$PLATFORM" == "macos" ]]; then
        date -v-${days}d +%s
    else
        date -d "$days days ago" +%s
    fi
}

# Cross-platform date: parse ISO timestamp to epoch
parse_iso_timestamp() {
    local timestamp="$1"
    if [[ "$PLATFORM" == "macos" ]]; then
        # Try to parse ISO format on macOS
        date -j -f "%Y-%m-%dT%H:%M:%S%z" "$timestamp" +%s 2>/dev/null || \
        date -j -f "%Y-%m-%dT%H:%M:%S" "${timestamp%+*}" +%s 2>/dev/null || echo "0"
    else
        date -d "$timestamp" +%s 2>/dev/null || echo "0"
    fi
}

# Cross-platform: get recent files sorted by mtime
get_recent_files() {
    local project_path="$1"
    local count="${2:-20}"
    if [[ "$PLATFORM" == "macos" ]]; then
        find "$project_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rs" \) \
            -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -"$count" | cut -d' ' -f2-
    else
        find "$project_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rs" \) \
            -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -"$count" | cut -d' ' -f2-
    fi
}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Helper: Generate project ID from path
generate_project_id() {
    echo -n "$1" | shasum -a 256 | cut -d' ' -f1 | cut -c 1-16
}

# Helper: Get project config path
get_project_config() {
    local project_id="$1"
    echo "$PROJECTS_DIR/$project_id/config.json"
}

# Helper: Get project index path
get_project_index() {
    local project_id="$1"
    echo "$PROJECTS_DIR/$project_id/index.json"
}

# Helper: Get project embeddings path
get_project_embeddings() {
    local project_id="$1"
    echo "$PROJECTS_DIR/$project_id/embeddings"
}

# --------------------------------------------------------
# Handler 1: Initialize Codebase Context
# --------------------------------------------------------
init_context() {
    local project_path="$1"
    local project_name="${2:-$(basename "$project_path")}"
    
    if [[ ! -d "$project_path" ]]; then
        log "❌ Error: Project path '$project_path' does not exist"
        return 1
    fi
    
    local project_id=$(generate_project_id "$project_path")
    local project_dir="$PROJECTS_DIR/$project_id"
    
    mkdir -p "$project_dir"
    
    # Create config
    cat > "$project_dir/config.json" << EOF
{
    "name": "$project_name",
    "path": "$project_path",
    "id": "$project_id",
    "created": "$(date -Iseconds)",
    "last_indexed": null,
    "indexing_strategy": "git_latest+function_extract",
    "exclude_patterns": [
        "node_modules",
        ".git",
        "dist",
        "build",
        "*.log",
        "*.tmp"
    ],
    "include_extensions": [
        ".js", ".jsx", ".ts", ".tsx", ".py", ".rs",
        ".go", ".java", ".cpp", ".c", ".h", ".hpp",
        ".rb", ".php", ".swift", ".kt", ".scala"
    ],
    "chunk_size": 2000,
    "max_files": 1000
}
EOF
    
    log "✅ Initialized context for '$project_name' (ID: $project_id)"
    echo "$project_id"
}

# --------------------------------------------------------
# Handler 2: Update Context (Incremental)
# --------------------------------------------------------
update_context() {
    local project_id="$1"
    local project_dir="$PROJECTS_DIR/$project_id"
    
    if [[ ! -d "$project_dir" ]]; then
        log "Error: Project '$project_id' not initialized"
        return 1
    fi
    
    local config_path="$project_dir/config.json"
    local project_path=$(jq -r '.path' "$config_path")
    
    # Validate project path exists
    if [[ ! -d "$project_path" ]]; then
        log "Error: Project path '$project_path' no longer exists"
        return 1
    fi
    
    # Check if git repository
    if [[ -d "$project_path/.git" ]]; then
        update_git_context "$project_id" "$project_path"
    else
        update_file_context "$project_id" "$project_path"
    fi
}

update_git_context() {
    local project_id="$1"
    local project_path="$2"
    local project_dir="$PROJECTS_DIR/$project_id"
    
    log "Updating context via git changes..."
    
    # Get files changed in last 5 commits
    local changed_files=$(git -C "$project_path" diff --name-only HEAD~5..HEAD 2>/dev/null)
    
    if [[ -z "$changed_files" ]]; then
        # Fallback to recently modified files
        changed_files=$(get_recent_files "$project_path" 20)
    fi
    
    # Process changed files
    local processed=0
    for file in ${(f)changed_files}; do
        if [[ -f "$project_path/$file" ]]; then
            index_single_file "$project_id" "$project_path/$file" "$file"
            processed=$((processed + 1))
        fi
    done
    
    # Update timestamp
    jq --arg timestamp "$(date -Iseconds)" '.last_indexed = $timestamp' \
        "$project_dir/config.json" > "$project_dir/config.tmp" \
        && mv "$project_dir/config.tmp" "$project_dir/config.json"
    
    log "Updated $processed files for project $project_id"
}

# Update context for non-git projects (based on recently modified files)
update_file_context() {
    local project_id="$1"
    local project_path="$2"
    local project_dir="$PROJECTS_DIR/$project_id"
    
    log "Updating context via file modification times..."
    
    # Get recently modified files
    local changed_files=$(get_recent_files "$project_path" 20)
    
    # Process changed files
    local processed=0
    for file in ${(f)changed_files}; do
        if [[ -f "$file" ]]; then
            local rel_path="${file#$project_path/}"
            index_single_file "$project_id" "$file" "$rel_path"
            processed=$((processed + 1))
        fi
    done
    
    # Update timestamp
    jq --arg timestamp "$(date -Iseconds)" '.last_indexed = $timestamp' \
        "$project_dir/config.json" > "$project_dir/config.tmp" \
        && mv "$project_dir/config.tmp" "$project_dir/config.json"
    
    log "Updated $processed files for project $project_id"
}

# --------------------------------------------------------
# Handler 3: Reindex and Update (Full)
# --------------------------------------------------------
reindex_context() {
    local project_id="$1"
    local project_dir="$PROJECTS_DIR/$project_id"
    
    if [[ ! -d "$project_dir" ]]; then
        log "Error: Project '$project_id' not initialized"
        return 1
    fi
    
    local config_path="$project_dir/config.json"
    local project_path=$(jq -r '.path' "$config_path")
    local exclude_patterns=($(jq -r '.exclude_patterns[]' "$config_path"))
    local include_extensions=($(jq -r '.include_extensions[]' "$config_path"))
    
    log "Starting full reindex of $project_path..."
    
    # Build find command with exclusions
    local find_cmd="find \"$project_path\" -type f"
    
    # Add include extensions
    if [[ ${#include_extensions[@]} -gt 0 ]]; then
        local ext_pattern=""
        for ext in "${include_extensions[@]}"; do
            if [[ -n "$ext_pattern" ]]; then
                ext_pattern="$ext_pattern -o -name \"*${ext}\""
            else
                ext_pattern="-name \"*${ext}\""
            fi
        done
        find_cmd="$find_cmd \\( $ext_pattern \\)"
    fi
    
    # Add exclusions
    for pattern in "${exclude_patterns[@]}"; do
        find_cmd="$find_cmd -not -path \"*/$pattern/*\""
    done
    
    # Execute find and process files
    local total_files=0
    eval "$find_cmd" | while read file; do
        local rel_path="${file#$project_path/}"
        index_single_file "$project_id" "$file" "$rel_path"
        total_files=$((total_files + 1))
        
        # Progress indicator
        if [[ $((total_files % 50)) -eq 0 ]]; then
            log "Processed $total_files files..."
        fi
    done
    
    # Update timestamp
    jq --arg timestamp "$(date -Iseconds)" '.last_indexed = $timestamp' \
        "$project_dir/config.json" > "$project_dir/config.tmp" \
        && mv "$project_dir/config.tmp" "$project_dir/config.json"
    
    log "Reindexed $total_files files for project $project_id"
}

# Helper: Index a single file
index_single_file() {
    local project_id="$1"
    local file_path="$2"
    local rel_path="$3"
    
    local project_dir="$PROJECTS_DIR/$project_id"
    local index_file="$project_dir/index.json"
    local chunk_size=$(jq -r '.chunk_size' "$project_dir/config.json")
    
    # Create index file if doesn't exist
    if [[ ! -f "$index_file" ]]; then
        echo '{"files": {}, "chunks": [], "stats": {}}' > "$index_file"
    fi
    
    # Extract content
    local content=$(cat "$file_path" 2>/dev/null)
    if [[ -z "$content" ]]; then
        return
    fi
    
    # Extract functions/methods/classes
    local extracted=""
    if [[ "$file_path" =~ .(js|jsx|ts|tsx)$ ]]; then
        extracted=$(extract_js_structures "$content")
    elif [[ "$file_path" =~ .py$ ]]; then
        extracted=$(extract_py_structures "$content")
    elif [[ "$file_path" =~ .rs$ ]]; then
        extracted=$(extract_rust_structures "$content")
    else
        extracted="$content"
    fi
    
    # Create chunks
    local chunks=()
    local chunk=""
    local lines=(${(f)extracted})
    
    for line in "${lines[@]}"; do
        if [[ ${#chunk} -gt $chunk_size ]]; then
            chunks+=("$chunk")
            chunk=""
        fi
        chunk+="$line"$'
'
    done
    
    if [[ -n "$chunk" ]]; then
        chunks+=("$chunk")
    fi
    
    # Update index
    local temp_file="$index_file.tmp"
    
    # Add file metadata
    jq --arg path "$rel_path" \
       --arg modified "$(get_mtime "$file_path")" \
       --arg size "$(get_fsize "$file_path")" \
       '.files[$path] = {"modified": $modified, "size": $size, "chunks": []}' \
       "$index_file" > "$temp_file"
    
    # Add chunks
    local chunk_index=0
    for chunk_content in "${chunks[@]}"; do
        local chunk_id="${rel_path}#${chunk_index}"
        jq --arg id "$chunk_id" \
           --arg path "$rel_path" \
           --arg content "$chunk_content" \
           '.files[$path].chunks += [$id] | .chunks += [{"id": $id, "path": $path, "content": $content}]' \
           "$temp_file" > "${temp_file}2"
        mv "${temp_file}2" "$temp_file"
        chunk_index=$((chunk_index + 1))
    done
    
    mv "$temp_file" "$index_file"
}

# Extract JavaScript/TypeScript structures
extract_js_structures() {
    echo "$1" | grep -E "(function|class|const|let|var|export|import|interface|type).*\{?$" \
        -A 8 | head -30
}

# Extract Python structures
extract_py_structures() {
    echo "$1" | grep -E "(def|class|import|from).*:$" \
        -A 6 | head -30
}

# Extract Rust structures
extract_rust_structures() {
    echo "$1" | grep -E "(fn|struct|enum|impl|mod|pub).*\{?$" \
        -A 6 | head -30
}

# --------------------------------------------------------
# Handler 4: Get Context for Project
# --------------------------------------------------------
get_context() {
    local project_id="$1"
    local query="${2:-''}"
    local limit="${3:-10}"
    
    local project_dir="$PROJECTS_DIR/$project_id"
    local index_file="$project_dir/index.json"
    
    if [[ ! -f "$index_file" ]]; then
        log "Error: Project '$project_id' not indexed"
        return 1
    fi
    
    if [[ -z "$query" ]]; then
        # Return recent chunks
        jq -r ".chunks[-${limit}:][] | .content" "$index_file"
    else
        # Search with ripgrep
        local search_result=$(rg -i "$query" "$index_file" -C 2 | head -c 8000)
        if [[ -n "$search_result" ]]; then
            echo "$search_result"
        else
            # Fallback to jq search
            jq -r --arg query "$query" \
                '.chunks[] | select(.content | contains($query)) | .content' \
                "$index_file" | head -$limit
        fi
    fi
}

# Helper: Generate a unique ID (cross-platform)
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr -d '-' | cut -c 1-8
    elif [[ -f /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid | tr -d '-' | cut -c 1-8
    else
        # Fallback: use date + random
        echo "$(date +%s%N | cut -c 1-8)$(( RANDOM % 9999 ))" | cut -c 1-8
    fi
}

# --------------------------------------------------------
# Handler 5: Agent Context Storage
# --------------------------------------------------------
save_agent_context() {
    local agent_name="$1"
    local context_text="$2"
    local tags="${3:-general}"
    
    local agent_file="$AGENTS_DIR/${agent_name}.jsonl"
    local entry_id=$(generate_uuid)
    
    # Create entry
    local entry=$(jq -n \
        --arg id "$entry_id" \
        --arg text "$context_text" \
        --arg tags "$tags" \
        --arg timestamp "$(date -Iseconds)" \
        --arg agent "$agent_name" \
        '{id: $id, text: $text, tags: $tags, timestamp: $timestamp, agent: $agent}')
    
    # Append to agent's context log
    echo "$entry" >> "$agent_file"
    
    # Also add to shared agent cache (last 100 entries)
    local cache_file="$CACHE_DIR/agent_context.jsonl"
    echo "$entry" >> "$cache_file"
    
    # Trim cache to last 100 entries
    tail -n 100 "$cache_file" > "$cache_file.tmp" && mv "$cache_file.tmp" "$cache_file"
    
    log "Agent '$agent_name' saved context: $entry_id"
    echo "$entry_id"
}

# Search agent context
search_agent_context() {
    local agent_name="$1"
    local query="$2"
    
    local agent_file="$AGENTS_DIR/${agent_name}.jsonl"
    
    if [[ ! -f "$agent_file" ]]; then
        return 1
    fi
    
    if [[ -z "$query" ]]; then
        # Return last 10 entries
        tail -n 10 "$agent_file" | jq -r '.text'
    else
        # Search in agent's context
        grep -i "$query" "$agent_file" | tail -5 | jq -r '.text'
    fi
}

# --------------------------------------------------------
# Utility Commands
# --------------------------------------------------------
list_projects() {
    echo "📁 Managed Projects:"
    for project_dir in "$PROJECTS_DIR"/*; do
        if [[ -f "$project_dir/config.json" ]]; then
            local name=$(jq -r '.name' "$project_dir/config.json")
            local path=$(jq -r '.path' "$project_dir/config.json")
            local last=$(jq -r '.last_indexed // "never"' "$project_dir/config.json")
            echo "  • $name ($(basename "$project_dir"))"
            echo "    Path: $path"
            echo "    Last indexed: $last"
            echo
        fi
    done
}

project_stats() {
    local project_id="$1"
    local project_dir="$PROJECTS_DIR/$project_id"
    
    if [[ ! -d "$project_dir" ]]; then
        log "Project not found: $project_id"
        return 1
    fi
    
    local index_file="$project_dir/index.json"
    
    if [[ ! -f "$index_file" ]]; then
        echo "No index found for project"
        return
    fi
    
    echo "📊 Project Statistics:"
    jq -r '
        "Files: (.files | length)",
        "Chunks: (.chunks | length)",
        "Total size: (.chunks | map(.content | length) | add) chars"
    ' "$index_file"
}

cleanup_old_context() {
    local days="${1:-30}"
    find "$AGENTS_DIR" -name "*.jsonl" -mtime +"$days" -exec rm {} \;
    log "Cleaned context older than $days days"
}

# --------------------------------------------------------
# Main Dispatcher Function
# --------------------------------------------------------
context() {
    case "$1" in
        init)
            init_context "$2" "$3"
            ;;
        update)
            update_context "$2"
            ;;
        reindex)
            reindex_context "$2"
            ;;
        get)
            get_context "$2" "$3" "$4"
            ;;
        save-agent)
            save_agent_context "$2" "$3" "$4"
            ;;
        search-agent)
            search_agent_context "$2" "$3"
            ;;
        list)
            list_projects
            ;;
        stats)
            project_stats "$2"
            ;;
        cleanup)
            cleanup_old_context "$2"
            ;;
        help|*)
            echo "📚 Context Dispatcher Commands:"
            echo "  init <path> [name]       Initialize context for a project"
            echo "  update <project_id>      Incremental update from git"
            echo "  reindex <project_id>     Full reindex of project"
            echo "  get <project_id> [query] Get context (optional search)"
            echo "  save-agent <name> <text> Save agent-specific context"
            echo "  search-agent <name> [q]  Search agent context"
            echo "  list                     List all managed projects"
            echo "  stats <project_id>       Show project statistics"
            echo "  cleanup [days]           Clean old context (default: 30)"
            ;;
    esac
}

