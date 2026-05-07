---
created: 2026-04-09
updated: 2026-05-05T01:56
---
# Zed HuJSON — Implementation TODO

A thorough, checkbox-driven implementation checklist derived from [[spec.md]] and [[prompt-plan.md]]. Tick items off as you go. Items are grouped by phase; each group ends with a verification gate so you don't move on with a broken tree.

Repo: `ggfevans/zed-hujson` — local path `/Users/gvns/code/projects/zed-hujson`.

---

## 0. Pre-flight

- [ ] Confirm Node.js ≥ 18 installed (`node -v`)
- [ ] Install `tree-sitter-cli` globally (`npm i -g tree-sitter-cli`)
- [ ] Confirm `tree-sitter --version` works
- [ ] Install Rust stable toolchain (`rustup install stable`)
- [ ] Add WASM target (`rustup target add wasm32-wasip2`)
- [ ] Install Zed Preview channel
- [ ] Run `tree-sitter init-config` once (creates `~/.config/tree-sitter/config.json`)
- [ ] Verify the GitHub repo `ggfevans/zed-hujson` exists (or create it, MIT licence, no template)
- [ ] Verify the extension id `hujson` is not already registered in `zed-industries/extensions`

---

## 1. Repo bootstrap (Prompt 1)

### Files
- [ ] `LICENSE` — MIT, "Gareth Evans", current year
- [ ] `README.md` with:
  - [ ] Project description (Zed extension for HuJSON / JWCC)
  - [ ] Features list (highlighting, `.hujson` association, brackets, indent, outline)
  - [ ] Installation placeholder (registry "coming soon" + dev-install instructions)
  - [ ] Grammar section (forked from tree-sitter-json, single trailing-comma change)
  - [ ] Links to Tailscale HuJSON repo and JWCC blog post
- [ ] `.gitignore` containing `node_modules/`, `target/`, `build/`, `*.wasm`
- [ ] `.gitattributes` marking `grammars/hujson/src/parser.c` and `grammars/hujson/src/tree_sitter/*` as `linguist-generated=true`

### Directory skeleton
- [ ] `grammars/hujson/` exists
- [ ] `languages/hujson/` exists
- [ ] `queries/hujson/` exists
- [ ] `src/` exists
- [ ] `.github/workflows/` exists

### Gate
- [ ] `git status` shows only the bootstrap files
- [ ] `LICENSE` and `README.md` present at repo root

---

## 2. Vendor the upstream grammar (Prompt 2)

- [ ] Pin upstream commit SHA: `001c28d7a29832b06b0e831ec77845553c89b56d`
- [ ] Copy all upstream files (except `.git/`) into `grammars/hujson/`
- [ ] Record the SHA in the README "Grammar" section
- [ ] Update `grammars/hujson/grammar.js`:
  - [ ] `name: 'hujson'`
  - [ ] Update top JSDoc to credit upstream + note the fork SHA
- [ ] Update `grammars/hujson/package.json`:
  - [ ] `name: tree-sitter-hujson`
  - [ ] `description` mentions HuJSON / JWCC
  - [ ] `repository.url` → `https://github.com/ggfevans/zed-hujson.git`
  - [ ] `repository.directory` → `grammars/hujson`
- [ ] Run `cd grammars/hujson && tree-sitter generate`
- [ ] Commit regenerated `src/parser.c`, `src/grammar.json`, `src/node-types.json`, `src/tree_sitter/*.h`

### Gate
- [ ] `cd grammars/hujson && tree-sitter test` exits 0 (zero corpus, no errors)
- [ ] `echo '{"a":1}' | tree-sitter parse /dev/stdin` produces a tree with no `ERROR`

---

## 3. Grammar metadata (Prompt 3)

- [ ] `grammars/hujson/tree-sitter.json` written per spec §3.2:
  - [ ] `grammars[0].name = "hujson"`
  - [ ] `scope = "source.hujson"`
  - [ ] `file-types = ["hujson"]`
  - [ ] `injection-regex = "hujson"`
  - [ ] `highlights = "queries/highlights.scm"`
  - [ ] `metadata` block (version, license, description, authors, links)
- [ ] `grammars/hujson/queries/highlights.scm` placeholder created (copied from spec §5.1)

