# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-14

### Changed

- Updated the pinned `tree-sitter-hujson` grammar to the v1.1.0 release (`54fb9ef`). The grammar was tightened to RFC 8259 strictness (a document has exactly one root value; numbers and strings follow stricter rules), so invalid JSON now surfaces `ERROR` nodes. Valid JSON and the public node types are unchanged, so syntax highlighting and queries behave identically. (#34)

## [1.0.2] - 2026-06-11

### Removed

- Rust/WASM extension boilerplate (no-op crate and `[lib]` manifest section) — pure grammar extensions don't need one; requested in zed-industries/extensions PR review (PR #32)

### Technical

- Dropped Rust CI jobs, cargo dependabot config, and Rust build documentation (PR #32)

## [1.0.1] - 2026-06-03

### Changed

- Updated the pinned `tree-sitter-hujson` grammar to the v1.0.1 release (`506ab94`). Node types are unchanged, so syntax highlighting and queries behave identically; this realigns the extension with the latest grammar release. (#24)

### Added

- README status badges (CI, latest release, grammar version, license, security scan, Zed extension). (#27)
- Documentation that Markdown ` ```hujson ` fenced code blocks highlight automatically via language-name matching, with an `examples/markdown-fence.md` demo. (#23)

### Fixed

- `scripts/check-queries.sh` now audits `languages/hujson/*.scm` (where the Zed query files actually live) instead of the non-existent `queries/hujson/`, so the `query-audit` CI gate validates query node names against the pinned grammar instead of silently no-opping. (#25)

## [1.0.0] - 2026-06-01

### Added

- `.jwcc` file extension association for HuJSON highlighting (#13)
- hujsonfmt formatter configuration documentation (#11, PR #17)
- SECURITY.md with private vulnerability reporting policy (#9, PR #10)
- GitHub Actions release workflow with changelog validation (#9, PR #10)
- Weekly Trivy security scanning (fs + config + secret) with SARIF upload (#6, PR #7)

### Changed

- Grammar extracted to standalone `ggfevans/tree-sitter-hujson` repository; `extension.toml` now references grammar by repository + commit
- `scripts/check-queries.sh` clones pinned grammar revision into `target/grammar-cache/` for node-name audit
- CI: dropped `grammar-test` job (moved to `tree-sitter-hujson` CI); kept `extension-build`, `lint`, and `query-audit`
- README updated for v1.0 (#5, PR #5)
- Syntax highlighting uses `@property` for accurate object-key colouring (#4, PR #4)

### Fixed

- Query files added to `languages/hujson/`, orphans removed, spec corrected (#2, PR #2)
- Block comment array syntax fixed (#3, PR #3)
- CodeRabbit review feedback applied across multiple PRs

### Security

- All GitHub Actions pinned to immutable SHA references instead of mutable version tags (#16, PR #18)
- Trivy action dependency bumped from 0.28.0 to 0.35.0 (#8)

## [0.1.0] - 2026-05-06

### Added

- Tree-sitter grammar for HuJSON (forked from tree-sitter-json with trailing comma support)
- Syntax highlighting for strings, numbers, booleans, null, object keys, comments, and punctuation
- File type association for `.hujson` files
- Bracket matching for `{}`, `[]`, and `""`
- Auto-indentation for objects and arrays
- Code outline navigation via object keys
- GitHub Actions CI (grammar tests + WASM extension build + lint)
