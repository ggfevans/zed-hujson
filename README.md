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

## Licence

[MIT](LICENSE) — matches the upstream tree-sitter-json licence.
