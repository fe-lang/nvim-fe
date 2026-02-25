# nvim-fe Plugin

Neovim plugin for the **Fe programming language** with:
- Syntax highlighting via Tree-sitter
- Indentation support
- LSP integration for go-to-definition and more

## Installation

### Prerequisites

1. **`fe` CLI** (includes the language server)
If you haven't already, install it to your `PATH`:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/argotorg/fe/master/feup/feup.sh | bash
  ```
  Or build from source:
  ```bash
  cargo install --git https://github.com/argotorg/fe.git fe
  ```
2. **Neovim 0.9.0 or later**

3. **GCC or Clang**
For compiling the tree-sitter parser (done automatically on first run)


---

### Manual Installation

1. Copy this directory to:
  ```bash
  cp -r ./ ~/.local/share/nvim/site/pack/plugins/start/nvim-fe
  ```

2. Add to `init.lua`:
  ```lua
  require("nvim_fe").setup()
  ```

---

### Install with `packer.nvim`

Add to your packer config:

```lua
use({
    "https://github.com/fe-lang/nvim-fe",
    config = function()
        require("nvim_fe").setup()
    end,
})
```

### Install with `lazy.nvim`

```lua
{
    "https://github.com/fe-lang/nvim-fe",
    config = function()
        require("nvim_fe").setup()
    end,
}
```

---

## Troubleshooting

### Missing Syntax Highlighting

1. Check that the parser was compiled:
   ```bash
   :lua print(vim.fn.filereadable(vim.fn.stdpath("data") .. "/nvim-fe-runtime/parser/fe.so"))
   ```
   Should print `1`. If not, ensure `gcc` or `clang` is installed and re-run `:lua require("nvim_fe").setup()`.

2. Check queries:
   ```bash
   :lua print(vim.inspect(vim.api.nvim_get_runtime_file("queries/fe/*.scm", true)))
   ```
   Ensure `fe` queries are loaded.

---

### Missing LSP Features

1. Ensure `fe` is installed and available in your `PATH`.

2. Check the LSP client:
   ```bash
   :LspInfo
   ```
   Confirm the Fe LSP client is listed and attached.

---

### Reinstall the Plugin

Delete the runtime directories to force reinstallation:
```bash
rm -rf ~/.local/share/nvim/tree-sitter-fe
rm -rf ~/.local/share/nvim/nvim-fe-runtime
```

Restart Neovim and the plugin will reinitialize.
