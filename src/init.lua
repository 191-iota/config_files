-- Bootstrap Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "github.com/folke/lazy.nvim", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  'neovim/nvim-lspconfig',
  { 'nvim-treesitter/nvim-treesitter', build = ":TSUpdate" },
  'nvim-treesitter/nvim-treesitter-textobjects',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'L3MON4D3/LuaSnip',
  'saadparwaiz1/cmp_luasnip',
  { 'simrat39/rust-tools.nvim', ft = 'rust' },
  'nvim-tree/nvim-tree.lua',
  'junegunn/fzf.vim',
  'windwp/nvim-autopairs',
  'numToStr/Comment.nvim',
  'lewis6991/gitsigns.nvim',
  'tpope/vim-sleuth',
{
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("kanagawa").setup({
      compile = false,
      overrides = function(colors)
        return {
          Normal      = { bg = "#090917" },
          NormalFloat = { bg = "#090917" },
          SignColumn  = { bg = "#090917" },
          LineNr      = { bg = "#090917" },
          CursorLine  = { bg = "#090917" },
        }
      end,
      
    })

    vim.cmd("colorscheme kanagawa")
  end,
},
  { 'stevearc/conform.nvim', opts = {} },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
  },
})

-- LSP core (define BEFORE any lspconfig.setup calls)
local capabilities = require('cmp_nvim_lsp').default_capabilities() 
local function on_attach(client, bufnr)
  local keymap = function(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { noremap = true, silent = true }, opts or {}))
  end
  keymap('n', 'gd', vim.lsp.buf.definition)
  keymap('n', 'gr', vim.lsp.buf.references)
  keymap('n', 'K',  vim.lsp.buf.hover)
  keymap('n', 'gi', vim.lsp.buf.implementation)
  keymap('n', '<leader>ca', vim.lsp.buf.code_action)
  keymap('n', '<leader>rn', vim.lsp.buf.rename)

  if client.name == 'rust_analyzer' then
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      callback = function() vim.lsp.buf.format({ async = false }) end,
    })
    keymap('n', 'rnw', function()
      local word = vim.fn.expand('<cword>')
      local new = vim.fn.input('Replace "' .. word .. '" with: ')
      if new ~= '' and new ~= word then
        vim.cmd('%s/\\<' .. word .. '\\>/' .. new .. '/g')
      end
    end)
  end
end

-- HTML LSP
vim.lsp.config('html', {
  cmd = { 'html-languageserver', '--stdio' },
  filetypes = { 'html' },
  capabilities = capabilities,
})


require('conform').setup({
  formatters_by_ft = {
    svelte = { "prettier" },  -- assuming prettier handles svelte
    html = {
      "prettier_custom",
    },
    javascript = { 'prettierd', 'prettier' },
    javascriptreact = { 'prettierd', 'prettier' },
    json = { 'prettierd', 'prettier' },
  },
  formatters = {
    prettier_custom = {
      command = "prettier",
      args = { "--parser", "babel" }, -- or "angular" if your HTML is more template-like
      stdin = true,
    },
  },
})
-- Treesitter
require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = { "lua", "rust", "typescript", "javascript", "query", "tsx" },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
      },
      selection_modes = {
        ['@function.outer'] = 'v',
        ['@function.inner'] = 'v',
      },
    },
  },
})

-- Autocompletion
local cmp = require('cmp')
local luasnip = require('luasnip')
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
    keyword_length = 1,
  },
})

-- Autopairs
require('nvim-autopairs').setup()
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

-- Diagnostics
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- nvim-tree
require('nvim-tree').setup({
  actions = { open_file = { quit_on_open = true } },
})

-- Telescope
require('telescope').setup({
  pickers = {
    find_files = {
      find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
    },
  },
})







local format_augroup = vim.api.nvim_create_augroup("LspFormat", { clear = true })

local function on_attach(client, bufnr)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'K',  vim.lsp.buf.hover, opts)
  if client.server_capabilities and client.server_capabilities.documentFormattingProvider then
    -- ensure any existing buffer-local autocommands from this group are cleared
    vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = format_augroup,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end,
    })
  end
end

vim.lsp.config('rust-analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = { enable = true, command = 'clippy' },
      assist = {
        importEnforceGranularity = true,
        importPrefix = 'by_self',
      },
      imports = {
        granularity = { group = 'item' },
        prefix = 'self',
      },
    },
  },
})

vim.lsp.enable('rust-analyzer')


-- TypeScript (via typescript-tools)
require("typescript-tools").setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Keymaps
local keymap = function(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { noremap = true, silent = true }, opts or {}))
end
keymap('i', 'jk', '<Esc>')
keymap('i', '<C-h>', '<Left>')
keymap('i', '<C-l>', '<Right>')
keymap('i', '<C-j>', '<Down>')
keymap('i', '<C-k>', '<Up>')
keymap('n', '<C-n>', ':NvimTreeToggle<CR>')
keymap('n', '<leader>ff', ':Files<CR>')
keymap('n', '<leader>fg', ':Rg<CR>')
keymap('n', '<C-p>', function()
  require('telescope.builtin').find_files({
    find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
    attach_mappings = function(_, map)
      map('i', '<CR>', function(prompt_bufnr)
        local action_state = require('telescope.actions.state')
        local actions = require('telescope.actions')
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd('edit ' .. entry.path)
      end)
      return true
    end,
  })
end)

-- Navigation
keymap('n', '<BS>', '<C-o>')
keymap('n', '<C-o>', '<C-o>')
keymap('n', '<C-i>', '<C-i>')
keymap('n', '<C-s>', ':w<CR>')
keymap('i', '<C-s>', '<Esc>:w<CR>gi')
keymap('n', '<C-z>', 'u')
keymap('i', '<C-z>', '<C-o>u')
keymap('i', '<C-BS>', '<C-w>')

-- Disable arrow keys
local no_arrow = function()
  vim.api.nvim_echo({ { "Use h/j/k/l, not arrows.", "WarningMsg" } }, false, {})
end
for _, key in ipairs({ '<Up>', '<Down>', '<Left>', '<Right>' }) do
  keymap('n', key, no_arrow)
  keymap('i', key, no_arrow)
  keymap('v', key, no_arrow)
end

-- Rename current file
keymap('n', 'rn', function()
  local old = vim.fn.expand('%')
  local new = vim.fn.input('Rename to: ', old)
  if new ~= '' and new ~= old then
    vim.cmd('saveas ' .. new)
    vim.fn.delete(old)
    vim.cmd('bdelete ' .. old)
  end
end)

-- Delete current file
keymap('n', 'rf', function()
  local file = vim.fn.expand('%')
  if vim.fn.confirm('Delete "' .. file .. '"?', '&Yes\n&No', 2) == 1 then
    local alt = vim.fn.bufnr('#')
    vim.fn.delete(file)
    if vim.api.nvim_buf_is_valid(alt) then
      vim.cmd('buffer ' .. alt)
    end
  end
end)

-- Options
vim.opt.clipboard = 'unnamedplus'
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = false
vim.opt.undodir = vim.fn.stdpath('config') .. '/undodir'
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.o.guifont = 'monospace:h8'
