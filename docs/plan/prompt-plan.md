---
created: 2026-04-09
updated: 2026-05-05T02:01
---
# Zed HuJSON Extension — Implementation Prompt Plan

A step-by-step, LLM-driven implementation plan derived from [[spec.md]]. Each step is small, builds on the previous, and ends fully wired (no orphaned code). Target repo: `ggfevans/zed-hujson` at `/Users/gvns/code/projects/zed-hujson`.

## Resolved decisions baked into this plan

Five previously-open questions are now locked. Every prompt below assumes them:

1. **Grammar lives under `grammars/hujson/`** (revised 2026-05-06; supersedes the earlier "repo root" plan). `grammar.js`, `package.json`, `tree-sitter.json`, `binding.gyp`, `test/corpus/`, and the generated `src/parser.c` + `src/grammar.json` + `src/node-types.json` + `src/tree_sitter/*` all live under `grammars/hujson/`. `extension.toml`'s `[grammars.hujson]` sets `path = "grammars/hujson"`. The grammar's own standalone queries (Neovim/Helix consumers) stay under `grammars/hujson/queries/`; Zed's queries are at the repo-root `queries/hujson/`. The Cargo crate's `src/lib.rs` lives at the repo-root `src/`, separate from the grammar's `grammars/hujson/src/`.

> **Reading the prompts below**: the original prompt text says "repo root" for grammar files. Everywhere a prompt says to put grammar files at the repo root, read it as `grammars/hujson/`. CI `working-directory:` is `grammars/hujson` for `tree-sitter generate` / `tree-sitter test`. Verification commands like `tree-sitter parse` should be run from `grammars/hujson/`, not the repo root.
2. **`zed_extension_api`** — pin to the **latest stable** version at implementation time (check `https://crates.io/crates/zed_extension_api` when working through Prompt 9), not a value baked into this plan.
3. **`Extension` trait** — if the trait requires more than `new()`, add minimal **no-op stubs** that return the most conservative unsupported value (`Ok(None)` / `Err("not supported")`). Use `_`-prefixed parameter names for clippy cleanliness. v0.1 stays strictly highlighting-only.
4. **Node-name verification (belt-and-braces)** — after every `tree-sitter generate`, audit `src/node-types.json` AND run `tree-sitter query` per `.scm` file. Both checks run locally via `scripts/check-queries.sh` and in CI.
5. **File-extension conflict (defence in depth)** — manual Zed smoke + README "Compatibility" section + registry pre-publish search.

---

## Phase 0 — Blueprint (high level)

1. **Repo scaffolding** — license, README, `.gitignore`, `.gitattributes`, directory skeleton (grammar files at repo root, decision 1).
2. **Grammar foundation** — fork `tree-sitter-json` at the repo root, pin the source SHA, regenerate parser as-is.
3. **Grammar mutation** — replace `commaSep`/`commaSep1` to allow a trailing comma. Regenerate.
4. **Grammar tests** — corpus suites covering literals, objects, arrays, comments, trailing commas, degenerate cases, invalid (strictness) cases.
5. **Zed extension shell** — `extension.toml`, `Cargo.toml`, minimal `src/lib.rs`, build to `wasm32-wasip2`.
6. **Language config** — `languages/hujson/config.toml` (path suffixes, brackets, comments, indent, word chars).
7. **Syntax queries** — `queries/hujson/{highlights,brackets,indents,outline}.scm`.
8. **CI** — GitHub Actions: grammar generate+test, extension build, lint.
9. **Manual integration** — load as Dev Extension in Zed, verify on real `.hujson` files.
10. **Polish** — CHANGELOG, registry-readiness checks, decision log notes.

---

## Phase 1 — Iterative chunk breakdown (medium grain)

- **C1. Bootstrap repo**: license + README + git ignore/attributes + directory skeleton.
- **C2. Vendor grammar**: copy upstream `tree-sitter-json` to repo root (decision 1), update package metadata, regenerate.
- **C3. JWCC trailing-comma change**: modify `grammar.js` helpers, regenerate, smoke-test.
- **C4. Corpus tests**: add 7 corpus files; everything green under `tree-sitter test`.
- **C5. Cargo + WASM extension entry**: `Cargo.toml`, `src/lib.rs`, `cargo build --release --target wasm32-wasip2` succeeds.
- **C6. Zed manifest + language config**: `extension.toml`, `languages/hujson/config.toml`.
- **C7. Zed query files**: `highlights.scm`, `brackets.scm`, `indents.scm`, `outline.scm`.
- **C8. CI workflow**: grammar test job, extension build job, lint job.
- **C9. Local validation**: install dev extension, eyeball highlighting on sample HuJSON.
- **C10. Release prep**: CHANGELOG, repo metadata polish.

