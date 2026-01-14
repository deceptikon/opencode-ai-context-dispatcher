#!/usr/bin/env python3
"""
Vector Store Extension for Context Dispatcher
Integrates ChromaDB + LlamaIndex for semantic search

Install dependencies:
    pip install chromadb llama-index

Usage:
    python vector_store.py index <project_id>          # Index from shell context
    python vector_store.py index-dir <project_id>      # Index directly from codebase
    python vector_store.py search <project_id> "query" # Semantic search
    python vector_store.py query <project_id> "query"  # Query with LlamaIndex
    python vector_store.py sync <project_id>           # Sync from shell index
"""

import os
import sys
import json
import argparse
from pathlib import Path
from datetime import datetime

# Configuration
CONTEXT_ROOT = Path.home() / ".opencode" / "context"
PROJECTS_DIR = CONTEXT_ROOT / "projects"
DOCS_DIR = CONTEXT_ROOT / "docs"
VECTOR_DIR = CONTEXT_ROOT / "vectors"


def ensure_dirs():
    """Create necessary directories."""
    VECTOR_DIR.mkdir(parents=True, exist_ok=True)


def load_project_index(project_id: str) -> dict:
    """Load the shell-generated index.json."""
    index_file = PROJECTS_DIR / project_id / "index.json"
    if not index_file.exists():
        return {"files": {}, "chunks": []}
    with open(index_file) as f:
        return json.load(f)


def load_project_docs(project_id: str) -> list:
    """Load manual docs/rules from docs.jsonl."""
    docs_file = DOCS_DIR / project_id / "docs.jsonl"
    if not docs_file.exists():
        return []
    docs = []
    with open(docs_file) as f:
        for line in f:
            if line.strip():
                docs.append(json.loads(line))
    return docs


def load_project_config(project_id: str) -> dict:
    """Load project configuration."""
    config_file = PROJECTS_DIR / project_id / "config.json"
    if not config_file.exists():
        return {}
    with open(config_file) as f:
        return json.load(f)


