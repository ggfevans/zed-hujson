# Roadmap

Tracks features intentionally deferred from v0.1 (which is strictly Tree-sitter highlighting + editor affordances). Each entry should become a tracking issue once the v0.1 registry PR is merged.

## v0.2 — Formatter integration

Wire [`hujsonfmt`](https://github.com/tailscale/hujson) into Zed via a thin language-server wrapper.

- Implement `language_server_command()` in `src/lib.rs` to spawn `hujsonfmt` with stdin/stdout document framing.
- Add `[language_servers.hujsonfmt]` to `extension.toml` mapping the server to the `HuJSON` language.
- Surface as **Format Document / Format Selection** + format-on-save.
- Document the `hujsonfmt` install requirement in the README.

Open question: whether to ship the binary path/version pinning logic in the extension or rely on the user's `$PATH`. Tailscale doesn't currently distribute prebuilt `hujsonfmt` binaries, so the extension may need to handle a `go install` flow on first run.

## v0.3 — Schema validation (LSP)

Provide diagnostics + completions for JWCC documents that have an associated schema (e.g. Tailscale ACLs).

- Investigate whether existing JSON-Schema language servers (`vscode-json-language-server`, `taplo`-style) can be coaxed into accepting JWCC input, or whether HuJSON needs its own minimal validator.
- If reusing `vscode-json-language-server`: add a preprocessing step in the extension that strips comments + trailing commas before forwarding to the server (preserve original positions for diagnostics).
- Wire `language_ids` so the server sees `HuJSON` buffers as `jsonc` or `json` per its expectations.
- Provide a default schema mapping for common HuJSON consumers (Tailscale ACL, `tailscale.json`, etc.).

## Beyond v0.3

- `.jwcc` file-extension association alongside `.hujson` (gate on real-world demand).
- Standalone formatter binary distribution (if `hujsonfmt` upstream doesn't add releases).
- Quarterly upstream sync against `tree-sitter-json` (per spec §11.3).

See [spec.md §11](docs/plan/spec.md) for the full deferral rationale.
