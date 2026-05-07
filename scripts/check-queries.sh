#!/usr/bin/env bash
# Audit Zed queries against the grammar revision pinned in extension.toml.
#
# Steps:
#   1. Parse [grammars.hujson] -> repository + rev from extension.toml.
#   2. Shallow-clone the grammar repo at that rev (cached under target/).
#   3. Confirm every node referenced in queries/hujson/*.scm exists in the
#      cloned src/node-types.json.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUERIES_DIR="$ROOT/queries/hujson"
CACHE_DIR="$ROOT/target/grammar-cache"
EXTENSION_TOML="$ROOT/extension.toml"

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

# Parse [grammars.hujson] repository + rev from extension.toml.
# Awk pulls the values out of the [grammars.hujson] block; sed strips quotes.
REPO=$(awk '/^\[grammars\.hujson\]/{f=1;next} /^\[/{f=0} f && /^repository[ \t]*=/{print; exit}' "$EXTENSION_TOML" \
       | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/')
REV=$(awk '/^\[grammars\.hujson\]/{f=1;next} /^\[/{f=0} f && /^rev[ \t]*=/{print; exit}' "$EXTENSION_TOML" \
       | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/')

if [ -z "$REPO" ] || [ -z "$REV" ]; then
  echo "ERROR: could not parse [grammars.hujson] repository/rev from $EXTENSION_TOML" >&2
  exit 1
fi

GRAMMAR_DIR="$CACHE_DIR/$REV"
NODE_TYPES="$GRAMMAR_DIR/src/node-types.json"

if [ ! -f "$NODE_TYPES" ]; then
  echo "fetching grammar $REPO @ $REV"
  rm -rf "$GRAMMAR_DIR"
  mkdir -p "$GRAMMAR_DIR"
  git clone --quiet --filter=blob:none "$REPO" "$GRAMMAR_DIR"
  (cd "$GRAMMAR_DIR" && git checkout --quiet "$REV")
fi

if [ ! -f "$NODE_TYPES" ]; then
  echo "ERROR: $NODE_TYPES still missing after clone" >&2
  exit 1
fi

# Audit every (node_name) capture against node-types.json.
nodes=$(grep -hoE '\([a-z_][a-z0-9_]*' "${query_files[@]}" | sed 's/^(//' | sort -u)

fail=0
for n in $nodes; do
  if ! grep -q "\"$n\"" "$NODE_TYPES"; then
    echo "MISSING node in node-types.json: $n" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "queries OK (${#query_files[@]} files, $(echo "$nodes" | wc -w | tr -d ' ') unique nodes, grammar @ ${REV:0:8})"