### Gate
- [ ] `cd grammars/hujson && tree-sitter generate && tree-sitter test` clean
- [ ] `tree-sitter parse` of a sample `.hujson` succeeds without warnings

---

## 4. JWCC trailing-comma mutation (Prompt 4)

- [ ] Replace `commaSep1` in `grammar.js` with:
      `seq(rule, repeat(seq(',', rule)), optional(','))`
- [ ] Replace `commaSep` with `optional(commaSep1(rule))`
- [ ] No other rule changes (strictness preserved)
- [ ] Regenerate parser (`tree-sitter generate`)

### Gate (smoke)
- [ ] `echo '{"a": 1,}' | tree-sitter parse /dev/stdin` → no `ERROR`
- [ ] `echo '[1, 2, 3,]' | tree-sitter parse /dev/stdin` → no `ERROR`
- [ ] `echo '{"a": 1}' | tree-sitter parse /dev/stdin` (no trailing comma) → still no `ERROR`
- [ ] `echo '{"a": 1,, "b": 2}' | tree-sitter parse /dev/stdin` → contains `ERROR`

---

## 5. Corpus tests — literals / objects / arrays (Prompt 5)

### `test/corpus/literals.txt`
- [ ] Plain string
- [ ] Escaped string with `\"`
- [ ] Escaped string with `\\`
- [ ] Escaped string with `\n`
- [ ] Escaped string with `\uXXXX`
- [ ] Integer literal
- [ ] Negative integer
- [ ] Float
- [ ] Float with exponent (e/E, +/-)
- [ ] `true`
- [ ] `false`
- [ ] `null`

### `test/corpus/objects.txt`
- [ ] Empty object `{}`
- [ ] Single pair
- [ ] Multiple pairs
- [ ] Nested objects
- [ ] Object containing every value type

### `test/corpus/arrays.txt`
- [ ] Empty array `[]`
- [ ] Single element
- [ ] Multiple elements
- [ ] Nested arrays
- [ ] Mixed value types

### Gate
- [ ] `tree-sitter test` green

---

## 6. Corpus tests — comments (Prompt 6)

`test/corpus/comments.txt`:
- [ ] Line comment at end of line after a value
- [ ] Standalone line comment
- [ ] Inline block comment
- [ ] Multi-line block comment
- [ ] Comment between object pairs
- [ ] Comment between array elements
- [ ] Comment before root value
- [ ] Comment after root value
- [ ] Empty block comment `/* */`
- [ ] Pseudo-nested block comment (`/* outer /* inner */ trailing */`) → trailing portion is ERROR

### Gate
- [ ] `tree-sitter test` green

---

## 7. Corpus tests — trailing commas (Prompt 7)

`test/corpus/trailing_commas.txt` (positives — no ERROR):
- [ ] `{"a": 1,}`
- [ ] `[1, 2, 3,]`
- [ ] `{"a": {"b": 1,},}`
- [ ] `[[1,], [2,],]`
- [ ] Trailing comma followed by line comment on same line
- [ ] Block comment between last element and trailing comma (multi-line)

Negatives (must produce ERROR):
- [ ] `{"a": 1,, "b": 2}`
- [ ] `{,"a": 1}`
- [ ] `{,}`
- [ ] `[,]`

### Gate
- [ ] `tree-sitter test` green

---

## 8. Corpus tests — degenerate + invalid (Prompt 8)

`test/corpus/degenerate.txt`:
- [ ] Empty input
- [ ] Whitespace only
- [ ] Comment-only file (line comment)
- [ ] Comment-only file (block comment)
- [ ] BOM at start of file (`\uFEFF`) — encode expected behaviour
- [ ] Bare root string
- [ ] Bare root number
- [ ] Bare root `null`
- [ ] Unicode in comments (CJK + emoji)
- [ ] Unicode in string values
- [ ] Deeply nested object (≥ 50 levels)

`test/corpus/invalid.txt` (all must produce ERROR):
- [ ] `{key: "value"}` (unquoted key)
- [ ] `{'k': 'v'}` (single quotes)
- [ ] `{"a": 0xFF}` (hex literal)
- [ ] `{"a": Infinity}`
- [ ] `{"a": NaN}`
- [ ] `{"a": hello}` (unquoted value)