---

## Phase 2 — Right-sized step decomposition

Each step below = one LLM prompt. Steps are small enough to verify in isolation, large enough to make progress, and each step ends with the project still building/testing cleanly.

| # | Step | Dependencies | Verification |
|---|---|---|---|
| 1 | Repo bootstrap files | — | `git status` clean, `LICENSE` & `README.md` exist |
| 2 | Vendor `tree-sitter-json` to repo root, rename to `hujson`, regenerate | 1 | `tree-sitter test` passes (zero corpus) |
| 3 | Add `tree-sitter.json` + `scripts/check-queries.sh` | 2 | `tree-sitter parse` accepts a sample JSON |
| 4 | Apply trailing-comma mutation, regenerate | 3 | `tree-sitter parse '{"a":1,}'` → no ERROR |
| 5 | Corpus: `literals.txt` + `objects.txt` + `arrays.txt` | 4 | `tree-sitter test` green |
| 6 | Corpus: `comments.txt` | 5 | `tree-sitter test` green |
| 7 | Corpus: `trailing_commas.txt` | 6 | `tree-sitter test` green |
| 8 | Corpus: `degenerate.txt` + `invalid.txt` | 7 | `tree-sitter test` green |
| 9 | Cargo + minimal `src/lib.rs` | 1 | `cargo build --release --target wasm32-wasip2` ok |
| 10 | `extension.toml` (manifest + grammars) | 9 | parses as TOML; matches spec |
| 11 | `languages/hujson/config.toml` | 10 | parses; matches spec |
| 12 | `queries/hujson/highlights.scm` | 4, 11 | tree-sitter query compiles |
| 13 | `queries/hujson/brackets.scm` + `indents.scm` + `outline.scm` | 12 | queries compile |
| 14 | GitHub Actions `ci.yml` | 8, 9, 13 | CI green on push |
| 15 | Manual Zed dev-install verification doc | 14 | README has section; smoke instructions |
| 16 | CHANGELOG + final polish | 15 | repo ready for registry PR |

This is the granularity I'll target: each step is a single PR-shaped change.

---

## Phase 3 — Code-generation prompts

Each prompt is self-contained and assumes the previous prompts have been applied. Run them in order.

> **Conventions for all prompts**
> - Working directory: repo root `zed-hujson/`.
> - Do not commit the `target/`, `node_modules/`, or `build/` directories.
> - After every step, run the verification command(s) listed in the prompt and ensure they pass before moving on.
> - Treat the spec at `/Users/gvns/notes/gVault/01-PROJECTS/zed-hujson/spec.md` as the source of truth. If a prompt and the spec disagree, re-read the spec section referenced in the prompt and prefer it.

---

### Prompt 1 — Repo bootstrap

```text
You are working in an empty git repo named `zed-hujson` (owner `ggfevans`).

Create exactly these files at the repo root:

1. `LICENSE` — MIT licence text, copyright "Gareth Evans" with the current year.
2. `README.md` — short description of the project: a Zed extension providing
   HuJSON (JWCC) syntax highlighting. List v0.1 features (Tree-sitter highlighting,
   `.hujson` file association, brackets, indent, outline). Add an "Installation"
   placeholder ("coming soon to the Zed registry; for dev use Extensions > Install
   Dev Extension"). Add a "Grammar" section noting it's a fork of tree-sitter-json
   with a single change (trailing commas allowed). Link to:
     - https://github.com/tailscale/hujson
     - https://nigeltao.github.io/blog/2021/json-with-commas-comments.html
3. `.gitignore`:
       node_modules/
       target/
       build/
       *.wasm
4. `.gitattributes`:
       grammars/hujson/src/parser.c linguist-generated=true
       grammars/hujson/src/tree_sitter/* linguist-generated=true

Also create empty placeholder directories with a `.gitkeep` if needed:
`grammars/hujson/`, `languages/hujson/`, `queries/hujson/`, `src/`,
`.github/workflows/`.

Do not create any other files. Produce no source code beyond the above.
```

---

