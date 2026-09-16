vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true

opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true

opt.splitright = true
opt.splitbelow = true

opt.clipboard = "unnamedplus"

-- Spelling
opt.spelllang = { "en", "es" }
opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
opt.spell = true

-- Hide ~ at the end of buffer
opt.fillchars = { eob = " " }

-- Persistent undo
opt.undofile = true

-- Scroll context
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Decrease update times
opt.updatetime = 250
opt.timeoutlen = 300
