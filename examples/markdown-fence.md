# Markdown `hujson` code-fence demo

Open this file in Zed (with the HuJSON extension installed) and the fenced block
below highlights as HuJSON — comments and trailing commas included — with no extra
configuration. Zed matches the fence info string (`hujson`) to this extension by
language name, so the Markdown grammar injects the highlighting automatically.

```hujson
{
  // line comment
  "name": "tailscale-acl",
  /* block comment */
  "hosts": {
    "server": "100.64.0.1", // trailing comma is valid in HuJSON
  },
  "tags": ["prod", "web",], // and here
}
```

Plain JSON also highlights, since all valid JSON is valid HuJSON:

```hujson
{ "ok": true, "count": 3 }
```
