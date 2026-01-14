#!/bin/bash
set -e

echo "=========================================="
echo "  Prerequisites Installation"
echo "=========================================="
echo ""

# Detect package manager
install_package() {
    local package="$1"
    if command -v brew &> /dev/null; then
        brew install "$package"
    elif command -v apt-get &> /dev/null; then
        sudo apt-get install -y "$package"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$package"
    elif command -v yum &> /dev/null; then
        sudo yum install -y "$package"
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm "$package"
    else
        echo "Warning: No supported package manager found. Please install $package manually."
        return 1
    fi
}

# # 1. Create directories
# echo "[1/6] Creating directories..."
# mkdir -p ~/.opencode/context/{projects,agents,cache,logs,docs,vectors}
# mkdir -p ~/bin

# # 2. Copy dispatcher
# echo "[2/6] Installing context dispatcher..."
# cp context-dispatcher.zsh ~/.opencode/

# # 3. Copy wrapper and extensions
# echo "[3/6] Installing wrapper and extensions..."
# cp opencode-with-context ~/bin/
# chmod +x ~/bin/opencode-with-context

# # Copy Python extension if exists
# if [[ -d extensions ]]; then
#     mkdir -p ~/.opencode/extensions
#     cp -r extensions/* ~/.opencode/extensions/
#     chmod +x ~/.opencode/extensions/ctx-vector 2>/dev/null || true
# fi

# 4. Install shell dependencies
echo "Checking shell dependencies..."
if ! command -v jq &> /dev/null; then
    echo "  Installing jq..."
    install_package jq
else
    echo "  jq: OK"
fi

if ! command -v rg &> /dev/null; then
    echo "  Installing ripgrep..."
    install_package ripgrep
else
    echo "  ripgrep: OK"
fi

# # 5. Add to shell config
# echo "[5/6] Configuring shell..."
# SHELL_RC=""
# if [[ -f ~/.zshrc ]]; then
#     SHELL_RC="$HOME/.zshrc"
# elif [[ -f ~/.bashrc ]]; then
#     SHELL_RC="$HOME/.bashrc"
# fi

# if [[ -n "$SHELL_RC" ]] && ! grep -q "context-dispatcher" "$SHELL_RC"; then
#     echo "" >> "$SHELL_RC"
#     echo "# Context Dispatcher for AI Agents" >> "$SHELL_RC"
#     echo 'source ~/.opencode/context-dispatcher.zsh' >> "$SHELL_RC"
#     echo 'alias ctx="source ~/.opencode/context-dispatcher.zsh && context"' >> "$SHELL_RC"
#     echo 'alias ocx="opencode-with-context"' >> "$SHELL_RC"
#     echo "  Added to $SHELL_RC"
# else
#     echo "  Shell config: OK (already configured)"
# fi

# 6. Optional: Install Python dependencies for semantic search
echo "Python extensions (optional)..."
echo ""
echo "  ChromaDB + LlamaIndex enable semantic search:"
echo "  - Find code by meaning, not just keywords"
echo "  - Ask questions like 'how does auth work?'"
echo "  - Get AI-synthesized answers with source references"
echo ""

# Check if Python is available
if command -v python3 &> /dev/null; then
    read -p "  Install ChromaDB + LlamaIndex for semantic search? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  Installing Python dependencies..."
        python3 -m pip install --quiet chromadb llama-index llama-index-vector-stores-chroma 2>/dev/null || {
            echo "  Warning: pip install failed. You can install manually later:"
            echo "    pip install chromadb llama-index llama-index-vector-stores-chroma"
        }
        echo "  Python extensions: OK"
    else
        echo "  Skipped. Install later with:"
        echo "    pip install chromadb llama-index llama-index-vector-stores-chroma"
    fi
else
    echo "  Python3 not found. Semantic search features unavailable."
    echo "  To enable later: pip install chromadb llama-index llama-index-vector-stores-chroma"
fi

# echo ""
# echo "=========================================="
# echo "  Installation Complete!"
# echo "=========================================="
# echo ""
# echo "Quick start:"
# echo ""
# echo '  1. Initialize a project:'
# echo '     ctx init /path/to/project "Project Name"'
# echo ""
# echo "  2. Index the codebase:"
# echo "     ctx reindex <project_id>"
# echo ""
# echo "  3. Add rules/documentation:"
# echo '     ctx add-doc <project_id> rule "Always use TypeScript" "TS Rule"'
# echo ""
# echo "  4. Get full context for AI:"
# echo "     ctx get-full <project_id>"
# echo ""
# echo "  5. List projects:"
# echo "     ctx list"
# echo ""
# echo "  6. (Optional) Semantic search:"
# echo '     python ~/.opencode/extensions/vector_store.py index <project_id>'
# echo '     python ~/.opencode/extensions/vector_store.py search <project_id> "how does auth work"'
# echo ""
# echo "Run 'ctx help' for all commands."
# echo ""
# echo "Restart your shell or run: source $SHELL_RC"