class VectorStoreManager:
    """Manages ChromaDB + LlamaIndex integration."""

    def __init__(self, project_id: str):
        self.project_id = project_id
        self.config = load_project_config(project_id)
        self.db_path = VECTOR_DIR / project_id
        self.db_path.mkdir(parents=True, exist_ok=True)

        self._chroma_client = None
        self._collection = None

    @property
    def chroma_client(self):
        """Lazy-load ChromaDB client."""
        if self._chroma_client is None:
            try:
                import chromadb

                self._chroma_client = chromadb.PersistentClient(path=str(self.db_path))
            except ImportError:
                print("ChromaDB not installed. Run: pip install chromadb")
                sys.exit(1)
        return self._chroma_client

    @property
    def collection(self):
        """Get or create ChromaDB collection."""
        if self._collection is None:
            self._collection = self.chroma_client.get_or_create_collection(
                name=f"project_{self.project_id}",
                metadata={"project": self.config.get("name", self.project_id)},
            )
        return self._collection

    def index_from_shell(self):
        """Index content from shell-generated index.json and docs."""
        print(f"Indexing project {self.project_id} into ChromaDB...")

        # Load shell index
        shell_index = load_project_index(self.project_id)
        chunks = shell_index.get("chunks", [])

        # Load manual docs
        docs = load_project_docs(self.project_id)

        # Prepare documents for ChromaDB
        documents = []
        metadatas = []
        ids = []

        # Add code chunks
        for chunk in chunks:
            chunk_id = chunk.get("id", "")
            content = chunk.get("content", "")
            if content and len(content.strip()) > 0:
                documents.append(content)
                metadatas.append(
                    {
                        "type": "code",
                        "path": chunk.get("path", ""),
                        "source": "shell_index",
                    }
                )
                ids.append(f"code_{chunk_id.replace('#', '_').replace('/', '_')}")

        # Add manual docs
        for doc in docs:
            doc_id = doc.get("id", "")
            content = doc.get("content", "")
            if content and len(content.strip()) > 0:
                documents.append(content)
                metadatas.append(
                    {
                        "type": doc.get("type", "doc"),
                        "title": doc.get("title", ""),
                        "source": "manual",
                    }
                )
                ids.append(f"doc_{doc_id}")

        if not documents:
            print("No content to index")
            return

        # Clear existing collection
        try:
            self.chroma_client.delete_collection(f"project_{self.project_id}")
            self._collection = None
        except:
            pass

        # Add in batches
        batch_size = 100
        for i in range(0, len(documents), batch_size):
            batch_docs = documents[i : i + batch_size]
            batch_meta = metadatas[i : i + batch_size]
            batch_ids = ids[i : i + batch_size]

            self.collection.add(
                documents=batch_docs, metadatas=batch_meta, ids=batch_ids
            )
            print(
                f"  Indexed {min(i + batch_size, len(documents))}/{len(documents)} items"
            )

        print(f"Indexed {len(documents)} items into ChromaDB")

    def index_from_directory(self):
        """Index directly from the project directory using LlamaIndex."""
        try:
            from llama_index.core import (
                SimpleDirectoryReader,
                VectorStoreIndex,
                StorageContext,
            )
            from llama_index.vector_stores.chroma import ChromaVectorStore
        except ImportError:
            try:
                # Try older import style
                from llama_index import (
                    SimpleDirectoryReader,
                    VectorStoreIndex,
                    StorageContext,
                )
                from llama_index.vector_stores import ChromaVectorStore
            except ImportError:
                print(
                    "LlamaIndex not installed. Run: pip install llama-index llama-index-vector-stores-chroma"
                )
                sys.exit(1)

        project_path = self.config.get("path")
        if not project_path or not Path(project_path).exists():
            print(f"Error: Project path not found: {project_path}")
            return

        print(f"Indexing {project_path} directly with LlamaIndex...")

        # Get exclude patterns from config
        exclude = self.config.get(
            "exclude_patterns", ["node_modules", ".git", "dist", "build"]
        )
        include_ext = self.config.get(
            "include_extensions", [".py", ".js", ".ts", ".jsx", ".tsx"]
        )

        # Load documents
        try:
            documents = SimpleDirectoryReader(
                input_dir=project_path,
                recursive=True,
                required_exts=include_ext,
                exclude=exclude,
            ).load_data()
        except Exception as e:
            print(f"Error loading documents: {e}")
            return

        print(f"Loaded {len(documents)} documents")

        # Also load manual docs
        manual_docs = load_project_docs(self.project_id)
        if manual_docs:
            from llama_index.core import Document

            for doc in manual_docs:
                documents.append(
                    Document(
                        text=doc.get("content", ""),
                        metadata={
                            "type": doc.get("type", "doc"),
                            "title": doc.get("title", ""),
                            "source": "manual",
                        },
                    )
                )
            print(f"Added {len(manual_docs)} manual documents")

        # Create vector store
        vector_store = ChromaVectorStore(chroma_collection=self.collection)
        storage_context = StorageContext.from_defaults(vector_store=vector_store)

        # Create index
        index = VectorStoreIndex.from_documents(
            documents, storage_context=storage_context, show_progress=True
        )

        print(f"Indexed {len(documents)} documents into ChromaDB")
        return index

    def search(self, query: str, n_results: int = 5, doc_type: str = None) -> list:
        """Semantic search using ChromaDB directly."""
        where_filter = None
        if doc_type:
            where_filter = {"type": doc_type}

        results = self.collection.query(
            query_texts=[query], n_results=n_results, where=where_filter
        )

        formatted = []
        if results and results.get("documents") and results["documents"][0]:
            for i, doc in enumerate(results["documents"][0]):
                meta = results["metadatas"][0][i] if results.get("metadatas") else {}
                distance = results["distances"][0][i] if results.get("distances") else 0
                formatted.append(
                    {
                        "content": doc,
                        "type": meta.get("type", "unknown"),
                        "path": meta.get("path", meta.get("title", "")),
                        "relevance": round(1 - distance, 3) if distance < 1 else 0,
                    }
                )

        return formatted

    def query_with_llama(self, query: str, n_results: int = 5) -> dict:
        """Query using LlamaIndex for RAG-style answers."""
        try:
            from llama_index.core import VectorStoreIndex, StorageContext
            from llama_index.vector_stores.chroma import ChromaVectorStore
        except ImportError:
            try:
                from llama_index import VectorStoreIndex, StorageContext
                from llama_index.vector_stores import ChromaVectorStore
            except ImportError:
                print("LlamaIndex not installed.")
                return {"answer": "LlamaIndex not available", "sources": []}

        # Create LlamaIndex wrapper around existing ChromaDB collection
        vector_store = ChromaVectorStore(chroma_collection=self.collection)

        # Create index from existing vector store
        index = VectorStoreIndex.from_vector_store(vector_store)

        # Query
        query_engine = index.as_query_engine(similarity_top_k=n_results)
        response = query_engine.query(query)

        sources = []
        if hasattr(response, "source_nodes"):
            for node in response.source_nodes:
                text = node.node.text if hasattr(node.node, "text") else str(node)
                sources.append(text[:300] + "..." if len(text) > 300 else text)

        return {"answer": str(response), "sources": sources}

    def get_stats(self) -> dict:
        """Get collection statistics."""
        return {
            "project_id": self.project_id,
            "project_name": self.config.get("name", "Unknown"),
            "total_items": self.collection.count(),
            "db_path": str(self.db_path),
        }


