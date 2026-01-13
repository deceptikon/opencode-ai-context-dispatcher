#!/bin/bash
echo "Installing Context Dispatcher System..."

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
        echo "Error: No supported package manager found. Please install $package manually."
        return 1
    fi
}

# 1. Create directories
mkdir -p ~/.opencode/context/{projects,agents,cache,logs}
mkdir -p ~/bin

# 2. Copy dispatcher
cp context-dispatcher.zsh ~/.opencode/

# 3. Copy wrapper
cp opencode-with-context ~/bin/
chmod +x ~/bin/opencode-with-context

# 4. Install dependencies
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    install_package jq
fi

if ! command -v rg &> /dev/null; then
    echo "Installing ripgrep..."
    install_package ripgrep
fi

# 5. Add to shell config
SHELL_RC=""
if [[ -f ~/.zshrc ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -f ~/.bashrc ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]] && ! grep -q "context-dispatcher" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# Context Dispatcher for AI Agents" >> "$SHELL_RC"
    echo 'source ~/.opencode/context-dispatcher.zsh' >> "$SHELL_RC"
    echo 'alias ctx="source ~/.opencode/context-dispatcher.zsh && context"' >> "$SHELL_RC"
    echo 'alias ocx="opencode-with-context"' >> "$SHELL_RC"
fi

echo "Installation complete!"
echo ""
echo "Quick start:"
echo '1. Initialize a project: ctx init /path/to/project "Project Name"'
echo "2. Index it: ctx reindex <project_id>"
echo "3. Use with opencode: ocx <project_id> 'your command'"
echo "4. List projects: ctx list"