### Gate
- [ ] `tree-sitter test` green across all 7 corpus files

---

## 9. Rust extension crate → WASM (Prompt 9)

- [ ] `Cargo.toml` at repo root with `[package]`, `[lib] crate-type=["cdylib"]`, `zed_extension_api = "0.7.0"`, `[profile.release]` opt-level `"s"`, `lto = true`
- [ ] `src/lib.rs` with `HujsonExtension` struct + `impl zed::Extension` + `register_extension!`
- [ ] Verify against `docs.rs/zed_extension_api/0.7.0` whether additional trait methods are required; add no-op impls if so
- [ ] `Cargo.lock` committed

### Gate
- [ ] `cargo build --release --target wasm32-wasip2` succeeds
- [ ] `target/wasm32-wasip2/release/zed_hujson.wasm` exists
- [ ] `cargo clippy --target wasm32-wasip2 -- -D warnings` clean
- [ ] `cargo fmt -- --check` clean

---

## 10. Extension manifest (Prompt 10)

`extension.toml`:
- [ ] `id = "hujson"`
- [ ] `name = "HuJSON"`
- [ ] `version = "0.1.0"`
- [ ] `schema_version = 1`
- [ ] `authors = ["Gareth Evans <…>"]`
- [ ] `description` set
- [ ] `repository = "https://github.com/ggfevans/zed-hujson"`
- [ ] `[grammars.hujson]` with `repository` + `path = "grammars/hujson"`
- [ ] TOML parses cleanly (`python -c 'import tomllib; tomllib.load(open("extension.toml","rb"))'`)

---

## 11. Language config (Prompt 11)

`languages/hujson/config.toml`:
- [ ] `name = "HuJSON"`
- [ ] `grammar = "hujson"`
- [ ] `path_suffixes = ["hujson"]`
- [ ] `line_comments = ["//"]`
- [ ] `block_comment = ["/*", "*/"]`
- [ ] `tab_size = 2`
- [ ] `hard_tabs = false`
- [ ] `autoclose_before = ",]}"`
- [ ] `brackets` array (3 entries: `{}`, `[]`, `""` with `not_in = ["string"]`)
- [ ] `word_characters = ["-"]`
- [ ] TOML parses cleanly

---

## 12. Highlights query (Prompt 12)

`queries/hujson/highlights.scm`:
- [ ] `(string) @string`
- [ ] `(escape_sequence) @string.escape`
- [ ] `(number) @number`
- [ ] `(true) (false) (null)` → `@constant.builtin`
- [ ] `(pair key: (string) @property.json_key)`
- [ ] Bracket punctuation captures (`{ } [ ]`)
- [ ] Delimiter captures (`:` `,`)
- [ ] `(comment) @comment`

### Gate
- [ ] `tree-sitter query queries/hujson/highlights.scm` (run from `grammars/hujson/`) reports no errors
- [ ] All node names referenced exist in `grammars/hujson/src/node-types.json`

---

## 13. Brackets / Indents / Outline queries (Prompt 13)

- [ ] `queries/hujson/brackets.scm` — `{}`, `[]`, `""`
- [ ] `queries/hujson/indents.scm` — `(object) (array) @indent`, `}`/`]` `@outdent`
- [ ] `queries/hujson/outline.scm` — `(pair key: (string) @name) @item`

### Gate
- [ ] All three query files compile against the generated grammar

---

## 14. CI workflow (Prompt 14)

`.github/workflows/ci.yml`:
- [ ] Triggers: push to `main`, PRs targeting `main`
- [ ] `permissions: contents: read` at workflow scope
- [ ] Job `grammar-test`:
  - [ ] `actions/checkout@v4`
  - [ ] `actions/setup-node@v4` (node 22)
  - [ ] `npm i -g tree-sitter-cli`
  - [ ] `tree-sitter generate` in `grammars/hujson`
  - [ ] `tree-sitter test` in `grammars/hujson`
- [ ] Job `extension-build`:
  - [ ] `dtolnay/rust-toolchain@stable` with `wasm32-wasip2`
  - [ ] `cargo build --release --target wasm32-wasip2`
  - [ ] `test -f target/wasm32-wasip2/release/zed_hujson.wasm`
