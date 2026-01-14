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
cp "$REPO_DIR/ONBOARDING_PROMPT_TEMPLATE.md" "$OPENCODE_HOME/templates/"
echo "  ✓ ONBOARDING_PROMPT_TEMPLATE.md"

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

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ Installation Complete!                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Install location: $OPENCODE_HOME"
echo ""
echo "📚 Quick start:"
echo "   1. Reload your shell:  source ~/.bashrc  (or ~/.zshrc)"
echo "   2. List projects:      ctx list"
echo "   3. Run onboarding:     ocx-onboard <project-id>"
echo ""
echo "📖 Documentation:"
echo "   - README.md                          - Main guide"
echo "   - ONBOARDING_PROMPT_TEMPLATE.md     - Generic onboarding prompt"
echo "   - POC_TEST_GUIDE.md                 - How to test the system"
echo ""
echo "🔧 Directory structure:"
echo "   ~/.opencode/"
echo "   ├── bin/                (executables)"
echo "   ├── templates/          (prompt templates)"
echo "   ├── context/            (project databases)"
echo "   │  ├── projects/       (project configs)"
echo "   │  ├── docs/           (project context JSONL)"
echo "   │  └── ..."
echo "   └── context-dispatcher.zsh (symlink to repo)"
echo ""
echo "All set! You can now use ctx and ocx commands from anywhere."
echo ""
