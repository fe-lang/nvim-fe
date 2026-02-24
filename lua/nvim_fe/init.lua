local M = {}

local ts_repo_url = "https://github.com/argotorg/fe.git"
local plugin_runtime_dir = vim.fn.stdpath("data") .. "/nvim-fe-runtime"
local queries_dir = plugin_runtime_dir .. "/queries/fe"
local parser_dir = plugin_runtime_dir .. "/parser"
local repo_dir = vim.fn.stdpath("data") .. "/tree-sitter-fe"

local function ensure_dir(dir)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

local function add_to_runtime()
    if not vim.tbl_contains(vim.opt.runtimepath:get(), plugin_runtime_dir) then
        vim.opt.runtimepath:prepend(plugin_runtime_dir)
    end
end

local function needs_setup()
    if vim.fn.isdirectory(repo_dir) == 0 then
        return true
    end
    local parser_so = parser_dir .. "/fe.so"
    if vim.fn.filereadable(parser_so) == 0 then
        return true
    end
    local query_files = vim.fn.glob(queries_dir .. "/*.scm", false, true)
    return #query_files == 0
end

local function setup_repository()
    if vim.fn.isdirectory(repo_dir) == 0 then
        vim.fn.system({ "git", "clone", "--depth", "1", ts_repo_url, repo_dir })
        vim.notify("Cloned fe repository.", vim.log.levels.INFO)
    else
        vim.fn.system({ "git", "-C", repo_dir, "pull" })
        vim.notify("Updated fe repository.", vim.log.levels.INFO)
    end
end

local function setup_queries()
    ensure_dir(queries_dir)

    local repo_queries_dir = repo_dir .. "/crates/tree-sitter-fe/queries"
    if vim.fn.isdirectory(repo_queries_dir) == 1 then
        for _, query_file in ipairs(vim.fn.glob(repo_queries_dir .. "/*.scm", false, true)) do
            local dest = queries_dir .. "/" .. vim.fn.fnamemodify(query_file, ":t")
            vim.fn.system({ "cp", query_file, dest })
        end
    else
        vim.notify("No queries directory found in fe repository.", vim.log.levels.WARN)
    end
end

local function compile_parser()
    ensure_dir(parser_dir)

    local src_dir = repo_dir .. "/crates/tree-sitter-fe/src"
    local parser_c = src_dir .. "/parser.c"
    local scanner_c = src_dir .. "/scanner.c"
    local output = parser_dir .. "/fe.so"

    if vim.fn.filereadable(parser_c) == 0 then
        vim.notify("parser.c not found, cannot compile Fe parser.", vim.log.levels.ERROR)
        return false
    end

    local cc = vim.fn.executable("cc") == 1 and "cc"
        or vim.fn.executable("gcc") == 1 and "gcc"
        or vim.fn.executable("clang") == 1 and "clang"
    if not cc then
        vim.notify("No C compiler found. Install gcc or clang to compile the Fe parser.", vim.log.levels.ERROR)
        return false
    end

    local sources = { parser_c }
    if vim.fn.filereadable(scanner_c) == 1 then
        table.insert(sources, scanner_c)
    end

    local cmd = { cc, "-o", output, "-shared", "-fPIC", "-O2", "-I", src_dir }
    for _, src in ipairs(sources) do
        table.insert(cmd, src)
    end

    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to compile Fe parser:\n" .. result, vim.log.levels.ERROR)
        return false
    end

    vim.notify("Compiled Fe tree-sitter parser.", vim.log.levels.INFO)
    return true
end

local function setup_filetype()
    vim.filetype.add({
        extension = {
            fe = "fe",
        },
    })
end

local function setup_highlighting()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "fe",
        callback = function()
            pcall(vim.treesitter.start)
        end,
    })
end

local function setup_lsp()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "fe",
        callback = function()
            local current_file = vim.api.nvim_buf_get_name(0)
            local result = vim.fn.system({ "fe", "root", current_file })
            local root_dir
            if vim.v.shell_error == 0 then
                root_dir = vim.trim(result)
            else
                root_dir = vim.fs.dirname(current_file)
            end

            local client_id = vim.lsp.start_client({
                name = "fe",
                cmd = { "fe", "lsp" },
                root_dir = root_dir,
                filetypes = { "fe" },
            })

            if client_id then
                vim.lsp.buf_attach_client(0, client_id)
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = true })
            end
        end,
    })
end

function M.setup()
    ensure_dir(plugin_runtime_dir)
    add_to_runtime()
    setup_filetype()

    if needs_setup() then
        setup_repository()
        setup_queries()
        compile_parser()
    end

    setup_highlighting()
    setup_lsp()
end

return M
