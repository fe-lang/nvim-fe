local M = {}

local ts_repo_url = "https://github.com/fe-lang/tree-sitter-fe.git"
local plugin_runtime_dir = vim.fn.stdpath("data") .. "/nvim-fe-runtime"
local queries_dir = plugin_runtime_dir .. "/queries/fe"
local repo_dir = vim.fn.stdpath("data") .. "/tree-sitter-fe"

-- Ensure a directory exists
local function ensure_dir(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

-- Prepend the plugin's runtime directory to Neovim's runtime path
local function add_to_runtime()
    if not vim.tbl_contains(vim.opt.runtimepath:get(), plugin_runtime_dir) then
        vim.opt.runtimepath:prepend(plugin_runtime_dir)
    end
end

-- Check if setup is needed
local function needs_setup()
    if vim.fn.isdirectory(repo_dir) == 0 then
        return true
    end
    local query_files = vim.fn.glob(queries_dir .. "/*.scm", false, true)
    return #query_files == 0 -- Check if queries are missing
end

-- Clone or update the tree-sitter-fe repository
local function setup_repository()
    if vim.fn.isdirectory(repo_dir) == 0 then
        vim.fn.system({ "git", "clone", ts_repo_url, repo_dir })
        vim.notify("Cloned tree-sitter-fe repository.", vim.log.levels.INFO)
    else
        vim.fn.system({ "git", "-C", repo_dir, "pull" })
        vim.notify("Updated tree-sitter-fe repository.", vim.log.levels.INFO)
    end
end

-- Set up Tree-sitter queries
local function setup_queries()
    ensure_dir(queries_dir)

    local repo_queries_dir = repo_dir .. "/queries"
    if vim.fn.isdirectory(repo_queries_dir) == 1 then
        for _, query_file in ipairs(vim.fn.glob(repo_queries_dir .. "/*.scm", false, true)) do
            local dest = queries_dir .. "/" .. vim.fn.fnamemodify(query_file, ":t")
            vim.fn.system({ "cp", query_file, dest })
        end
        vim.notify("Fe queries copied to plugin runtime path.", vim.log.levels.INFO)
    else
        vim.notify("No queries directory found in tree-sitter-fe repository.", vim.log.levels.WARN)
    end
end

-- Configure Tree-sitter for Fe
local function setup_treesitter()
    local ok, _ = pcall(require, "nvim-treesitter.parsers")
    if not ok then
        vim.notify("nvim-treesitter is not installed. Please install it for Fe syntax highlighting.", vim.log.levels
            .WARN)
        return
    end

    -- Register Fe parser with nvim-treesitter
    -- require() must be called inside the callback to modify the cached module
    vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
            require("nvim-treesitter.parsers").fe = {
                install_info = {
                    url = ts_repo_url,
                    files = { "src/parser.c", "src/scanner.c" },
                    branch = "main",
                },
            }
        end,
    })

    -- Trigger registration immediately
    vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })

    -- Enable highlighting for Fe files
    local group = vim.api.nvim_create_augroup("FeTreesitterSetup", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "fe",
        callback = function(args)
            vim.treesitter.start(args.buf)
        end,
    })
end

-- Set up filetype detection for `.fe` files
local function setup_filetype()
    vim.filetype.add({
        extension = {
            fe = "fe",
        },
    })
end

-- Set up LSP for Fe
local function setup_lsp()
    local group = vim.api.nvim_create_augroup("FeLspSetup", { clear = true })

    local function start_or_attach_lsp()
        local function find_root(patterns)
            local current_file = vim.api.nvim_buf_get_name(0)
            local start_dir = vim.fs.dirname(current_file)

            for _, pattern in ipairs(patterns) do
                local found = vim.fs.find(pattern, {
                    upward = true,
                    path = start_dir,
                })

                if #found > 0 then
                    local dir = vim.fs.dirname(found[1])
                    return dir
                end
            end
            return nil
        end

        local root_dir = find_root({ "fe.toml" })
        if not root_dir then
            root_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
        end

        -- Check if ANY fe client already exists (ignore root_dir - reuse across all projects)
        local existing_client = nil
        local all_clients = vim.lsp.get_clients()

        for _, client in ipairs(all_clients) do
            if client.name == "fe" then
                existing_client = client
                break
            end
        end

        -- Start or attach the client
        if existing_client then
            -- Reuse the existing client regardless of root_dir
            -- The server will automatically load the ingot when the .fe file is opened
            vim.lsp.buf_attach_client(0, existing_client.id)
        else
            -- Start new client only if no fe client exists at all
            vim.lsp.start({
                name = "fe",
                cmd = { "fe-language-server" },
                root_dir = root_dir,
            })
        end
    end

    -- Trigger LSP for .fe files
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "fe",
        callback = function()
            start_or_attach_lsp()
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = true })
        end,
    })

    -- Trigger LSP for fe.toml files
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        group = group,
        pattern = "**/fe.toml",
        callback = function()
            start_or_attach_lsp()
        end,
    })
end

-- Plugin setup entry point
function M.setup()
    ensure_dir(plugin_runtime_dir)
    add_to_runtime()
    setup_filetype()

    if needs_setup() then
        setup_repository()
        setup_queries()
        setup_treesitter()
        vim.notify("Fe plugin setup completed.", vim.log.levels.INFO)
    else
        setup_treesitter() -- Ensure Tree-sitter is configured
    end

    setup_lsp()
end

return M
