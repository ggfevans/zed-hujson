# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — Unreleased

### Added

- Tree-sitter grammar for HuJSON (forked from tree-sitter-json with trailing comma support)
- Syntax highlighting for strings, numbers, booleans, null, object keys, comments, and punctuation
- File type association for `.hujson` files
- Bracket matching for `{}`, `[]`, and `""`
- Auto-indentation for objects and arrays
- Code outline navigation via object keys
- GitHub Actions CI (grammar tests + WASM extension build + lint)
