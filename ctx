#!/usr/bin/env python3
"""
ctx - Standalone context management tool
Works from any shell (bash, sh, zsh)
Provides add-doc, get-docs, list, and other context functions
"""

import json
import os
import sys
import hashlib
from pathlib import Path
from datetime import datetime

HOME = os.path.expanduser("~")
CONTEXT_ROOT = Path(HOME) / ".opencode" / "context"
PROJECTS_DIR = CONTEXT_ROOT / "projects"
DOCS_DIR = CONTEXT_ROOT / "docs"

def ensure_dirs():
    """Ensure all necessary directories exist"""
    DOCS_DIR.mkdir(parents=True, exist_ok=True)

def add_doc(project_id, doc_type, content, title):
    """Add a document to project context"""
    ensure_dirs()
    
    docs_file = DOCS_DIR / project_id / "docs.jsonl"
    docs_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Generate ID from title hash
    doc_id = hashlib.md5(title.encode()).hexdigest()[:8]
    
    # Create document
    doc = {
        "id": doc_id,
        "type": doc_type,
        "title": title,
        "content": content,
        "timestamp": datetime.now().isoformat() + "+06:00"
    }
    
    # Append to JSONL file
    with open(docs_file, 'a') as f:
        f.write(json.dumps(doc, ensure_ascii=False) + '\n')
    
    print(f"✓ Saved {doc_type}: {title} ({doc_id})")

def get_docs(project_id, doc_type=None):
    """Get documents from project context"""
    docs_file = DOCS_DIR / project_id / "docs.jsonl"
    
    if not docs_file.exists():
        print(f"No context found for project {project_id}")
        return
    
    with open(docs_file, 'r') as f:
        for line in f:
            try:
                doc = json.loads(line)
                if doc_type is None or doc.get('type') == doc_type:
                    print(f"[{doc.get('type')}] {doc.get('title')}")
                    print(f"  {doc.get('content')[:100]}...")
                    print()
            except json.JSONDecodeError:
                continue

def list_docs(project_id):
    """List all documents for a project"""
    docs_file = DOCS_DIR / project_id / "docs.jsonl"
    
    if not docs_file.exists():
        print(f"No context found for project {project_id}")
        return
    
    count = 0
    with open(docs_file, 'r') as f:
        for line in f:
            try:
                doc = json.loads(line)
                doc_type = doc.get('type', 'unknown')
                title = doc.get('title', 'untitled')
                print(f"  [{doc_type}] {title}")
                count += 1
            except json.JSONDecodeError:
                continue
    
    print(f"\nTotal: {count} documents")

def list_projects():
    """List all projects in context database"""
    projects_dir = Path(HOME) / ".opencode" / "context" / "projects"
    
    if not projects_dir.exists():
        print("No projects found")
        return
    
    projects = sorted([p.name for p in projects_dir.iterdir() if p.is_dir()])
    
    if not projects:
        print("No projects found")
        return
    
    print("Available projects:")
    for project_id in projects:
        config_file = projects_dir / project_id / "config.json"
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    name = config.get('name', 'Unknown')
                    print(f"  {project_id}")
                    print(f"    Name: {name}")
            except:
                print(f"  {project_id}")
        else:
            print(f"  {project_id}")

def main():
    if len(sys.argv) < 2:
        print("Usage: ctx <command> [args...]")
        print("Commands:")
        print("  list                        - List all projects")
        print("  add-doc <id> <type> <content> <title>")
        print("  get-docs <id> [type]")
        print("  list-docs <id>")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "list":
        list_projects()
    
    elif command == "add-doc":
        if len(sys.argv) < 6:
            print("Usage: ctx add-doc <project_id> <type> <content> <title>")
            sys.exit(1)
        add_doc(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    
    elif command == "get-docs":
        project_id = sys.argv[2] if len(sys.argv) > 2 else None
        doc_type = sys.argv[3] if len(sys.argv) > 3 else None
        if not project_id:
            print("Usage: ctx get-docs <project_id> [type]")
            sys.exit(1)
        get_docs(project_id, doc_type)
    
    elif command == "list-docs":
        if len(sys.argv) < 3:
            print("Usage: ctx list-docs <project_id>")
            sys.exit(1)
        list_docs(sys.argv[2])
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()
