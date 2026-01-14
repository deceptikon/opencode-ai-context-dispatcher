#!/bin/bash
# uninstall.sh - Uninstall OpenCode Context Dispatcher
# This script removes the installation but PRESERVES your context data

set -e

OPENCODE_HOME="${HOME}/.opencode"

echo "🗑️  Removing OpenCode Context Dispatcher"
echo ""
echo "⚠️  This will remove the installation but KEEP your context data in:"
echo "   $OPENCODE_HOME/context/"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Removing symlinks and binaries..."

# Remove symlinks in ~/.local/bin
rm -f "$HOME/.local/bin/ctx"
echo "  ✓ Removed ctx"

rm -f "$HOME/.local/bin/ocx"
echo "  ✓ Removed ocx"

rm -f "$HOME/.local/bin/ocx-onboard"
echo "  ✓ Removed ocx-onboard"

# Remove bin directory but keep context
if [[ -d "$OPENCODE_HOME/bin" ]]; then
    rm -rf "$OPENCODE_HOME/bin"
    echo "  ✓ Removed bin/"
fi

# Remove templates
if [[ -d "$OPENCODE_HOME/templates" ]]; then
    rm -rf "$OPENCODE_HOME/templates"
    echo "  ✓ Removed templates/"
fi

# Remove lib and extensions (but not context)
if [[ -d "$OPENCODE_HOME/lib" ]]; then
    rm -rf "$OPENCODE_HOME/lib"
    echo "  ✓ Removed lib/"
fi

if [[ -d "$OPENCODE_HOME/extensions" ]]; then
    rm -rf "$OPENCODE_HOME/extensions"
    echo "  ✓ Removed extensions/"
fi

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "Your context data is still at:"
echo "   $OPENCODE_HOME/context/"
echo ""
echo "To fully remove (DELETE CONTEXT DATA):"
echo "   rm -rf $OPENCODE_HOME"
echo ""
