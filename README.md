# HuJSON for Zed

A [Zed](https://zed.dev) extension providing syntax highlighting and editor support for [HuJSON](https://github.com/tailscale/hujson) (Human JSON).

HuJSON is a superset of JSON defined by the [JWCC](https://nigeltao.github.io/blog/2021/json-with-commas-comments.html) (JSON With Commas and Comments) specification. It adds exactly two features to standard JSON:

- **C-style comments** — line comments (`//`) and block comments (`/* */`)
- **Trailing commas** — optional trailing comma after the last element in arrays and objects

All valid JSON is valid HuJSON. HuJSON intentionally rejects all other extensions (unquoted keys, hex literals, etc.).

## Features (v0.1)

- Syntax highlighting via Tree-sitter
- File type association (`.hujson`)
- Bracket matching
- Auto-indentation
- Code outline (object key navigation)

## Installation

*Coming soon* — this extension will be available from the Zed extension registry.

For development, clone this repo and use **Extensions > Install Dev Extension** in Zed, pointing to the repo root.

## Grammar

The Tree-sitter grammar is a fork of [tree-sitter-json](https://github.com/tree-sitter/tree-sitter-json) with a single modification: the `commaSep` helper tolerates an optional trailing comma. The upstream grammar already supports comments.

Forked from tree-sitter-json at [`001c28d`](https://github.com/tree-sitter/tree-sitter-json/commit/001c28d7a29832b06b0e831ec77845553c89b56d).

## Compatibility

- This extension only handles `.hujson` files.
- `.json` and `.jsonc` are left to Zed's built-in grammars.
- The grammar id `hujson` is distinct from `json` / `jsonc`, so installing this extension will not interfere with built-in JSON support.

## Development

### Prerequisites

- Node 18+ and `tree-sitter-cli` (`npm i -g tree-sitter-cli`)
- Rust stable with the WASM target (`rustup target add wasm32-wasip2`)
- Zed Preview channel (for the dev-extension installer)

### Build

```bash
# regenerate the parser and run the corpus suite
(cd grammars/hujson && tree-sitter generate && tree-sitter test)

# build the extension to WASM
cargo build --release --target wasm32-wasip2

# audit Zed query files against the generated grammar
scripts/check-queries.sh
```

### Install in Zed

Open Zed → **Extensions** → **Install Dev Extension** → select the repo root.

### Reload after edits

`Cmd/Ctrl+Shift+P` → `zed: reload extensions`.

### Try it out

A sample document is provided at [`examples/sample.hujson`](examples/sample.hujson) — open it in Zed to verify highlighting, bracket matching, and trailing-comma tolerance.

## Licence

[MIT](LICENSE) — matches the upstream tree-sitter-json licence.
