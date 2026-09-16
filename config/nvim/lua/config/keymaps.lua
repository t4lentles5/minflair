local keymap = vim.keymap

-- General Keymaps
keymap.set("n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear search highlights" })
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half a page (centered)" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half a page (centered)" })

-- Window Navigation
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
keymap.set("n", "<A-Left>", "<C-w>h", { desc = "Go to left window" })
keymap.set("n", "<A-Down>", "<C-w>j", { desc = "Go to lower window" })
keymap.set("n", "<A-Up>", "<C-w>k", { desc = "Go to upper window" })
keymap.set("n", "<A-Right>", "<C-w>l", { desc = "Go to right window" })

keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- Resize Windows
keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Buffer Navigation
keymap.set("n", "<leader>x", "<cmd>Bdelete<cr>", { desc = "Close current buffer" })

-- Save File
keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })

-- Plugins
keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
keymap.set("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Toggle LazyGit" })

-- Telescope
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files (Project)" })
keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep (Project)" })


-- Spelling
keymap.set("n", "<leader>sp", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })
local add_to_dict = function()
  local word = vim.fn.expand("<cword>"):lower()
  vim.cmd("spellgood " .. word)
  print("Agregado: " .. word)
end
keymap.set("n", "zg", add_to_dict, { desc = "Add word to dictionary (lowercase)" })
keymap.set("n", "zw", "zw", { desc = "Mark word as incorrect" })
keymap.set("n", "zug", "zug", { desc = "Undo add word to dictionary" })
keymap.set("n", "zuw", "zuw", { desc = "Undo mark word as incorrect" })
keymap.set("n", "<leader>so", "<cmd>Telescope spell_suggest<cr>", { desc = "Spelling Suggestions" })

-- UI Toggles
keymap.set("n", "<leader>un", "<cmd>set nu!<CR>", { desc = "Toggle line numbers" })
keymap.set("n", "<leader>ur", "<cmd>set rnu!<CR>", { desc = "Toggle relative line numbers" })
local diagnostics_active = true
local toggle_diagnostics = function()
  diagnostics_active = not diagnostics_active
  if diagnostics_active then
    vim.diagnostic.show()
    print("Diagnostics active")
  else
    vim.diagnostic.hide()
    print("Diagnostics disabled")
  end
end
keymap.set("n", "<leader>ud", toggle_diagnostics, { desc = "Toggle diagnostics" })

-- Match
keymap.set("n", "<leader>sm", "<cmd>MatchWord<cr>", { desc = "Search & Replace (word under cursor)" })
keymap.set("n", "<leader>sl", "<cmd>MatchLine<cr>", { desc = "Search & Replace (current line)" })

-- Trouble
keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
keymap.set(
  "n",
  "<leader>xX",
  "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { desc = "Buffer Diagnostics (Trouble)" }
)
keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
keymap.set(
  "n",
  "<leader>cl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP Definitions / references / ... (Trouble)" }
)
keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- Markdown Render
keymap.set("n", "<leader>mp", "<Plug>(md-render-preview)", { desc = "Markdown preview (toggle)" })
keymap.set("n", "<leader>mt", "<Plug>(md-render-preview-tab)", { desc = "Markdown preview in tab (toggle)" })
keymap.set("n", "<leader>md", "<Plug>(md-render-demo)", { desc = "Markdown render demo" })

-- Better Indenting
keymap.set("v", "<", "<vgv", { desc = "Indent out" })
keymap.set("v", ">", ">gv", { desc = "Indent in" })

-- Move Lines (Ctrl + Alt + Up/Down)
keymap.set("n", "<C-A-Down>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
keymap.set("n", "<C-A-Up>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
keymap.set("i", "<C-A-Down>", "<esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
keymap.set("i", "<C-A-Up>", "<esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })
keymap.set("v", "<C-A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap.set("v", "<C-A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Search Centering
keymap.set("n", "n", "nzzzv", { desc = "Next match (centered)" })
keymap.set("n", "N", "Nzzzv", { desc = "Prev match (centered)" })

-- Paste without losing registry
keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over selection" })

-- LSP Keymaps (only when LSP is attached)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }

    keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition", buffer = ev.buf })
    keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Show references", buffer = ev.buf })
    keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation", buffer = ev.buf })
    keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol", buffer = ev.buf })
    keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action", buffer = ev.buf })

    -- Diagnostic Keymaps
    keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message", buffer = ev.buf })
    keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message", buffer = ev.buf })
    keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Open floating diagnostic message", buffer = ev.buf })
    keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list", buffer = ev.buf })
  end,
})

-- QuickBuf
keymap.set("n", "<Tab>", "<cmd>QuickBuf<CR>", { desc = "QuickBuf" })
keymap.set("n", "<leader>qt", "<cmd>QuickBufPinToggle<CR>", { desc = "Pin toggle" })
keymap.set("n", "<S-h>", "<cmd>QuickBufPrevPinned<CR>", { desc = "Prev pinned buffer" })
keymap.set("n", "<S-l>", "<cmd>QuickBufNextPinned<CR>", { desc = "Next pinned buffer" })
