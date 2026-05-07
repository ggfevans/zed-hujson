# HuJSON for Zed

A [Zed](https://zed.dev) extension providing syntax highlighting and editor support for [HuJSON](https://github.com/tailscale/hujson) (Human JSON).

HuJSON is a superset of JSON defined by the [JWCC](https://nigeltao.github.io/blog/2021/json-with-commas-comments.html) (JSON With Commas and Comments) specification. From the JWCC docs:

> The JWCC format permits two things over standard JSON:
>
> 1. C-style line comments and block comments intermixed with whitespace.
> 2. Trailing commas after the last member/element in an object/array.
>
> All JSON is valid JWCC.

HuJSON intentionally rejects all other extensions (unquoted keys, hex literals, `Infinity`/`NaN`, single-quoted strings, etc.) — strictness is preserved beyond those two additions.

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

The Tree-sitter grammar lives in its own repo at [`ggfevans/tree-sitter-hujson`](https://github.com/ggfevans/tree-sitter-hujson). It is a fork of [tree-sitter-json](https://github.com/tree-sitter/tree-sitter-json) (forked at [`001c28d`](https://github.com/tree-sitter/tree-sitter-json/commit/001c28d7a29832b06b0e831ec77845553c89b56d)) with a single semantic change: the `commaSep` helper tolerates an optional trailing comma. The upstream grammar already supports comments.

This extension references the grammar by URL + rev in `extension.toml`. To bump the pinned grammar revision, edit `[grammars.hujson] rev = "…"` and re-run `scripts/check-queries.sh`.

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
# build the extension to WASM
cargo build --release --target wasm32-wasip2

# audit Zed query files against the pinned grammar revision
# (clones tree-sitter-hujson at the rev in extension.toml on first run;
#  cached under target/grammar-cache/<rev>/)
scripts/check-queries.sh
```

To work on the grammar itself, see [`ggfevans/tree-sitter-hujson`](https://github.com/ggfevans/tree-sitter-hujson). After a grammar change, push a new commit there and bump `[grammars.hujson] rev` in this repo's `extension.toml`.

### Install in Zed

Open Zed → **Extensions** → **Install Dev Extension** → select the repo root.

### Reload after edits

`Cmd/Ctrl+Shift+P` → `zed: reload extensions`.

### Try it out

A sample document is provided at [`examples/sample.hujson`](examples/sample.hujson) — open it in Zed to verify highlighting, bracket matching, and trailing-comma tolerance.

## Licence

[MIT](LICENSE) — matches the upstream tree-sitter-json licence.
