# TODO — spec-v0-1.md Remaining Items

Tracks work outstanding from [`docs/plan/spec-v0-1.md`](docs/plan/spec-v0-1.md). Section refs (§N) point into that spec. Ordered by dependency: P0 unblocks dev install; P1 closes pre-existing decisions; P2 is publish/release prep.

---

## P0 — Highlighting Fix (spec §14)

Blocks the v0.1 promise (working highlighting in dev-mode). Cross-repo: items marked **[grammar]** belong in [`ggfevans/tree-sitter-hujson`](https://github.com/ggfevans/tree-sitter-hujson).

### Diagnose first (§14.3)

- [ ] Clone pinned grammar at `69e5e147274d91608f146c7ecc6d0821a390d951` (tag `v0.1.0`); run the artefact inventory loop. A passing run prints `OK $f` for each of the 10 expected artefacts (grammar.js, tree-sitter.json, package.json, src/parser.c, src/node-types.json, src/grammar.json, queries/highlights.scm, queries/brackets.scm, queries/indents.scm, queries/outline.scm). Any `MISSING $f` line is a failure.
- [ ] `tree-sitter parse examples/sample.hujson` against pinned grammar — record output.
- [ ] `tree-sitter query queries/highlights.scm examples/sample.hujson` against pinned grammar — record any "unknown node type" errors.
- [ ] Capture Zed log on extension reload; grep for `hujson|grammar|tree-sitter|wasm`.
- [ ] Assign root cause to H1 (parser unbuildable), H2 (query/node mismatch), or both. Note in the implementation PR.

### Grammar repo work (§14.6) **[grammar]**

- [ ] `src/parser.c`, `src/grammar.json`, `src/node-types.json`, `src/tree_sitter/*` committed and current at HEAD.
- [ ] `tree-sitter generate` produces no diff against committed files.
- [ ] `tree-sitter.json` correct: `name=hujson`, `scope=source.hujson`, `file-types=["hujson"]`, `injection-regex=hujson`, `highlights` path resolves.
- [ ] All node names captured in `queries/{highlights,brackets,indents,outline}.scm` exist in `src/node-types.json`.
- [ ] Capture names match Zed conventions (`@string`, `@number`, `@constant.builtin`, `@property.json_key`, `@comment`, `@punctuation.bracket`, `@punctuation.delimiter`, `@string.escape`).
- [ ] `tree-sitter query` runs cleanly against each `queries/*.scm`.
- [ ] Representative sample parses with zero `ERROR` nodes.
- [ ] CI gate: `tree-sitter generate` (no-op), `tree-sitter test` (corpus), `tree-sitter query` per `.scm`.
- [ ] Tag release commit once green; capture the SHA for the pin bump.

### Extension repo work (§14.5)

- [ ] `git rm -r grammars/hujson/` (orphan from pre-`cf8d0d1`).
- [ ] `git rm -r queries/hujson/` (includes the malformed `indents.scm`).
- [x] Bump `extension.toml` `[grammars.hujson] commit = …` to the audited SHA from the grammar tag. — Pinned to `69e5e14` (v0.1.0); §14.3 programmatic checks pass.
- [ ] Re-run §14.3 diagnostic recipe against the new SHA — all checks must pass.
- [ ] README — add "Grammar source" section pointing at `tree-sitter-hujson` for grammar/query edits.
- [ ] README — add "Bumping the grammar pin" subsection mirroring the procedure in §14.5.
- [ ] CI — verify `query-audit` job *fails* the build on grammar/query mismatch (not just warns); `scripts/check-queries.sh` is the source of truth.
- [ ] Decide `extension.wasm` policy: keep committed + document rebuild, or `.gitignore` it + build in CI. Update README accordingly.

### Acceptance + verification (§14.4, §14.7)

- [ ] In dev-mode Zed, `examples/sample.hujson` colours: strings, numbers, booleans, null, escape sequences, object keys, line comments, block comments, brackets, punctuation. Each capture fires.
- [ ] `tree-sitter parse examples/sample.hujson` against pinned SHA → zero `ERROR` nodes.
- [ ] `scripts/check-queries.sh` exits 0 locally and in CI.
- [ ] Zed log shows no warnings/errors on extension load.
- [ ] (Optional) before/after highlighting screenshots attached to the closing PR.

---

## P1 — Pre-existing Open Decisions

Items spec-v0-1.md flagged for resolution at implementation time but not yet recorded as resolved.

- [ ] Document resolved Decision 2: record `zed_extension_api = "0.7.0"` from `Cargo.toml` into §4.4 of the spec. Decision 2 is resolved — this task is a documentation update, not a new decision.
- [ ] §4.3 Decision 3 — verify `Extension` trait shape against docs.rs for the pinned `zed_extension_api`; ensure no-op stubs exist for any required methods beyond `new()`.
- [ ] §7.3 Decision 5 step 2 — README "Compatibility" section explicitly stating this extension only handles `.hujson`; `.json`/`.jsonc` left to Zed built-ins; grammar id `hujson` distinct from `json`/`jsonc`.
- [ ] §9.1 — refresh CI description in the spec: post-extraction the `grammar-test` job moved to the grammar repo; this repo runs `extension-build`, `lint`, `query-audit`. (CHANGELOG already records this; spec §9.1 is stale.)

---

## P2 — Publish & Release (spec §10, §9.2)

Sequenced after P0/P1. Out of scope for the highlighting fix itself.

- [ ] §7.3 Decision 5 step 3 — registry pre-publish search: grep `zed-industries/extensions` for `hujson` (id collision), `\.hujson\b`, `path_suffixes.*hujson`. Resolve any prior claim before submitting.
- [ ] §8.3 — capture visual-regression reference screenshots for key test files (manual eyeball baseline).
- [ ] §8.4 — comparison baseline check vs. forced JSONC mode (comments identical; trailing commas not errors in HuJSON; everything else matches).
- [ ] §9.2 — set up tag-based release workflow (build, package as `.tar.gz`, GitHub Release).
- [ ] §10.1 — fork `zed-industries/extensions`, add submodule via HTTPS, run `pnpm sort-extensions`, ensure `LICENSE` present, open PR.
- [ ] Front-matter — flip spec-v0-1.md `Status: Ready for implementation` → `Status: Released` once shipped; bump `Version` to `0.1.0`.
- [ ] CHANGELOG — promote `[Unreleased]` to `[0.1.0] — YYYY-MM-DD`.

---

## Notes

- This file tracks **only spec-v0-1.md** remaining items. v0.2 work is tracked separately in `docs/plan/spec-v0-2.md` (currently outline-only).
- `docs/plan/todo.md` was the original 18-phase implementation checklist; it has been consolidated into this file. The detailed per-prompt gates and pre-flight checks are captured by the spec sections they reference. When an item lands, check it off here AND, if it resolves an open question in the spec, update the corresponding §13 Decision Log entry inline.