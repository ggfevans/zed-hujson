# v0.1.0 release hand-off

I (Claude) prepped what I could without needing pushed state. The submodule pin requires `v0.1.0` to exist on GitHub, so the submodule + commit step has to wait until after you push the tag. Below is the full sequence.

## Current state

**`zed-hujson`**:
- HEAD = `c2047bc` "polish: align queries to doc idioms, expand README, prep for v0.1.0".
- Tag `v0.1.0` exists locally (annotated, points at `c2047bc`). Not pushed.
- All gates green: `tree-sitter test` (in tree-sitter-hujson), `cargo build/clippy/fmt`, `scripts/check-queries.sh`.

**`extensions` (your fork)**:
- On branch `add-hujson-extension`, synced to `upstream/main`. Empty branch — no changes staged.

## Step 1 — Push zed-hujson main + v0.1.0 tag

```bash
cd ~/code/projects/zed-hujson
git push origin main
git push origin v0.1.0
```

Check: https://github.com/ggfevans/zed-hujson/releases/tag/v0.1.0 exists.

## Step 2 — Add the submodule pinned to v0.1.0 in the extensions fork

```bash
cd ~/code/projects/extensions

# Should already be on add-hujson-extension; if not:
git checkout add-hujson-extension

git submodule add https://github.com/ggfevans/zed-hujson.git extensions/hujson
(cd extensions/hujson && git fetch --tags && git checkout v0.1.0)
git add extensions/hujson
```

## Step 3 — Add the [hujson] entry to extensions.toml

Open `extensions.toml`, add this block in alphabetical order (between `[htmx]` and the next `h…` or `i…` entry — `pnpm sort-extensions` will normalise regardless):

```toml
[hujson]
submodule = "extensions/hujson"
version = "0.1.0"
```

Then:

```bash
pnpm install
pnpm sort-extensions
git add extensions.toml .gitmodules
```

## Step 4 — Sanity checks

```bash
ls extensions/hujson/LICENSE                              # must exist (registry CI requirement)
(cd extensions/hujson && git describe --exact-match HEAD) # should print v0.1.0
grep -A2 '^\[hujson\]' extensions.toml                    # entry present
git diff --cached --stat                                  # only .gitmodules + extensions.toml + extensions/hujson
```

## Step 5 — Commit and open the PR

```bash
git commit -m "Add hujson extension"

git push -u origin add-hujson-extension

gh pr create --repo zed-industries/extensions \
  --base main \
  --head ggfevans:add-hujson-extension \
  --title "Add hujson extension" \
  --body "$(cat <<'BODY'
Adds a Zed extension for HuJSON (JWCC) — JSON with comments and trailing commas.

- Grammar lives at https://github.com/ggfevans/tree-sitter-hujson, pinned by commit in extension.toml.
- Tested as a dev extension locally; sample document at examples/sample.hujson.
- LICENSE present at submodule root.

Closes any related discussion in zed-hujson.
BODY
)"
```

## Things to watch

- **Tag must exist on origin** before the registry PR is opened. Step 1 first.
- **Submodule URL is HTTPS, not SSH** — registry CI rejects SSH.
- **Don't `git push --force`** to either repo.
- If `pnpm sort-extensions` rewrites the file substantially, that's expected — the diff is normalisation; commit it.
- If you want the existing main of the extensions fork synced too: `git checkout main && git push origin main` after step 1.
