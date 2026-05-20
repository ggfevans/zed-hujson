# HuJSON for Zed

A Zed extension providing syntax highlighting and editor support for HuJSON (Human JSON).
HuJSON is a superset of JSON defined by the JWCC (JSON With Commas and Comments) specification. It permits C-style line or block comments and trailing commas in objects or arrays. All valid JSON is valid HuJSON. It strictly rejects other syntax extensions like unquoted keys or single-quoted strings.
Unlike default JSON parsers that flag comments and trailing commas as syntax errors, this extension provides a valid Abstract Syntax Tree (AST). This preserves editor features like code folding, document symbols, and auto-formatting without throwing false error squiggles.

## Features

* Syntax highlighting via a dedicated Tree-sitter grammar
* File type association (.hujson, .jwcc)
* Automatic comment toggling (Cmd+/) for line and block comments
* Bracket matching and auto-closing pairs
* Document outline support for object key navigation

## Installation

Open the Extensions view in Zed (Cmd+Shift+X), search for HuJSON, and click install.

## Grammar

The underlying parser lives at ggfevans/tree-sitter-hujson. It forks tree-sitter-json to allow optional trailing commas via the commaSep helper.

The extension pins this grammar by repository URL and commit hash in extension.toml. To update the pinned revision, update the commit value and run the query check script.

## Formatting

To enable format-on-save with [hujsonfmt](https://github.com/tailscale/hujson/tree/main/cmd/hujsonfmt), add the following to your Zed `settings.json`:

```json
{
  "languages": {
    "HuJSON": {
      "formatter": {
        "external": {
          "command": "hujsonfmt",
          "arguments": []
        }
      },
      "format_on_save": "on"
    }
  }
}
```

Install hujsonfmt with:

```
go install tailscale.com/cmd/hujsonfmt@latest
```

> **Note:** Zed extensions cannot yet register a default external formatter ([zed#31904](https://github.com/zed-industries/zed/issues/31904)). When that API lands, this extension will provide formatting out of the box with no manual config required.

## Compatibility

This extension registers the `hujson` grammar ID. It isolates tracking to `.hujson` and `.jwcc` files. It does not conflict with or override Zed's built-in `json` or `jsonc` grammars.

This extension is particularly useful for formats like Tailscale ACL policy files, which rely on HuJSON features that standard JSON parsers flag as syntax errors.

## Development

### Prerequisites

* Node 18+ and tree-sitter-cli (npm i -g tree-sitter-cli)
* Rust stable with the WebAssembly target (rustup target add wasm32-wasip2)
* Zed Preview (required for local extension loading)

## Build

Compile the extension and verify the Tree-sitter queries against your pinned grammar:

```
cargo build --release --target wasm32-wasip2
./scripts/check-queries.sh
```

## Local Testing

   1. Open the command palette in Zed (Cmd+Shift+P).
   2. Run Extensions: Install Dev Extension.
   3. Select this repository root directory.
   4. Open examples/sample.hujson to verify the syntax highlighting and comment behavior.

Use Extensions: Reload Extensions from the command palette to apply updates after making changes.

## License

MIT