### Prompt 2 — Vendor the upstream grammar

```text
Goal: vendor `tree-sitter/tree-sitter-json` at the **repo root** (decision 1) as
a starting point, renamed to `hujson`, with no behavioural changes yet.

Steps:
1. Pin upstream to commit SHA `001c28d7a29832b06b0e831ec77845553c89b56d` (HEAD of
   master at fork time). Copy files from that commit into the **repo root**
   (NOT under `grammars/hujson/`):
     - `grammar.js`, `package.json`, `tree-sitter.json`, `binding.gyp`
     - `test/` (the upstream corpus directory — we'll replace its contents
       in later prompts; keep the directory)
     - Rename upstream's `queries/` directory to `tree-sitter-queries/` so it
       doesn't clash with the Zed-specific `queries/hujson/` we add later.
   Skip the upstream's `bindings/` directory (Rust/Node/Go/Python/Swift) — we
   don't need them; they can be regenerated on demand if external editors want
   them later.
   Skip the upstream's `.git/`, `.github/`, and any CI files.
2. In `grammar.js` (now at repo root) change `name: 'json'` to `name: 'hujson'`.
   Update the top JSDoc block to credit upstream and add a note:
       Forked from tree-sitter-json at commit
       001c28d7a29832b06b0e831ec77845553c89b56d.
3. In `package.json` (now at repo root) set `"name": "tree-sitter-hujson"` and
   update `description` to "HuJSON (JWCC) grammar for tree-sitter — JSON with
   comments and trailing commas". Set `repository.url` to
   `https://github.com/ggfevans/zed-hujson.git` (no `directory:` key needed
   since the grammar is at the repo root).
4. Regenerate the parser from the repo root:
       tree-sitter generate
   Commit the regenerated `src/parser.c`, `src/grammar.json`,
   `src/node-types.json`, and `src/tree_sitter/` headers. Note: `src/` is
   shared with `src/lib.rs` (added in Prompt 9); Cargo only picks up `lib.rs`.

Do NOT modify `commaSep` yet. Do NOT add corpus tests yet.

Verification:
    tree-sitter test                              # zero tests, exits 0
    echo '{"a":1}' | tree-sitter parse /dev/stdin # produces a clean tree
```

---

### Prompt 3 — Grammar metadata + `scripts/check-queries.sh`

```text
At the repo root, write `tree-sitter.json`:

    {
      "grammars": [
        {
          "name": "hujson",
          "scope": "source.hujson",
          "file-types": ["hujson"],
          "injection-regex": "hujson",
          "highlights": "tree-sitter-queries/highlights.scm"
        }
      ],
      "metadata": {
        "version": "0.1.0",
        "license": "MIT",
        "description": "HuJSON (JWCC) grammar for tree-sitter",
        "authors": [
          { "name": "Gareth Evans", "email": "hi@gvns.ca" }
        ],
        "links": {
          "repository": "https://github.com/ggfevans/zed-hujson"
        }
      }
    }

Note `highlights` points at `tree-sitter-queries/highlights.scm` — the
Neovim/Helix-facing query file we copied (and renamed) from upstream in Prompt 2.
The Zed-specific queries under `queries/hujson/` are separate (added in
Prompts 12–13).

If `tree-sitter-queries/highlights.scm` is missing or stale (upstream's version
pre-dates HuJSON node names), overwrite it with the spec's §5.1 highlights
content.

Also create `scripts/check-queries.sh` (decision 4 — belt-and-braces node-name
verification). The script must:

  1. Run `tree-sitter query` for every file in `queries/hujson/*.scm`,
     failing the build on any unknown node.
  2. For every `(node_name)` capture appearing in `queries/hujson/*.scm`,
     grep `src/node-types.json` and fail if not found.

Make it executable (`chmod +x`).

Verification:
    tree-sitter generate && tree-sitter test
    # scripts/check-queries.sh will be wired in fully in Prompts 12–13 once
    # the queries/hujson/ files exist; just confirm the script is executable
    # and exits 0 when no queries/hujson/*.scm files are present.
```

---

### Prompt 4 — Apply the JWCC trailing-comma mutation

```text
In `grammar.js` (at the repo root), replace the existing `commaSep1`/`commaSep`
helpers (whatever the upstream shape was) with:

    function commaSep1(rule) {
      return seq(rule, repeat(seq(',', rule)), optional(','));
    }

    function commaSep(rule) {
      return optional(commaSep1(rule));
    }