def main():
    parser = argparse.ArgumentParser(
        description="Vector Store Extension for Context Dispatcher"
    )
    parser.add_argument(
        "command", choices=["index", "index-dir", "search", "query", "stats", "sync"]
    )
    parser.add_argument("project_id", help="Project ID")
    parser.add_argument("query_text", nargs="?", help="Search/query text")
    parser.add_argument(
        "-n", "--num-results", type=int, default=5, help="Number of results"
    )
    parser.add_argument(
        "-t", "--type", help="Filter by doc type (code/rule/doc/note/prompt)"
    )
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()
    ensure_dirs()

    manager = VectorStoreManager(args.project_id)

    if args.command == "index" or args.command == "sync":
        manager.index_from_shell()

    elif args.command == "index-dir":
        manager.index_from_directory()

    elif args.command == "search":
        if not args.query_text:
            print("Error: Search query required")
            sys.exit(1)

        results = manager.search(args.query_text, args.num_results, args.type)

        if args.json:
            print(json.dumps(results, indent=2, ensure_ascii=False))
        else:
            if not results:
                print("No results found")
            for i, r in enumerate(results, 1):
                print(f"\n--- Result {i} (relevance: {r['relevance']}) ---")
                print(f"Type: {r['type']} | Path: {r['path']}")
                content = r["content"]
                print(content[:500] + "..." if len(content) > 500 else content)

    elif args.command == "query":
        if not args.query_text:
            print("Error: Query required")
            sys.exit(1)

        results = manager.query_with_llama(args.query_text, args.num_results)

        if args.json:
            print(json.dumps(results, indent=2, ensure_ascii=False))
        else:
            print("\n=== Answer ===")
            print(results.get("answer", "No answer"))
            if results.get("sources"):
                print("\n=== Sources ===")
                for i, s in enumerate(results["sources"], 1):
                    print(f"\n[{i}] {s}")

    elif args.command == "stats":
        stats = manager.get_stats()
        if args.json:
            print(json.dumps(stats, indent=2))
        else:
            print(f"Project: {stats['project_name']} ({stats['project_id']})")
            print(f"Total items: {stats['total_items']}")
            print(f"DB path: {stats['db_path']}")


if __name__ == "__main__":
    main()
