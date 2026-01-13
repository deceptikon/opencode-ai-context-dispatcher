#!/bin/bash
echo "Uninstalling Context Dispatcher System..."

# 1. Remove installed files
rm -f ~/.opencode/context-dispatcher.zsh
rm -f ~/bin/opencode-with-context

echo "Removed dispatcher scripts"

# 2. Remove context data (ask first)
if [[ -d ~/.opencode/context ]]; then
    read -p "Remove all context data (~/.opencode/context)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.opencode/context
        echo "Removed context data"
    else
        echo "Kept context data"
    fi
fi

# 3. Remove from shell config
for rc_file in ~/.zshrc ~/.bashrc; do
    if [[ -f "$rc_file" ]] && grep -q "context-dispatcher" "$rc_file"; then
        # Create backup
        cp "$rc_file" "${rc_file}.bak"
        # Remove context-dispatcher lines
        grep -v "context-dispatcher\|alias ctx=\|alias ocx=" "$rc_file" > "${rc_file}.tmp"
        mv "${rc_file}.tmp" "$rc_file"
        echo "Cleaned $rc_file (backup at ${rc_file}.bak)"
    fi
done

# 4. Clean up empty .opencode directory if no other files
if [[ -d ~/.opencode ]] && [[ -z "$(ls -A ~/.opencode 2>/dev/null)" ]]; then
    rmdir ~/.opencode
    echo "Removed empty ~/.opencode directory"
fi

echo ""
echo "Uninstall complete!"
echo "Please restart your shell or run: source ~/.zshrc"