- [ ] Job `lint`:
  - [ ] `dtolnay/rust-toolchain@stable` with `clippy`, `rustfmt`, `wasm32-wasip2`
  - [ ] `cargo clippy --target wasm32-wasip2 -- -D warnings`
  - [ ] `cargo fmt -- --check`

### Gate
- [ ] Push a branch and open a draft PR
- [ ] All three jobs go green

---

## 15. Local Zed verification (Prompt 15)

- [ ] Add a "Development" section to `README.md` (prerequisites, build, dev install, reload)
- [ ] Create `examples/sample.hujson` with a Tailscale-ACL-style snippet using comments + trailing commas + nesting
- [ ] Reference `examples/sample.hujson` from the README

### Manual smoke (in Zed)
- [ ] Extensions panel → "Install Dev Extension" → select repo root
- [ ] Open `examples/sample.hujson` → file is detected as `HuJSON` (status bar bottom right)
- [ ] Strings, numbers, booleans, null, keys, comments all highlight as expected
- [ ] Trailing commas do NOT show as errors
- [ ] Bracket matching works on `{}` and `[]`
- [ ] Auto-indent on Enter inside `{}` / `[]` works
- [ ] Outline panel lists object keys
- [ ] Double-click on a hyphenated key (e.g. `acl-rule-name`) selects the whole key
- [ ] `Cmd/Ctrl+Shift+P → "zed: reload extensions"` works without restarting Zed

### Comparison check
- [ ] Force-switch the buffer to "JSON with Comments" via the status bar — trailing commas are flagged as errors there but not in HuJSON mode
- [ ] Comments highlight identically in both modes

### Negative checks
- [ ] Opening a `.json` file still uses Zed's built-in JSON grammar (not HuJSON)
- [ ] Zed log shows no warnings about duplicate grammar registration

---

## 16. CHANGELOG + release polish (Prompt 16)

- [ ] `CHANGELOG.md` (Keep-a-Changelog format) with `Unreleased` and `0.1.0` sections
  - [ ] Tree-sitter HuJSON grammar (mention upstream SHA + JWCC mutation)
  - [ ] Zed language config for `.hujson`
  - [ ] Highlights / brackets / indents / outline queries
  - [ ] CI: grammar tests, WASM build, clippy + rustfmt
- [ ] Final repo audit:
  - [ ] `extension.toml` id `hujson` still free in registry
  - [ ] `LICENSE` present at repo root
  - [ ] `tree-sitter test` clean
  - [ ] `cargo build --release --target wasm32-wasip2` clean
  - [ ] `cargo clippy --target wasm32-wasip2 -- -D warnings` clean
  - [ ] `cargo fmt -- --check` clean
  - [ ] All four `.scm` files compile

---

## 17. Publishing to the Zed registry

- [ ] Tag the release commit `v0.1.0` in `ggfevans/zed-hujson`
- [ ] Fork `zed-industries/extensions`
- [ ] In the fork, add submodule via **HTTPS** (not SSH):
      `git submodule add https://github.com/ggfevans/zed-hujson.git extensions/hujson`
- [ ] Pin submodule to the `v0.1.0` tag
- [ ] Run `pnpm sort-extensions` in the registry fork
- [ ] Confirm `LICENSE` is present in the submodule (registry CI requires it)
- [ ] Open PR against `zed-industries/extensions`
- [ ] Address any review feedback

---

## 18. Post-publish housekeeping

- [ ] Add a "Published" badge / link to the registry in `README.md`
- [ ] Capture reference screenshots of highlighting (visual regression baseline)
- [ ] Add a quarterly reminder to check upstream `tree-sitter-json` for syncs (spec §11.3)
- [ ] File a tracking issue for v0.2 (`hujsonfmt` formatter integration)
- [ ] File a tracking issue for v0.3 (LSP, optional)
- [ ] File a tracking issue for grammar extraction into a standalone repo (spec §11.4) — gate on external editor demand

---

## Resolved decisions (from open-question review)

