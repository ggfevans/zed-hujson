#!/usr/bin/env bash
# Belt-and-braces verification (decision 4):
# 1. Compile each Zed query against the generated grammar.
# 2. Confirm every node referenced in queries/hujson/*.scm exists in
#    grammars/hujson/src/node-types.json.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRAMMAR_DIR="$ROOT/grammars/hujson"
QUERIES_DIR="$ROOT/queries/hujson"
NODE_TYPES="$GRAMMAR_DIR/src/node-types.json"

if [ ! -d "$QUERIES_DIR" ]; then
  echo "no queries/hujson directory; nothing to check"
  exit 0
fi

shopt -s nullglob
query_files=("$QUERIES_DIR"/*.scm)

if [ ${#query_files[@]} -eq 0 ]; then
  echo "no .scm files in $QUERIES_DIR; nothing to check"
  exit 0
fi

if [ ! -f "$NODE_TYPES" ]; then
  echo "ERROR: $NODE_TYPES not found — run \`tree-sitter generate\` in $GRAMMAR_DIR" >&2
  exit 1
fi

# Step 1: tree-sitter query compile check.
fail=0
for f in "${query_files[@]}"; do
  if ! (cd "$GRAMMAR_DIR" && tree-sitter query "$f" >/dev/null 2>&1); then
    # tree-sitter query may emit warnings without failing; capture stderr to detect real errors.
    out=$(cd "$GRAMMAR_DIR" && tree-sitter query "$f" 2>&1 || true)
    if echo "$out" | grep -qiE 'error|invalid'; then
      echo "QUERY ERROR in $f:" >&2
      echo "$out" >&2
      fail=1
    fi
  fi
done

# Step 2: node-name audit.
nodes=$(grep -hoE '\([a-z_][a-z0-9_]*' "${query_files[@]}" | sed 's/^(//' | sort -u)
for n in $nodes; do
  if ! grep -q "\"$n\"" "$NODE_TYPES"; then
    echo "MISSING node in node-types.json: $n" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "queries OK (${#query_files[@]} files, $(echo "$nodes" | wc -w | tr -d ' ') unique nodes)"
