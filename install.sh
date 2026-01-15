#!/bin/bash
# install.sh - Install OpenCode Context Dispatcher
# This script sets up the complete context management system in ~/.opencode/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_HOME="${HOME}/.opencode"

echo "🚀 Installing OpenCode Context Dispatcher"
echo ""
echo "Repository: $REPO_DIR"
echo "Install location: $OPENCODE_HOME"
echo ""

# Create directory structure
echo "📁 Creating directories..."
mkdir -p "$OPENCODE_HOME"/{bin,lib,templates,context/{projects,docs,agents,cache,logs},extensions}

# Install prerequisites
echo " Download and install prerequisites..."
./install-ctx-prerequisites.sh
echo "  ✓ prerequisites installed"

# Copy core files
echo "📋 Installing core files..."

# Main dispatcher (as symlink to avoid duplication)
ln -sf "$REPO_DIR/context-dispatcher.zsh" "$OPENCODE_HOME/context-dispatcher.zsh"
echo "  ✓ context-dispatcher.zsh"

# Executables
cp "$REPO_DIR/ctx" "$OPENCODE_HOME/bin/ctx"
chmod +x "$OPENCODE_HOME/bin/ctx"
echo "  ✓ ctx (Python wrapper)"

cp "$REPO_DIR/ocx" "$OPENCODE_HOME/bin/ocx"
chmod +x "$OPENCODE_HOME/bin/ocx"
echo "  ✓ ocx (main command)"

cp "$REPO_DIR/ocx-onboard" "$OPENCODE_HOME/bin/ocx-onboard"
chmod +x "$OPENCODE_HOME/bin/ocx-onboard"
echo "  ✓ ocx-onboard (helper)"

# Templates
echo "📄 Installing templates..."
cp "$REPO_DIR"/templates/*.md "$OPENCODE_HOME/templates/"
echo "  ✓ onboarding templates"

# Copy optional extensions
if [[ -f "$REPO_DIR/extensions/vector_store.py" ]]; then
    cp "$REPO_DIR/extensions/vector_store.py" "$OPENCODE_HOME/extensions/"
    echo "  ✓ vector_store.py (optional)"
fi

# Create symlinks in ~/.local/bin (or ~/bin if preferred)
echo ""
echo "🔗 Creating command symlinks..."

mkdir -p "$HOME/.local/bin"

ln -sf "$OPENCODE_HOME/bin/ctx" "$HOME/.local/bin/ctx"
echo "  ✓ ctx → ~/.local/bin/ctx"

ln -sf "$OPENCODE_HOME/bin/ocx" "$HOME/.local/bin/ocx"
echo "  ✓ ocx → ~/.local/bin/ocx"

ln -sf "$OPENCODE_HOME/bin/ocx" "$HOME/.local/bin/opencode-with-context"
echo "  ✓ opencode-with-context → ~/.local/bin/opencode-with-context"

ln -sf "$OPENCODE_HOME/bin/ocx-onboard" "$HOME/.local/bin/ocx-onboard"
echo "  ✓ ocx-onboard → ~/.local/bin/ocx-onboard"

# Add to shell profile if not already there
echo ""
echo "⚙️  Configuring shell..."

for SHELL_RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if [[ -f "$SHELL_RC" ]]; then
        if ! grep -q "\.local/bin" "$SHELL_RC"; then
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
            echo "  ✓ Added ~/.local/bin to PATH in $(basename "$SHELL_RC")"
        fi
    fi
done

# Setup Python virtual environment if not exists
if command -v python3 &> /dev/null; then
    if [[ ! -d "$OPENCODE_HOME/venv" ]]; then
        echo "🐍 Creating Python virtual environment..."
        # Prefer Python 3.12 for stability with heavy dependencies
        PYTHON_STABLE="/usr/bin/python3.12"
        if [[ -x "$PYTHON_STABLE" ]]; then
            $PYTHON_STABLE -m venv "$OPENCODE_HOME/venv"
        else
            python3 -m venv "$OPENCODE_HOME/venv"
        fi
        echo "  ✓ venv created in $OPENCODE_HOME/venv"
        echo "  ℹ Note: To enable semantic search, run:"
        echo "    $OPENCODE_HOME/venv/bin/pip install chromadb llama-index llama-index-vector-stores-chroma"
    fi
fi

# Verify installation
echo ""
echo "✅ Verifying installation..."

if command -v ctx &> /dev/null; then
    echo "  ✓ ctx command available"
else
    echo "  ⚠️  ctx not in PATH (reload shell or check PATH)"
fi

if command -v ocx &> /dev/null; then
    echo "  ✓ ocx command available"
else
    echo "  ⚠️  ocx not in PATH (reload shell or check PATH)"
fi

if command -v ocx-onboard &> /dev/null; then
    echo "  ✓ ocx-onboard command available"
else
    echo "  ⚠️  ocx-onboard not in PATH (reload shell or check PATH)"
fi

# Reload shell environment for current session
echo ""
echo "⚡ Reloading shell environment..."
if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc" 2>/dev/null || true
elif [[ -f "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc" 2>/dev/null || true
fi

# Re-verify after reload
echo ""
echo "✅ Final verification after reload..."
if command -v ctx &> /dev/null; then
    echo "  ✓ ctx ready"
else
    echo "  ⚠️  ctx still not found - try: source ~/.bashrc"
fi

if command -v ocx &> /dev/null; then
    echo "  ✓ ocx ready"
else
    echo "  ⚠️  ocx still not found - try: source ~/.bashrc"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ Installation Complete & Ready!                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Install location: $OPENCODE_HOME"
echo ""
echo "🚀 You can now use:"
echo "   ctx list                    # List all projects"
echo "   ocx-onboard <project-id>    # Run onboarding for a project"
echo "   ocx <project-id>            # Start interactive mode"
echo ""
echo "󰃁 Quick start:"
echo ""
echo '  1. Initialize a project:'
echo '     ctx init /path/to/project "Project Name"'
echo ""
echo "  2. Index the codebase:"
echo "     ctx reindex <project_id>"
echo ""
echo "  3. Add rules/documentation:"
echo '     ctx add-doc <project_id> rule "Always use TypeScript" "TS Rule"'
echo ""
echo "  4. Get full context for AI:"
echo "     ctx get-full <project_id>"
echo ""
echo "  5. List projects:"
echo "     ctx list"
echo ""
echo "  6. (Optional) Semantic search:"
echo '     python ~/.opencode/extensions/vector_store.py index <project_id>'
echo '     python ~/.opencode/extensions/vector_store.py search <project_id> "how does auth work"'
echo ""
echo "📖 Documentation:"
echo "   - README.md                          - Main guide"
echo "   - ONBOARDING_PROMPT_TEMPLATE.md     - Generic onboarding prompt"
echo "   - POC_TEST_GUIDE.md                 - How to test the system"
echo ""
echo "🔧 Everything is in: ~/.opencode/"
echo ""
echo "Run 'ctx help' for all commands."
