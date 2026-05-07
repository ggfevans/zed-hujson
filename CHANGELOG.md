# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Grammar extracted to standalone [`ggfevans/tree-sitter-hujson`](https://github.com/ggfevans/tree-sitter-hujson) repository. `extension.toml` now references the grammar by `repository` + `rev` rather than vendoring it under `grammars/hujson/`. This aligns with Zed's grammar-loading conventions and unblocks dev install.
- `scripts/check-queries.sh` now clones the pinned grammar revision into `target/grammar-cache/` to perform the node-name audit, replacing the previous in-tree lookup.
- CI: dropped the `grammar-test` job (lives in `tree-sitter-hujson`'s CI now); kept `extension-build`, `lint`, and a slimmed `query-audit` job.

## [0.1.0] — Unreleased

### Added

- Tree-sitter grammar for HuJSON (forked from tree-sitter-json with trailing comma support)
- Syntax highlighting for strings, numbers, booleans, null, object keys, comments, and punctuation
- File type association for `.hujson` files
- Bracket matching for `{}`, `[]`, and `""`
- Auto-indentation for objects and arrays
- Code outline navigation via object keys
- GitHub Actions CI (grammar tests + WASM extension build + lint)