This is the only semantic change to the upstream grammar.

Regenerate the parser and re-run tests from the repo root:
    tree-sitter generate && tree-sitter test

Sanity-check by parsing JWCC inputs that vanilla JSON would reject:
    echo '{"a": 1,}' | tree-sitter parse /dev/stdin
    echo '[1, 2, 3,]' | tree-sitter parse /dev/stdin

Both must produce trees with NO `ERROR` node.
```

---

### Prompt 5 — Corpus tests: literals / objects / arrays

```text
Create `test/corpus/literals.txt`, `test/corpus/objects.txt`, and
`test/corpus/arrays.txt` (paths relative to repo root) using tree-sitter's
corpus format:

    ==================
    <test name>
    ==================

    <input>

    ---

    <expected s-expression tree>

Cover (per spec.md §8.1):

literals.txt:
  - Plain string, escaped string (\", \\, \n, \uXXXX)
  - Integer, negative integer, float, exponent
  - true, false, null

objects.txt:
  - Empty object
  - Single pair
  - Multiple pairs
  - Nested objects
  - Object containing every value type

arrays.txt:
  - Empty array
  - Single element
  - Multiple elements
  - Nested arrays
  - Mixed value types

Verification:
    tree-sitter test   # all green (run from repo root)
```

---

### Prompt 6 — Corpus tests: comments

```text
Create `test/corpus/comments.txt` (repo root) covering:
  - Line comment at end of line after a value
  - Standalone line comment
  - Inline block comment
  - Multi-line block comment
  - Comment between object pairs
  - Comment between array elements
  - Comment before the root value
  - Comment after the root value
  - Empty block comment `/* */`
  - Pseudo-nested block comment: `/* outer /* inner */ trailing */` — the FIRST
    `*/` terminates; the trailing ` trailing */` becomes ERROR content.
    Reflect this in the expected tree.

Verification:
    tree-sitter test
```

---

### Prompt 7 — Corpus tests: trailing commas

```text
Create `test/corpus/trailing_commas.txt` (repo root). Positive cases (must
parse cleanly, no ERROR):
  - `{"a": 1,}`
  - `[1, 2, 3,]`
  - `{"a": {"b": 1,},}`
  - `[[1,], [2,],]`
  - Trailing comma followed by a line comment on same line
  - Block comment between last element and trailing comma, e.g.:
        {
          "a": 1 // note
          ,
        }

Negative cases (must produce ERROR somewhere):
  - `{"a": 1,, "b": 2}` (double comma)
  - `{,"a": 1}` (leading comma)
  - `{,}` (empty object with comma)
  - `[,]` (empty array with comma)

Verification:
    tree-sitter test
```

---

### Prompt 8 — Corpus tests: degenerate + invalid

```text
Create `test/corpus/degenerate.txt` (repo root):
  - Empty input
  - Whitespace only
  - Comment only (line; then block)
  - BOM at start of file (\uFEFF) — tree-sitter is expected to ERROR on the BOM
    but recover; encode this in the expected tree.
  - Bare root value: string, number, null
  - Unicode in comments and strings
  - Deeply nested object (e.g. 50 levels) — assertion: parses without panic.
    Use a generated input via the corpus's `:skip-tree` style if helpful, or
    simply assert the outer shape and leave inner repetition canonical.

Create `test/corpus/invalid.txt` (repo root). All cases must produce ERROR:
  - `{key: "value"}`        (unquoted key)
  - `{'k': 'v'}`            (single quotes)
  - `{"a": 0xFF}`           (hex literal)
  - `{"a": Infinity}`
  - `{"a": NaN}`
  - `{"a": hello}`          (unquoted value)

Verification:
    tree-sitter test    # everything green (run from repo root)
```

---

### Prompt 9 — Rust extension crate (compiles to WASM)

```text
At repo root create:

Decision 2: before writing `Cargo.toml`, check
`https://crates.io/crates/zed_extension_api` for the latest stable version
and pin to that exact version (NOT `0.7.0`). Record the version chosen in
spec.md §4.4 as a follow-up.

`Cargo.toml`:
    [package]
    name = "zed-hujson"
    version = "0.1.0"
    edition = "2021"

    [lib]
    crate-type = ["cdylib"]

    [dependencies]
    # Replace <LATEST_STABLE> with the version from crates.io.
    zed_extension_api = "<LATEST_STABLE>"

    [profile.release]
    opt-level = "s"
    lto = true

`src/lib.rs` (note: this lives alongside the generated `parser.c` etc.;
Cargo only picks up `lib.rs`):

    // v0.1: highlighting-only — no language server / formatter / completions.
    use zed_extension_api as zed;

    struct HujsonExtension;

    impl zed::Extension for HujsonExtension {
        fn new() -> Self {
            HujsonExtension
        }
    }

    zed::register_extension!(HujsonExtension);

Decision 3: open the docs.rs page for the version pinned in `Cargo.toml`
and inspect the `Extension` trait signature. For every required method beyond
`new()`, add a minimal no-op stub returning the most conservative "unsupported"
value (`Ok(None)` / `Err("hujson extension does not provide <feature>".into())`).
Use `_`-prefixed parameter names for clippy.

Verification:
    rustup target add wasm32-wasip2
    cargo build --release --target wasm32-wasip2
    test -f target/wasm32-wasip2/release/zed_hujson.wasm
    cargo clippy --target wasm32-wasip2 -- -D warnings
    cargo fmt -- --check
```

---

### Prompt 10 — Zed extension manifest

```text
At repo root, create `extension.toml`:

    id = "hujson"
    name = "HuJSON"
    version = "0.1.0"
    schema_version = 1
    authors = ["Gareth Evans <gareth.gwilym.frederick.evans@gmail.com>"]
    description = "HuJSON (JWCC) support — JSON with comments and trailing commas"
    repository = "https://github.com/ggfevans/zed-hujson"

    [grammars.hujson]
    repository = "https://github.com/ggfevans/zed-hujson"
    # path key intentionally omitted: grammar lives at the repo root
    # (decision 1). Equivalent to `path = "."`.

No other content.
```

---

### Prompt 11 — Language configuration

```text
Create `languages/hujson/config.toml`:

    name = "HuJSON"
    grammar = "hujson"
    path_suffixes = ["hujson"]
    line_comments = ["//"]
    block_comment = ["/*", "*/"]
    tab_size = 2
    hard_tabs = false
    autoclose_before = ",]}"
    brackets = [
      { start = "{", end = "}", close = true, newline = true },
      { start = "[", end = "]", close = true, newline = true },
      { start = "\"", end = "\"", close = true, newline = false, not_in = ["string"] },
    ]
    word_characters = ["-"]
```

---

### Prompt 12 — Highlights query

```text
Create `queries/hujson/highlights.scm` per spec.md §5.1:

    ; Strings
    (string) @string
    (escape_sequence) @string.escape

    ; Numbers
    (number) @number

    ; Booleans and null
    (true) @constant.builtin
    (false) @constant.builtin
    (null) @constant.builtin

    ; Object keys
    (pair
      key: (string) @property.json_key)

    ; Punctuation
    "{" @punctuation.bracket
    "}" @punctuation.bracket
    "[" @punctuation.bracket
    "]" @punctuation.bracket
    ":" @punctuation.delimiter
    "," @punctuation.delimiter

    ; Comments
    (comment) @comment

Verification (run from repo root — decision 4, belt-and-braces):
    tree-sitter query queries/hujson/highlights.scm
    # And confirm every node referenced exists in src/node-types.json:
    for n in string escape_sequence number true false null pair comment; do
      grep -q "\"$n\"" src/node-types.json || echo "MISSING: $n"
    done
```

---

### Prompt 13 — Brackets, indents, outline queries

```text
Create three files under `queries/hujson/`:

`brackets.scm`:
    ("{" @open "}" @close)
    ("[" @open "]" @close)
    ("\"" @open "\"" @close)

`indents.scm`:
    (object) @indent
    (array) @indent

    "}" @outdent
    "]" @outdent

`outline.scm`:
    (pair
      key: (string) @name) @item

Verification (run from repo root):
    for f in queries/hujson/*.scm; do tree-sitter query "$f"; done
    scripts/check-queries.sh   # decision 4: full audit
```

---

### Prompt 14 — GitHub Actions CI

```text
Create `.github/workflows/ci.yml` with three jobs:

1. `grammar-test` (Ubuntu):
   - actions/checkout@v4
   - actions/setup-node@v4 with node-version "22"
   - npm install -g tree-sitter-cli
   - tree-sitter generate (run from repo root)
   - tree-sitter test
   - scripts/check-queries.sh   # decision 4

2. `extension-build` (Ubuntu):
   - actions/checkout@v4
   - dtolnay/rust-toolchain@stable with target wasm32-wasip2
   - cargo build --release --target wasm32-wasip2
   - test -f target/wasm32-wasip2/release/zed_hujson.wasm

3. `lint` (Ubuntu):
   - dtolnay/rust-toolchain@stable with components clippy, rustfmt and target
     wasm32-wasip2
   - cargo clippy --target wasm32-wasip2 -- -D warnings
   - cargo fmt -- --check

Trigger on push to `main` and on pull requests targeting `main`. Set
`permissions: contents: read` at workflow scope.

Verification: push a branch, open a draft PR, ensure all three jobs go green.
```

---

### Prompt 15 — Local Zed verification + README update

```text
Add a "Development" section to `README.md` describing:

    # Prerequisites
    - Node 18+, tree-sitter-cli (`npm i -g tree-sitter-cli`)
    - Rust stable, `rustup target add wasm32-wasip2`
    - Zed Preview channel

    # Build
    tree-sitter generate && tree-sitter test
    cargo build --release --target wasm32-wasip2
    scripts/check-queries.sh

    # Install in Zed
    Open Zed → Extensions → "Install Dev Extension" → select repo root.

    # Reload after edits
    Cmd/Ctrl+Shift+P → "zed: reload extensions"

Also create `examples/sample.hujson` with a Tailscale-ACL-flavoured snippet
(comments + trailing commas + nested objects/arrays) for manual smoke tests.
Reference it from the README.

Decision 5 — add a "Compatibility" section to the README explicitly stating:
  - This extension only handles `.hujson` files.
  - `.json` and `.jsonc` are left to Zed's built-in grammars.
  - The grammar id `hujson` is distinct from `json` / `jsonc`.

Manual smoke checks to perform after dev-installing in Zed:
  - Open `examples/sample.hujson` → status bar shows "HuJSON".
  - Open a `.json` file → status bar still shows "JSON" (not HuJSON).
  - Open a `.jsonc` file → status bar shows "JSON with Comments".
  - No duplicate-grammar warnings in Zed's log.

No new code paths required.
```

---

### Prompt 16 — CHANGELOG + release polish

```text
Create `CHANGELOG.md` following Keep-a-Changelog style with an Unreleased
section and an entry for v0.1.0 listing:
  - Tree-sitter HuJSON grammar (forked from tree-sitter-json
    @ 001c28d7a29832b06b0e831ec77845553c89b56d, JWCC trailing-comma mutation)
  - Zed language config for `.hujson`
  - Highlights, brackets, indents, outline queries
  - CI: grammar tests, WASM build, clippy + rustfmt

Final repo audit:
  - `extension.toml` `id = "hujson"` not already taken in zed-industries/extensions
  - `LICENSE` present at repo root (registry CI requirement)
  - `tree-sitter test`, `cargo build --release --target wasm32-wasip2`,
    `cargo clippy`, `cargo fmt --check` all clean.
  - All four `.scm` query files compile against the generated grammar.
  - `scripts/check-queries.sh` clean (decision 4).

Decision 5 — registry pre-publish search. Before opening the PR to
`zed-industries/extensions`:
  - Clone the registry repo locally.
  - `grep -r 'hujson' .`         (id collision)
  - `grep -rE '\.hujson\b' .`    (extension claim)
  - `grep -rE 'path_suffixes.*hujson' .`
  If any prior claim exists, decide on rename / coordination before submitting.

Output: a checklist of any remaining manual tasks before opening a PR to
`zed-industries/extensions` (fork registry, add submodule via HTTPS, run
`pnpm sort-extensions`, open PR).
```

---

## Notes on ordering and integration

- **No orphans**: every artifact created by a prompt is consumed by a later prompt or by a verification command in the same prompt. Examples: the grammar from steps 2–4 is exercised by tests in 5–8, then consumed by queries in 12–13 and the manifest in 10; the WASM crate from step 9 is referenced by the manifest in step 10 and the CI in step 14.
- **Resync points**: after step 4 (grammar mutation locked in), after step 8 (corpus complete), after step 14 (CI green). These are good commit/tag boundaries.
- **Out of scope** (deferred to v0.2+ per spec §11): formatter integration, LSP, `.jwcc` file extension, schema validation, release workflow.
