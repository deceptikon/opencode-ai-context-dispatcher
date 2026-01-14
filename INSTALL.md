# Installation Guide

## Quick Install

```bash
cd /path/to/opencode-ai-context-dispatcher
./install.sh
```

That's it! Everything will be installed to `~/.opencode/` with symlinks in `~/.local/bin/`.

## What Gets Installed

### Directory Structure

```
~/.opencode/
├── bin/                          # Executables
│   ├── ctx                      # Context management CLI (Python)
│   ├── ocx                      # OpenCode wrapper with context
│   └── ocx-onboard             # Onboarding helper
├── templates/                   # Prompt templates
│   └── ONBOARDING_PROMPT_TEMPLATE.md
├── context/                     # User data (your projects)
│   ├── projects/               # Project configs
│   ├── docs/                   # Project context (JSONL files)
│   ├── agents/                 # Agent-specific context
│   ├── cache/                  # Temporary cache
│   └── logs/                   # System logs
├── extensions/                 # Optional: ChromaDB, semantic search
└── context-dispatcher.zsh      # Core functions (symlink to repo)
```

### Commands Available After Install

```bash
ctx list                    # List all projects
ctx add-doc <id> <type> <content> <title>  # Save context
ctx get-docs <id> [type]    # Retrieve context
ctx list-docs <id>          # List project documents

ocx <project-id>            # Interactive mode (no message)
ocx -c full <id> "message"  # Interactive with message/prompt
ocx-onboard <id>            # Run onboarding session
```

## Installation Details

### What install.sh Does

1. ✅ Creates `~/.opencode/` directory structure
2. ✅ Copies executable scripts (ctx, ocx, ocx-onboard)
3. ✅ Copies template files (ONBOARDING_PROMPT_TEMPLATE.md)
4. ✅ Creates symlinks in `~/.local/bin/` for easy access
5. ✅ Adds `~/.local/bin/` to shell PATH (if needed)
6. ✅ Verifies installation

### Requirements

- Python 3.7+ (for ctx command)
- Bash/Zsh shell
- jq (for JSON processing)
- ripgrep (rg) (optional, for better search)

### File Locations

After installation, files are in ONE place: `~/.opencode/`

- Binaries: `~/.opencode/bin/`
- Templates: `~/.opencode/templates/`
- Context data: `~/.opencode/context/`
- Core functions: `~/.opencode/context-dispatcher.zsh` (symlink to repo)

Symlinks in `~/.local/bin/` point back to `~/.opencode/bin/` for convenience.

## Uninstall

To remove the installation (but keep your context data):

```bash
./uninstall.sh
```

Or manually:

```bash
rm -rf ~/.opencode/bin
rm -rf ~/.opencode/templates
rm -f ~/.local/bin/{ctx,ocx,ocx-onboard}
```

To completely remove everything including context data:

```bash
rm -rf ~/.opencode
```

## After Installation

1. **Reload your shell** to get the commands in PATH:
   ```bash
   source ~/.bashrc   # or ~/.zshrc for zsh
   ```

2. **Verify installation**:
   ```bash
   ctx list
   ocx --help
   ocx-onboard --help
   ```

3. **Initialize a project** (if not done yet):
   ```bash
   ctx init /path/to/project "Project Name"
   ```

4. **Run onboarding** for a project:
   ```bash
   ocx-onboard <project-id>
   ```

## Troubleshooting

### Commands Not Found

If `ctx`, `ocx`, or `ocx-onboard` are not found:

1. Reload shell:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

2. Check PATH:
   ```bash
   echo $PATH | grep .local/bin
   ```

3. If `.local/bin` not in PATH, add it manually:
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

### Permission Denied

If you get permission denied errors:

```bash
chmod +x ~/.opencode/bin/*
```

### Context Directory Issues

If context commands fail, check permissions:

```bash
ls -la ~/.opencode/context/
chmod 755 ~/.opencode/context/*
```

## Configuration

No additional configuration needed! The system works out of the box.

Optional: Set environment variables to customize:

```bash
# Set default model (default: opencode/big-pickle)
export OCX_MODEL="opencode/big-pickle"

# Set context cache directory (default: ~/.opencode/context/cache)
export OCX_CACHE_DIR="$HOME/.opencode/context/cache"
```

## Development Installation

If you want to hack on the code and test changes:

```bash
# Clone/navigate to the repo
cd /home/lexx/MyWork/opencode-ai-context-dispatcher

# Run install from the repo
./install.sh

# Changes to files in the repo will be used immediately
# (since ~/.opencode/context-dispatcher.zsh is a symlink)

# To reinstall after changes:
./install.sh
```

## Multiple Machines

You can install on multiple machines and sync context:

1. Install on machine A:
   ```bash
   ./install.sh
   ```

2. Initialize projects and run onboarding

3. Sync context to machine B:
   ```bash
   # On machine A
   tar czf context-backup.tar.gz ~/.opencode/context/

   # Copy to machine B
   scp context-backup.tar.gz user@machine-b:~

   # On machine B
   tar xzf context-backup.tar.gz  # extracts to ~/.opencode/context/
   ```

4. Install on machine B:
   ```bash
   ./install.sh
   ```

All your projects and context will be available!

## Getting Help

- **README.md** - Main documentation
- **POC_TEST_GUIDE.md** - How to test the system
- **ONBOARDING_QUICK_START.md** - Quick reference
- **CTX_TOOLS_GUIDE.md** - Detailed tool documentation

## Next Steps

After installation:

1. Read **README.md** for overview
2. See **ONBOARDING_QUICK_START.md** for quick start
3. Run `ocx-onboard <project-id>` to onboard a project
4. Run `ocx <project-id>` to start using it!

---

**Everything is in `~/.opencode/` - no more scattered files!** 🎉
