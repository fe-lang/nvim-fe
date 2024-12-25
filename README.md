# nvim-fe Plugin

Neovim plugin for the **Fe programming language** with:
- Syntax highlighting via Tree-sitter
- Indentation support
- LSP integration for go-to-definition and more

## Installation

### Prerequisites

1. **`fe-language-server`**
If you haven't already, install it to your `PATH`:
  ```bash
  cargo install --git https://github.com/ethereum/fe.git --branch fe-v2 fe-language-server
  ```
2. **Neovim 0.9.0 or later**
Requires Tree-sitter and `vim.filetype.add` support

3. **GCC or Clang**
For compiling the Tree-sitter parser


---

### Manual Installation

1. Copy this directory to:
  ```bash
  cp -r ./ ~/.local/share/nvim/site/pack/plugins/start/nvim-fe
  ```

2. Install `nvim-treesitter`:
  ```bash
  git clone https://github.com/nvim-treesitter/nvim-treesitter ~/.local/share/nvim/site/pack/plugins/start/nvim-treesitter
  ```

3. Add to `init.lua`:
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
    requires = {
        "nvim-treesitter/nvim-treesitter",
    },
})
```

### Install with `lazy.nvim`

```lua
{
    "https://github.com/fe-lang/nvim-fe",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("nvim_fe").setup()
    end,
}
```

---

## Troubleshooting

### Missing Syntax Highlighting

1. Ensure `nvim-treesitter` is installed:
   ```bash
   :TSInstallInfo
   ```
   Confirm `fe` is listed under "Parsers installed."

2. Check queries:
   ```bash
   :lua print(vim.inspect(vim.api.nvim_get_runtime_file("queries/fe/*.scm", true)))
   ```
   Ensure `fe` queries are loaded.

---

### Missing LSP Features

1. Ensure `fe-language-server` is installed and available in your `PATH`.

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
