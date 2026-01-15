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

# Cache command paths to avoid lookup issues in some shell configurations
JQ_CMD="${JQ_CMD:-$(command -v jq)}"
RG_CMD="${RG_CMD:-$(command -v rg)}"
BASENAME_CMD="${BASENAME_CMD:-$(command -v basename)}"
DIRNAME_CMD="${DIRNAME_CMD:-$(command -v dirname)}"

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

# Check if a file should be excluded based on patterns
is_file_excluded() {
    local file_path="$1"
    local exclude_patterns=(${@:2})
    
    for pattern in "${exclude_patterns[@]}"; do
        if [[ "$file_path" == *"/$pattern/"* || "$file_path" == *"/$pattern" || "$file_path" == "$pattern/"* || "$file_path" == "$pattern" ]]; then
            return 0 # Should exclude
        fi
        # Handle glob-like patterns in exclusions (simple version)
        if [[ "$pattern" == *"*"* ]]; then
            local regex_pattern="${pattern//./\\.}"
            regex_pattern="${regex_pattern//\*/.*}"
            if [[ "$file_path" =~ "$regex_pattern" ]]; then
                return 0 # Should exclude
            fi
        fi
    done
    return 1 # Should not exclude
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

# Helper: Sanitize string for JSON (remove control characters, escape quotes)
sanitize_for_json() {
    local input="$1"
    # Remove control characters (newlines, tabs, etc) and trim whitespace
    echo "$input" | tr -d '\n\r\t' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/"/\\"/g'
}

# --------------------------------------------------------
# Handler 1: Initialize Codebase Context
# --------------------------------------------------------
init_context() {
    local raw_path="$1"
    local raw_name="$2"

    # Sanitize inputs
    local project_path=$(sanitize_for_json "$raw_path")
    local project_name="${raw_name:-$($BASENAME_CMD "$project_path")}"
    project_name=$(sanitize_for_json "$project_name")

    if [[ -z "$project_path" ]]; then
        log "Error: Project path is required"
        return 1
    fi

    if [[ ! -d "$project_path" ]]; then
        log "Error: Project path '$project_path' does not exist"
        return 1
    fi

    local project_id=$(generate_project_id "$project_path")
    local project_dir="$PROJECTS_DIR/$project_id"

    mkdir -p "$project_dir"

    # Create config using jq for proper JSON escaping
    $JQ_CMD -n \
        --arg name "$project_name" \
        --arg path "$project_path" \
        --arg id "$project_id" \
        --arg created "$(date -Iseconds)" \
        '{
            name: $name,
            path: $path,
            id: $id,
            created: $created,
            last_indexed: null,
            indexing_strategy: "git_latest+function_extract",
            exclude_patterns: ["node_modules", ".git", "dist", "build", "*.log", "*.tmp", "__pycache__", ".mypy_cache", ".pytest_cache", "*.pyc", "target", "out", "coverage", "*.min.*", "*.map", ".DS_Store", ".ruff_cache", ".venv", "venv", "env", ".env", ".idea", ".vscode", "*.lock", ".cache", "tmp", ".brv", "vendor", "bower_components", ".next", ".nuxt", ".output", ".svelte-kit", "out-tsc", ".parcel-cache", ".cache-loader", ".eslintcache", ".stylelintcache", ".docz", ".cache", ".nyc_output", ".dynamodb", ".serverless", ".webpack", ".meteor", ".swc", ".cache", ".vercel", ".turbo", "out", "bundle.js", "*.chunk.js", "*.bundle.js", "*.min.js", ".pnpm-store", ".yarn", ".npm", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb"],
            include_extensions: [".js", ".jsx", ".ts", ".tsx", ".py", ".rs", ".go", ".java", ".cpp", ".c", ".h", ".hpp", ".rb", ".php", ".swift", ".kt", ".scala", ".zsh", ".sh", ".bash", ".md", ".yaml", ".yml", ".json", ".sql", ".conf", ".ini", ".env", ".toml", ".mdx"],
            chunk_size: 2000,
            max_files: 1000
        }' > "$project_dir/config.json"

    log "Initialized context for '$project_name' (ID: $project_id)"
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
    local project_path=$($JQ_CMD -r ".path" "$config_path")

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
    $JQ_CMD --arg timestamp "$(date -Iseconds)" ".last_indexed = \$timestamp" \
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
    $JQ_CMD --arg timestamp "$(date -Iseconds)" ".last_indexed = \$timestamp" \
        "$project_dir/config.json" > "$project_dir/config.tmp" \
        && mv "$project_dir/config.tmp" "$project_dir/config.json"

    log "Updated $processed files for project $project_id"
}

# --------------------------------------------------------
# Handler 3: Reindex and Update (Full)
# --------------------------------------------------------
reindex_context() {
    local project_id="$1"
    local subpath="$2"
    local project_dir="$PROJECTS_DIR/$project_id"

    if [[ ! -d "$project_dir" ]]; then
        log "Error: Project '$project_id' not initialized"
        return 1
    fi

    local config_path="$project_dir/config.json"
    local project_path=$($JQ_CMD -r ".path" "$config_path")
    
    local target_path="$project_path"
    if [[ -n "$subpath" ]]; then
        target_path="$project_path/$subpath"
        if [[ ! -d "$target_path" && ! -f "$target_path" ]]; then
            log "Error: Subpath '$subpath' not found in project"
            return 1
        fi
        log "Targeted reindex of $target_path..."
    else
        log "Starting full reindex of $project_path..."
    fi

    local file_list="/tmp/reindex_files_$$.txt"
    
    # Use git ls-files if it's a git repo
    if [[ -d "$project_path/.git" ]]; then
        log "Detected git repository..."
        if [[ -n "$subpath" ]]; then
             (cd "$project_path" && git ls-files -c -o --exclude-standard "$subpath") | sed "s|^|$project_path/|" > "$file_list" 2>/dev/null
        else
             (cd "$project_path" && git ls-files -c -o --exclude-standard) | sed "s|^|$project_path/|" > "$file_list" 2>/dev/null
        fi
    else
        log "No git repository found..."
        local include_extensions=($($JQ_CMD -r ".include_extensions[]" "$config_path"))
        local exclude_patterns=($($JQ_CMD -r ".exclude_patterns[]" "$config_path"))
        local find_cmd="find \"$target_path\" -type f"
        
        # Add extensions filter to find command if possible for speed
        if [[ ${#include_extensions[@]} -gt 0 ]]; then
            local ext_pattern=""
            for ext in "${include_extensions[@]}"; do
                [[ -z "$ext" ]] && continue
                if [[ -z "$ext_pattern" ]]; then
                    ext_pattern="-name \"*$ext\""
                else
                    ext_pattern="$ext_pattern -o -name \"*$ext\""
                fi
            done
            find_cmd="$find_cmd \\( $ext_pattern \\)"
        fi

        # Add initial exclusions
        for pattern in "${exclude_patterns[@]}"; do
            find_cmd="$find_cmd -not -path \"*/$pattern/*\" -not -name \"$pattern\""
        done

        # Add .gitignore patterns if any exist despite no .git dir
        local gitignore_patterns=($(parse_gitignore_patterns "$project_path"))
        for pattern in "${gitignore_patterns[@]}"; do
            find_cmd="$find_cmd -not -path \"*/$pattern/*\" -not -name \"$pattern\""
        done
        
        eval "$find_cmd" > "$file_list" 2>/dev/null
    fi

    # Process files
    local total_files=0
    local filtered_list="/tmp/filtered_files_$$.txt"
    local exclude_patterns=($($JQ_CMD -r ".exclude_patterns[]" "$config_path"))
    
    # Filter the file list using exclude_patterns
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local skip=false
        for pattern in "${exclude_patterns[@]}"; do
            if [[ "$file" == *"/$pattern/"* || "$file" == *"/$pattern" || "$file" == "$pattern/"* || "$file" == "$pattern" ]]; then
                skip=true
                break
            fi
            # Handle glob-like patterns in exclusions (very simple version)
            if [[ "$pattern" == *"*"* ]]; then
                local regex_pattern="${pattern//./\\.}"
                regex_pattern="${regex_pattern//\*/.*}"
                if [[ "$file" =~ "$regex_pattern" ]]; then
                    skip=true
                    break
                fi
            fi
        done
        [[ "$skip" == true ]] && continue
        echo "$file" >> "$filtered_list"
    done < "$file_list"
    mv "$filtered_list" "$file_list"

    # Initialize index file
    local index_file="$project_dir/index.json"
    echo '{"files": {}, "chunks": [], "stats": {}}' > "$index_file"

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        # Extension check (redundant but safe)
        local ext="${file##*.}"
        local match=false
        for include_ext in "${include_extensions[@]}"; do
            if [[ ".$ext" == "$include_ext" || "$file" == *"$include_ext" ]]; then
                match=true
                break
            fi
        done
        [[ "$match" == false ]] && continue

        local rel_path="${file#$project_path/}"
        index_single_file "$project_id" "$file" "$rel_path"
        total_files=$((total_files + 1))

        # Progress indicator
        if [[ $((total_files % 50)) -eq 0 ]]; then
            log "Processed $total_files files..."
        fi
    done < "$file_list"
    rm -f "$file_list"

    # Update timestamp
    $JQ_CMD --arg timestamp "$(date -Iseconds)" ".last_indexed = \$timestamp" \
        "$project_dir/config.json" > "$project_dir/config.tmp" \
        && mv "$project_dir/config.tmp" "$project_dir/config.json"

    log "Reindexed $total_files files for project $project_id"
}

# Prune index: remove files matching exclude_patterns from index.json
prune_context() {
    local project_id="$1"
    local project_dir="$PROJECTS_DIR/$project_id"
    local index_file="$project_dir/index.json"
    local config_file="$project_dir/config.json"

    if [[ ! -f "$index_file" ]]; then
        log "Error: Index not found for project $project_id"
        return 1
    fi

    log "Pruning index for project $project_id..."
    local exclude_patterns=($($JQ_CMD -r ".exclude_patterns[]" "$config_file"))
    local files=($($JQ_CMD -r ".files | keys[]" "$index_file"))
    local count=0

    for file in "${files[@]}"; do
        if is_file_excluded "$file" "${exclude_patterns[@]}"; then
            log "  Removing excluded file: $file"
            
            # Remove from files object and remove its chunks
            local updated_index="/tmp/pruned_index_$$.json"
            
            # Get chunk IDs for this file
            local chunk_ids=($($JQ_CMD -r ".files[\"$file\"].chunks[]" "$index_file"))
            
            # Build jq command to remove file and all its chunks
            local jq_filter="del(.files[\"$file\"])"
            for cid in "${chunk_ids[@]}"; do
                jq_filter="$jq_filter | del(.chunks[] | select(.id == \"$cid\"))"
            done
            
            $JQ_CMD "$jq_filter" "$index_file" > "$updated_index" && mv "$updated_index" "$index_file"
            count=$((count + 1))
        fi
    done

    log "Pruned $count files from project $project_id"
}

# Helper: Index a single file
index_single_file() {
    local project_id="$1"
    local file_path="$2"
    local rel_path="$3"

    local project_dir="$PROJECTS_DIR/$project_id"
    local config_file="$project_dir/config.json"
    local index_file="$project_dir/index.json"
    
    # Check exclusion list
    local exclude_patterns=($($JQ_CMD -r ".exclude_patterns[]" "$config_file"))
    if is_file_excluded "$rel_path" "${exclude_patterns[@]}"; then
        # If it's in the index but now excluded, remove it?
        # For now just skip indexing
        return
    fi

    local chunk_size=$($JQ_CMD -r ".chunk_size" "$config_file")

    # Create index file if doesn't exist
    if [[ ! -f "$index_file" ]]; then
        echo '{"files": {}, "chunks": [], "stats": {}}' > "$index_file"
    fi

    # Skip binary files (but allow text executables like scripts)
    local file_type=$(file -b "$file_path" 2>/dev/null)
    if echo "$file_type" | grep -qi "binary\|data\|image\|audio\|video\|archive\|compressed"; then
        if ! echo "$file_type" | grep -qi "text"; then
            return
        fi
    fi

    # Extract content
    local content=$(cat "$file_path" 2>/dev/null)
    if [[ -z "$content" ]]; then
        return
    fi

    # Extract functions/methods/classes
    local extracted=""
    if [[ "$file_path" == *.js || "$file_path" == *.jsx || "$file_path" == *.ts || "$file_path" == *.tsx ]]; then
        extracted=$(extract_js_structures "$content")
    elif [[ "$file_path" == *.py ]]; then
        extracted=$(extract_py_structures "$content")
    elif [[ "$file_path" == *.rs ]]; then
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
    $JQ_CMD --arg path "$rel_path" \
       --arg modified "$(get_mtime "$file_path")" \
       --arg size "$(get_fsize "$file_path")" \
       '.files[$path] = {"modified": $modified, "size": $size, "chunks": []}' \
       "$index_file" > "$temp_file"

    # Add chunks
    local chunk_index=0
    local chunk_tmp="/tmp/chunk_content_$$.txt"
    for chunk_content in "${chunks[@]}"; do
        local chunk_id="${rel_path}#${chunk_index}"
        # Write chunk to temp file to avoid argument length limits
        printf '%s' "$chunk_content" > "$chunk_tmp"
        $JQ_CMD --arg id "$chunk_id" \
           --arg path "$rel_path" \
           --rawfile content "$chunk_tmp" \
           '.files[$path].chunks += [$id] | .chunks += [{"id": $id, "path": $path, "content": $content}]' \
           "$temp_file" > "${temp_file}2" 2>/dev/null
        mv "${temp_file}2" "$temp_file"
        chunk_index=$((chunk_index + 1))
    done
    rm -f "$chunk_tmp"

    mv "$temp_file" "$index_file"
}

# Extract JavaScript/TypeScript structures
extract_js_structures() {
    LC_ALL=C grep -a -E "(function|class|const|let|var|export|import|interface|type).*[{]?$" \
        -A 12 2>/dev/null <<< "$1" | head -100
}

# Extract Python structures
extract_py_structures() {
    # Include imports, classes, and function definitions with more context
    # but still keep it summarized for the shell index
    LC_ALL=C grep -a -E "(def|class|import|from|async def).*:$" \
        -A 10 2>/dev/null <<< "$1" | head -100
}

# Extract Rust structures
extract_rust_structures() {
    LC_ALL=C grep -a -E "(fn|struct|enum|impl|mod|pub).*[{]?$" \
        -A 10 2>/dev/null <<< "$1" | head -100
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
        local search_result=$($RG_CMD -i "$query" "$index_file" -C 2 | head -c 8000)
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
    local entry=$($JQ_CMD -n \
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
        tail -n 10 "$agent_file" | $JQ_CMD -r ".text"
    else
        # Search in agent's context
        grep -i "$query" "$agent_file" | tail -5 | $JQ_CMD -r ".text"
    fi
}

# List projects with shortcuts
list_projects() {
    echo "Managed Projects:"
    local name path last project_id shortcut
    local i=1
    
    # Header for shortcuts
    echo "SHORTCUT  ID                NAME (PATH)"
    echo "--------  ----------------  ----------------"
    
    # We'll use a temp file to store the map for the current session
    local map_file="$CACHE_DIR/project_shortcuts.map"
    echo "# Project Shortcuts Map" > "$map_file"

    for project_dir in "$PROJECTS_DIR"/*; do
        if [[ -d "$project_dir" && -f "$project_dir/config.json" ]]; then
            name=$($JQ_CMD -r ".name" "$project_dir/config.json")
            path=$($JQ_CMD -r ".path" "$project_dir/config.json")
            project_id=$($BASENAME_CMD "$project_dir")
            
            # Generate shortcut: First letter of project name + counter
            # Using parameter expansion and zsh built-ins for speed and reliability
            local char=${name[1]}
            local first_char=${(U)char}
            shortcut="CTX_${first_char}${i}"
            
            printf "%-8s  %-16s  %s (%s)\n" "$shortcut" "$project_id" "$name" "$path"
            
            # Save to map
            echo "$shortcut=$project_id" >> "$map_file"
            
            # Export as ENV variable for current session
            # Note: Dash/underscore are safer for env vars
            export "$shortcut=$project_id"
            
            i=$((i + 1))
        fi
    done
    
    echo ""
    echo "💡 Shortcuts are exported as ENV variables (e.g., \$CTX-F1)."
    echo "   You can use them in commands: ocx \$CTX-F1"
}

# Resolve ID from shortcut if needed
resolve_id() {
    local input="$1"
    if [[ "$input" == CTX_* ]]; then
        # Check if it's an environment variable
        local val=$(eval echo "\$$input")
        if [[ -n "$val" ]]; then
            echo "$val"
            return
        fi
        
        # Fallback to map file
        local map_file="$CACHE_DIR/project_shortcuts.map"
        if [[ -f "$map_file" ]]; then
            grep "^$input=" "$map_file" | head -n 1 | cut -d'=' -f2
            return
        fi
    fi
    echo "$input"
}

project_stats() {
    local project_id="$1"
    local project_dir="$PROJECTS_DIR/$project_id"

    if [[ ! -d "$project_dir" ]]; then
        log "Project not found: $project_id"
        return 1
    fi

    local index_file="$project_dir/index.json"

    if [[ ! -f "$index_file" ]] || [[ ! -s "$index_file" ]]; then
        echo "No index found for project. Run: ctx reindex $project_id"
        return
    fi

    local files_count=$($JQ_CMD ".files | length" "$index_file" 2>/dev/null)
    local chunks_count=$($JQ_CMD ".chunks | length" "$index_file" 2>/dev/null)
    local total_size=$($JQ_CMD "[.chunks[].content | length] | add // 0" "$index_file" 2>/dev/null)

    echo "Project Statistics:"
    echo "  Files: ${files_count:-0}"
    echo "  Chunks: ${chunks_count:-0}"
    echo "  Total size: ${total_size:-0} chars"
}

cleanup_old_context() {
    local days="${1:-30}"
    find "$AGENTS_DIR" -name "*.jsonl" -mtime +"$days" -exec rm {} \;
    log "Cleaned context older than $days days"
}

# --------------------------------------------------------
# Handler 7: Manual Docs/Notes Management
# --------------------------------------------------------
DOCS_DIR="$CONTEXT_ROOT/docs"
mkdir -p "$DOCS_DIR"

# Add a document/note to project context
add_doc() {
    local project_id="$1"
    local doc_type="$2"  # rule, doc, note, prompt
    local content="$3"
    local title="$4"

    if [[ -z "$project_id" ]] || [[ -z "$doc_type" ]] || [[ -z "$content" ]]; then
        echo "Usage: ctx add-doc <project_id> <type> <content> [title]"
        echo "Types: rule, doc, note, prompt"
        return 1
    fi

    # Auto-generate title if missing or 'untitled'
    if [[ -z "$title" || "$title" == "untitled" ]]; then
        # Take first non-empty line, strip markdown headers, trim to 50 chars
        title=$(echo "$content" | grep -v '^\s*$' | head -n 1 | sed 's/^[#* ]*//' | cut -c 1-50)
        [[ -z "$title" ]] && title="untitled-$(date +%H%M%S)"
    fi

    local project_docs="$DOCS_DIR/$project_id"
    mkdir -p "$project_docs"

    local doc_file="$project_docs/docs.jsonl"
    local doc_id=$(generate_uuid)

    # Create entry using jq and append directly to avoid shell string issues
    $JQ_CMD -c -n \
        --arg id "$doc_id" \
        --arg type "$doc_type" \
        --arg title "$title" \
        --arg content "$content" \
        --arg timestamp "$(date -Iseconds)" \
        '{id: $id, type: $type, title: $title, content: $content, timestamp: $timestamp}' >> "$doc_file"
    
    log "Added $doc_type: $title ($doc_id)"
    echo "$doc_id"
}

# Diff context: see what changed recently
diff_context() {
    local project_id="$1"
    local days="${2:-1}"
    local doc_file="$DOCS_DIR/$project_id/docs.jsonl"

    if [[ ! -f "$doc_file" ]]; then
        echo "No documents found for project $project_id"
        return
    fi

    local since_ts=$(get_timestamp_days_ago "$days")
    
    echo "Changes in project $project_id since $days day(s) ago:"
    echo "--------------------------------------------------------"
    
    # Use jq to filter by timestamp
    # Note: timestamp is ISO, so we need to parse it or use string comparison if ISO
    $JQ_CMD -r --arg since "$(date -d "$days days ago" -Iseconds 2>/dev/null || date -v-${days}d -Iseconds)" \
        'select(.timestamp >= $since) | "[\(.timestamp)] [\(.type)] \(.title) (\(.id))"' "$doc_file"
}

# Sync environment variables between projects
sync_env() {
    local src_id=$(resolve_id "$1")
    local dest_id=$(resolve_id "$2")
    shift 2
    local keys=("$@")

    if [[ -z "$src_id" || -z "$dest_id" ]]; then
        echo "Usage: ctx sync-env <src_id> <dest_id> [key1 key2 ...]"
        return 1
    fi

    local src_path=$($JQ_CMD -r ".path" "$(get_project_config "$src_id")")
    local dest_path=$($JQ_CMD -r ".path" "$(get_project_config "$dest_id")")
    
    local src_env="$src_path/.env"
    local dest_env="$dest_path/.env"

    if [[ ! -f "$src_env" ]]; then
        echo "Error: Source .env not found at $src_env"
        return 1
    fi

    if [[ ! -f "$dest_env" ]]; then
        echo "Warning: Destination .env not found at $dest_env, creating it..."
        touch "$dest_env"
    fi

    echo "Syncing env from $src_id to $dest_id..."

    if [[ ${#keys[@]} -eq 0 ]]; then
        # If no keys specified, show differences or ask? 
        # For now, just list what's in src
        echo "Source keys available:"
        grep -v '^#' "$src_env" | grep '=' | cut -d'=' -f1
        return 0
    fi

    for key in "${keys[@]}"; do
        local value=$(grep "^$key=" "$src_env" | cut -d'=' -f2-)
        if [[ -z "$value" ]]; then
            echo "  ⚠️  Key $key not found in source"
            continue
        fi

        if grep -q "^$key=" "$dest_env"; then
            # Update existing
            if [[ "$PLATFORM" == "macos" ]]; then
                sed -i '' "s|^$key=.*|$key=$value|" "$dest_env"
            else
                sed -i "s|^$key=.*|$key=$value|" "$dest_env"
            fi
            echo "  ✅ Updated $key"
        else
            # Append new
            echo "$key=$value" >> "$dest_env"
            echo "  ✅ Added $key"
        fi
    done
    
    # Add a note to context about the sync
    add_doc "$dest_id" "note" "Synced environment variables ($*) from project $src_id" "Env Sync" > /dev/null
}

# Link two documents
link_docs() {
    local project_id="$1"
    local source_id="$2"
    local target_id="$3"
    local relation="${4:-related_to}"

    if [[ -z "$project_id" ]] || [[ -z "$source_id" ]] || [[ -z "$target_id" ]]; then
        echo "Usage: ctx link <project_id> <source_id> <target_id> [relation]"
        return 1
    fi

    add_doc "$project_id" "note" "Relation: $relation to $target_id" "Link: $source_id -> $target_id"
}

# Add document from file
add_doc_file() {
    local project_id="$1"
    local doc_type="$2"
    local file_path="$3"
    local title="${4:-$($BASENAME_CMD "$file_path")}"

    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found: $file_path"
        return 1
    fi

    local content=$(cat "$file_path")
    add_doc "$project_id" "$doc_type" "$content" "$title"
}

# List documents for a project
list_docs() {
    local project_id="$1"
    local doc_type="$2"  # optional filter

    local doc_file="$DOCS_DIR/$project_id/docs.jsonl"

    if [[ ! -f "$doc_file" ]]; then
        echo "No documents found for project $project_id"
        return
    fi

    echo "Documents for project $project_id:"
    if [[ -n "$doc_type" ]]; then
        $JQ_CMD -r "select(.type == \"$doc_type\") | \"  [\(.type)] \(.title) (\(.id))\"" "$doc_file"
    else
        $JQ_CMD -r '"  [\(.type)] \(.title) (\(.id))"' "$doc_file"
    fi
}

# Get documents content
get_docs() {
    local project_id="$1"
    local doc_type="$2"  # optional filter

    local doc_file="$DOCS_DIR/$project_id/docs.jsonl"

    if [[ ! -f "$doc_file" ]]; then
        return
    fi

    if [[ -n "$doc_type" ]]; then
        $JQ_CMD -r "select(.type == \"$doc_type\") | \"## \(.title)\n\(.content)\n\"" "$doc_file"
    else
        $JQ_CMD -r '"## [\(.type)] \(.title)\n\(.content)\n"' "$doc_file"
    fi
}

# Remove a document
remove_doc() {
    local project_id="$1"
    local doc_id="$2"

    local doc_file="$DOCS_DIR/$project_id/docs.jsonl"

    if [[ ! -f "$doc_file" ]]; then
        echo "No documents found"
        return 1
    fi

    grep -v "\"id\":\"$doc_id\"" "$doc_file" > "${doc_file}.tmp"
    mv "${doc_file}.tmp" "$doc_file"
    log "Removed document: $doc_id"
}

# Edit a document (opens in $EDITOR)
edit_doc() {
    local project_id="$1"
    local doc_id="$2"

    local doc_file="$DOCS_DIR/$project_id/docs.jsonl"
    local tmp_file="/tmp/ctx_edit_$$.md"

    # Extract content
    $JQ_CMD -r "select(.id == \"$doc_id\") | .content" "$doc_file" > "$tmp_file"

    if [[ ! -s "$tmp_file" ]]; then
        echo "Document not found: $doc_id"
        rm -f "$tmp_file"
        return 1
    fi

    # Open in editor
    ${EDITOR:-vim} "$tmp_file"

    # Update content
    local new_content=$(cat "$tmp_file")
    local updated=$($JQ_CMD -r "select(.id == \"$doc_id\")" "$doc_file" | \
        $JQ_CMD --arg content "$new_content" '.content = $content')

    # Replace in file
    grep -v "\"id\":\"$doc_id\"" "$doc_file" > "${doc_file}.tmp"
    echo "$updated" >> "${doc_file}.tmp"
    mv "${doc_file}.tmp" "$doc_file"

    rm -f "$tmp_file"
    log "Updated document: $doc_id"
}

# Get full context (code + docs) for AI
get_full_context() {
    local project_id="$1"
    local query="$2"

    echo "=== PROJECT RULES ==="
    get_docs "$project_id" "rule"

    echo "=== PROJECT DOCS ==="
    get_docs "$project_id" "doc"

    echo "=== CUSTOM PROMPTS ==="
    get_docs "$project_id" "prompt"

    echo "=== CODE CONTEXT ==="
    get_context "$project_id" "$query"

    echo "=== NOTES ==="
    get_docs "$project_id" "note"
}

# --------------------------------------------------------
# Handler 8: Agent Onboarding & Guide Generation
# --------------------------------------------------------

# Generate AGENTS.md guide in the project root
generate_agent_guide() {
    local project_id="$1"
    local project_dir="$PROJECTS_DIR/$project_id"

    if [[ ! -d "$project_dir" ]]; then
        log "Error: Project '$project_id' not initialized"
        return 1
    fi

    local config_path="$project_dir/config.json"
    local project_path=$($JQ_CMD -r ".path" "$config_path")
    local project_name=$($JQ_CMD -r ".name" "$config_path")

    if [[ ! -d "$project_path" ]]; then
        log "Error: Project path '$project_path' not found"
        return 1
    fi

    local guide_path="$project_path/AGENTS.md"
    
    cat << EOF > "$guide_path"
# 🤖 Agent Onboarding & Context Guide: $project_name

Welcome, Agent! This project uses the **OpenCode Context Dispatcher** to manage project-specific knowledge, rules, and workflows.

## 🆔 Project Identity
- **Project Name**: $project_name
- **Project ID**: $project_id

## 🚀 How to Onboard Yourself
If you are new to this project or the context feels "cold", follow these steps to warm up:

### 1. Load Full Context
Get all established rules, documentation, and code structure:
\`\`\`bash
ctx get-full $project_id
\`\`\`

### 2. Semantic Exploration
If you need to understand *how* something works conceptually:
\`\`\`bash
ctx search-v $project_id "how does the authentication flow work?"
\`\`\`

### 3. Identify Tools & Workflows
Check for project-specific commands (testing, linting, building):
\`\`\`bash
ctx get-docs $project_id rule
\`\`\`

## 🛠 Essential Commands
- \`ctx list-docs $project_id\` - See all available documentation
- \`ctx diff $project_id\` - See what changed recently in the context
- \`ctx stats $project_id\` - Check indexing status
- \`ctx update $project_id\` - Sync latest git changes to context

## 🔗 Cross-Project Sync
If you need to sync environment variables from another project:
\`\`\`bash
ctx sync-env <source_project_id> $project_id SECRET_KEY API_URL
\`\`\`

## ✍️ Contributing to Context
When you discover a new pattern, fix a complex bug, or identify a recurring issue, **save it for future agents**:

\`\`\`bash
# Add a new rule
ctx add-doc $project_id rule "Always use 'uv run pytest' for testing" "Testing Standard"

# Add a workflow note
ctx add-doc $project_id note "To fix DB migration issues, run: rm dev.db && python manage.py migrate" "DB Troubleshooting"
\`\`\`

## 📋 Onboarding Checklist (For First Session)
If this is the first time an agent is working here, please:
1. [ ] Explore the directory structure (\`ls -R\`)
2. [ ] Identify the tech stack (\`package.json\`, \`requirements.txt\`, etc.)
3. [ ] Test the build/test commands
4. [ ] Document your findings using \`ctx add-doc\`

---
*Generated by OpenCode Context Dispatcher*
EOF

    log "Generated agent guide at $guide_path"
    echo "$guide_path"
}

# --------------------------------------------------------
# Main Dispatcher Function
# --------------------------------------------------------
context() {
    case "$1" in
        init)
            init_context "$2" "$3"
            ;;
        init-agent)
            local id=$(resolve_id "$2")
            generate_agent_guide "$id"
            ;;
        update)
            local id=$(resolve_id "$2")
            update_context "$id"
            ;;
        reindex)
            local id=$(resolve_id "$2")
            reindex_context "$id" "$3"
            ;;
        get)
            local id=$(resolve_id "$2")
            get_context "$id" "$3" "$4"
            ;;
        get-full)
            local id=$(resolve_id "$2")
            get_full_context "$id" "$3"
            ;;
        save-agent)
            save_agent_context "$2" "$3" "$4"
            ;;
        search-agent)
            search_agent_context "$2" "$3"
            ;;
        add-doc)
            local id=$(resolve_id "$2")
            add_doc "$id" "$3" "$4" "$5"
            ;;
        add-file)
            local id=$(resolve_id "$2")
            add_doc_file "$id" "$3" "$4" "$5"
            ;;
        link)
            local id=$(resolve_id "$2")
            link_docs "$id" "$3" "$4" "$5"
            ;;
        list-docs)
            local id=$(resolve_id "$2")
            list_docs "$id" "$3"
            ;;
        get-docs)
            local id=$(resolve_id "$2")
            get_docs "$id" "$3"
            ;;
        edit-doc)
            local id=$(resolve_id "$2")
            edit_doc "$id" "$3"
            ;;
        rm-doc)
            local id=$(resolve_id "$2")
            remove_doc "$id" "$3"
            ;;
        stats)
            local id=$(resolve_id "$2")
            project_stats "$id"
            ;;
        list)
            list_projects
            ;;
        prune)
            local id=$(resolve_id "$2")
            prune_context "$id"
            ;;
        diff)
            local id=$(resolve_id "$2")
            diff_context "$id" "$3"
            ;;
        sync-env)
            sync_env "$2" "$3" "${@:4}"
            ;;
        cleanup)
            cleanup_old_context "$2"
            ;;
        search-v|semantic-search)
            # Handled by ctx wrapper but for consistency:
            local id=$(resolve_id "$2")
            # This part is usually bypassed by the 'ctx' wrapper
            ;;
        help|*)
            echo "Context Dispatcher Commands:"
            echo ""
            echo "Project Management:"
            echo "  init <path> [name]       Initialize context for a project"
            echo "  init-agent <id>          Generate AGENTS.md guide in project root"
            echo "  update <project_id>      Incremental update from git"
            echo "  reindex <project_id>     Full reindex of project"
            echo "  list                     List all managed projects"
            echo "  stats <project_id>       Show project statistics"
            echo "  prune <project_id>       Remove excluded files from index"
            echo ""
            echo "Semantic Search (Vector Store):"
            echo "  sync-v <id>              Sync project to semantic index"
            echo "  search-v <id> <query>    Search code by meaning"
            echo ""
            echo "Context Retrieval:"
            echo "  get <project_id> [query] Get code context (optional search)"
            echo "  get-full <project_id>    Get full context (code + docs + rules)"
            echo "  diff <project_id> [days] Show recently added context"
            echo ""
            echo "Documentation & Rules:"
            echo "  add-doc <id> <type> <text> [title]  Add doc (types: rule/doc/note/prompt)"
            echo "  add-file <id> <type> <file> [title] Add doc from file"
            echo "  list-docs <id> [type]               List project documents"
            echo "  get-docs <id> [type]                Get document contents"
            echo "  edit-doc <id> <doc_id>              Edit document in \$EDITOR"
            echo "  rm-doc <id> <doc_id>                Remove a document"
            echo ""
            echo "Environment & Cross-Repo:"
            echo "  sync-env <src> <dest> [keys...]     Sync .env vars between projects"
            echo ""
            echo "Agent Context:"
            echo "  save-agent <name> <text> Save agent-specific context"
            echo "  search-agent <name> [q]  Search agent context"
            echo ""
            echo "Maintenance:"
            echo "  cleanup [days]           Clean old context (default: 30)"
            ;;
    esac
}


# alias ctx="source ~/.opencode/context-dispatcher.zsh && ~/.opencode/context"
# pwd
# echo "ctx-tool init finished"
# ctx

# Parse .gitignore for exclusion patterns
parse_gitignore_patterns() {
    local project_path="$1"
    local gitignore_path="$project_path/.gitignore"
    
    if [[ ! -f "$gitignore_path" ]]; then
        return
    fi

    # Use grep to find non-comment, non-empty lines from .gitignore
    grep -v '^\s*#' "$gitignore_path" | grep -v '^\s*$' | while read -r pattern; do
        # Trim leading/trailing whitespace
        pattern=$(echo "$pattern" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Ignore absolute paths or paths starting with ! (negation)
        [[ "$pattern" == /* ]] && continue
        [[ "$pattern" == !* ]] && continue
        
        # Handle directory matching (** for recursive, * for single-level)
        pattern=$(echo "$pattern" | sed -e 's/\*\*/.*/')
        
        # Escape some regex special chars
        pattern=$(echo "$pattern" | sed -e 's/\./\\./g')
        
        # Convert glob pattern to regex-like path matching
        pattern=$(echo "$pattern" | sed -e 's/\*/[^/]*/')
        
        echo "$pattern"
    done
}
