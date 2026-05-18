---
created: 2026-05-06
updated: 2026-05-06
---
# Zed HuJSON Extension — v0.2 Specification (Outline)

**Version:** 0.2.0-outline
**Author:** Gareth Evans (ggfevans)
**Date:** 2026-05-06
**Status:** Outline only — full detail deferred until v0.1 highlighting fix lands (see [spec-v0-1.md §14](spec-v0-1.md)).

> This document is a structural skeleton. Section bodies are 1–2 line stubs marking intent; concrete acceptance criteria, code, and decisions land in a follow-up revision once v0.1 ships working highlighting.

---

## 1. Overview

Wire [`hujsonfmt`](https://github.com/tailscale/hujson) into Zed as a thin language-server so HuJSON buffers gain **Format Document**, **Format Selection**, and **format-on-save**. v0.2 adds *no* parsing/highlighting/diagnostics — those stay in the Tree-sitter layer (v0.1) and a future LSP (v0.3+).

Prerequisite: v0.1 highlighting works in dev-mode (spec-v0-1.md §14 acceptance criteria #1–#7 all green).

---

## 2. Architecture

`hujsonfmt` is a Go CLI that reads a HuJSON document on stdin and writes the formatted document to stdout. The Zed extension implements `Extension::language_server_command()` to spawn it as a language server and proxies Zed's formatter requests through standard LSP `textDocument/formatting` and `textDocument/rangeFormatting` messages.

Open question: `hujsonfmt` does not natively speak LSP. The extension either (a) wraps it in a small Zed-side adapter that translates LSP formatting requests to stdin/stdout invocations, or (b) requires a separate LSP-aware wrapper binary. **Approach decision deferred.**

---

## 3. Extension Changes

- `src/lib.rs`: implement `language_server_command(&mut self, _id, worktree)` returning a `Command` that locates the `hujsonfmt` binary (resolution strategy in §4) and configures it for LSP-style framing per the §2 decision.
- `extension.toml`: add `[language_servers.hujsonfmt]` mapping the server to language `HuJSON`.
- `languages/hujson/config.toml`: confirm `language_servers = ["hujsonfmt"]` (or equivalent) and that no Tree-sitter assumption breaks.

---

## 4. `hujsonfmt` Install Strategy

Open question. Tailscale does **not** distribute prebuilt `hujsonfmt` binaries. Candidate strategies:

1. **Require user-managed `$PATH`** — README documents `go install tailscale.com/cmd/hujsonfmt@latest`; extension errors clearly if not found.
2. **Auto-install on first run** — extension shells out to `go install` if `hujsonfmt` not on `$PATH`; requires a Go toolchain on the user's system.
3. **Bundled mirror** — maintain a release-binary mirror in this org and download per-platform.

Trade-offs to be evaluated in the full spec: friction vs. control vs. distribution-licensing concerns.

---

## 5. UX

- **Format Document** (`editor: format`) — full-buffer formatting via LSP.
- **Format Selection** — range formatting if `hujsonfmt` supports it; else fall back to full-document with a notice (or surface an error with actionable guidance if `hujsonfmt` is missing or fails to start).
- **Format-on-save** — opt-in via Zed's `format_on_save` setting, scoped to HuJSON.
- **Error UX** — if `hujsonfmt` rejects the buffer (e.g. invalid HuJSON), surface the error via standard LSP diagnostics; do not silently corrupt the buffer.

---

## 6. README / Install Documentation

- New "Formatter" section: `hujsonfmt` install instructions (per §4 decision), how to enable format-on-save, troubleshooting "binary not found" / "outdated version".
- Cross-link from the existing v0.1 README sections.

---

## 7. Open Questions

1. Does `hujsonfmt` need a separate LSP wrapper, or can the extension act as a minimal adapter? (§2)
2. Install strategy: require `$PATH`, auto-install via `go install`, or bundled binary? (§4)
3. Version pinning: pin a known-good `hujsonfmt` version, or rely on `@latest`? Implication: reproducibility vs. friction.
4. Behaviour when `hujsonfmt` is missing or fails to start: MUST surface a clear, persistent error with actionable guidance (e.g., install/start hujsonfmt or configure a fallback formatter).
5. Range formatting support: does `hujsonfmt` accept partial-document input? If not, what's the fallback for **Format Selection**?
6. Concurrent invocations: is one `hujsonfmt` process per buffer or shared across buffers?
7. Schema / config: any per-project `hujsonfmt` settings to expose (indent width, sort keys, etc.)?

---

## 8. Acceptance Criteria

*Deferred.* To be filled in alongside §2/§4 decisions. Skeleton:

- Format Document on a valid HuJSON buffer produces canonical `hujsonfmt` output with no buffer corruption on malformed input.
- Format Selection works (or its fallback is documented and predictable).
- Format-on-save is opt-in and respects Zed's existing settings.
- Missing `hujsonfmt` binary produces a clear, actionable error — not a silent failure.
- Round-trip: format → save → reopen yields an identical buffer.

---

## 9. Risks

- **No prebuilt binaries upstream** — every install strategy carries non-trivial UX cost.
- **Go toolchain prerequisite** — auto-install path locks out users without Go.
- **`hujsonfmt` does not natively speak LSP** — extra adapter logic required; risk of subtle framing bugs.
- **Tailscale upstream cadence** — `hujsonfmt` could change CLI surface; pin or test against a known version.
- **Buffer corruption on formatter errors** — a formatter that emits empty or partial output on malformed input could destroy user data; the extension must validate the formatter's output before applying it.

---

## 10. Out of Scope (deferred to v0.3+)

- Schema-aware diagnostics / completions.
- Tailscale ACL-specific intelligence.
- `.jwcc` association.
- Standalone formatter binary distribution from this org.