1. **Grammar location** → grammar lives under **`grammars/hujson/`** (revised 2026-05-06). `extension.toml`'s `[grammars.hujson]` uses `path = "grammars/hujson"`. The earlier "move to repo root" plan was abandoned — the grammar was already vendored under `grammars/hujson/` with the JWCC mutation, regenerated parser, and corpus suite, and Zed's loader resolves the explicit `path` cleanly. The Cargo crate's `src/lib.rs` lives at the repo-root `src/`, distinct from the grammar's own `grammars/hujson/src/parser.c`.
2. **`zed_extension_api` version** → use the **latest stable** at implementation time (check `https://crates.io/crates/zed_extension_api` when working through Prompt 9). Update the spec/plan to match the actual version pinned.
3. **`Extension` trait** → if the trait requires more than `new()`, add **minimal no-op stubs** for every required method (return the most conservative `Ok(None)` / `Err("not supported")` / equivalent). v0.1 remains strictly highlighting-only.
4. **Node-name verification** → **belt-and-braces**: audit `src/node-types.json` after each regenerate AND keep `tree-sitter query <file>.scm` as a verification gate (locally and in CI).
5. **File-extension conflict** → manual smoke test in Zed (`.json` vs `.hujson`) **plus** a compatibility note in the README **plus** an explicit search of `zed-industries/extensions` for any prior claim on `.hujson` or id `hujson` before opening the registry PR.

---

## Decision-driven follow-up tasks

### From decision 1 (grammar under `grammars/hujson/`) — done
- [x] Grammar files placed under `grammars/hujson/` (`grammar.js`, `package.json`, `tree-sitter.json`, `binding.gyp`, `bindings/`, `src/`, `test/`, `queries/`)
- [x] `.gitattributes` marks `grammars/hujson/src/parser.c` and `grammars/hujson/src/tree_sitter/*` as `linguist-generated=true`
- [x] `extension.toml` `[grammars.hujson]` uses `path = "grammars/hujson"`
- [x] CI `working-directory:` is `grammars/hujson` for `tree-sitter generate` and `tree-sitter test`
- [x] README "Grammar" / "Development" sections reflect the `grammars/hujson/` layout
- [x] Naming clash resolved: Zed queries at repo-root `queries/hujson/`, grammar's own queries at `grammars/hujson/queries/` (consumed by Neovim/Helix)

### From decision 2 (latest `zed_extension_api`)
- [ ] Before writing `Cargo.toml`, run a quick check on `https://crates.io/crates/zed_extension_api` for the latest stable version
- [ ] Pin to that version exactly in `Cargo.toml`
- [ ] Update `spec.md` §4.4 with the actual version used
- [ ] If the version differs from `0.7.0`, re-verify the `Extension` trait shape on docs.rs for that version

### From decision 3 (no-op trait stubs)
- [ ] After first build attempt of `src/lib.rs`, capture every "missing trait method" compiler error
- [ ] For each, add a minimal stub that returns the most conservative "unsupported" value
- [ ] Add a `// v0.1: highlighting-only — no language server / formatter / completions` comment block at the top of the impl
- [ ] Re-run `cargo clippy --target wasm32-wasip2 -- -D warnings` and ensure no `unused_variables` warnings on stub args (use `_` prefix)

### From decision 4 (node-name verification, belt-and-braces)
- [ ] After every `tree-sitter generate`, grep `src/node-types.json` for each node name referenced in `queries/hujson/*.scm`
- [ ] Add a CI step that runs `tree-sitter query queries/hujson/highlights.scm`, `brackets.scm`, `indents.scm`, `outline.scm` against the generated grammar — fail the build on any unknown node
- [ ] Add a local Makefile target or shell script (`scripts/check-queries.sh`) that runs the same loop, for fast iteration during development
- [ ] Document the audit step in the README's "Development" section

### From decision 5 (extension conflict — defence in depth)
- [ ] Manual smoke (already in §15): open `.json` and `.hujson` files in Zed; confirm correct grammar binds and no log warnings
- [ ] Add a "Compatibility" section to the README explicitly stating:
  - This extension **only** handles `.hujson` files
  - `.json` and `.jsonc` are left to Zed's built-in grammars
  - The grammar id `hujson` is distinct from `json` / `jsonc`
- [ ] Before opening the registry PR, run a search in `zed-industries/extensions`:
  - [ ] grep the registry repo for `hujson` (id collision)
  - [ ] grep the registry repo for `\.hujson\b` and `path_suffixes.*hujson` (extension claim)
  - [ ] If any prior claim exists, decide on rename / coordination before submitting
