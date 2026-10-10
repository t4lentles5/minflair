local M = {}

local theme_file = vim.fn.expand("~/.cache/quickshell/nvim_theme.lua")

function M.load_theme()
  if vim.fn.filereadable(theme_file) == 1 then
    -- Source the file which contains vim.cmd.colorscheme and vim.opt.background
    package.loaded["luna.palette"] = nil
    package.loaded["luna.palette_dark"] = nil
    package.loaded["luna.palette_light"] = nil
    package.loaded["luna.highlights"] = nil
    package.loaded["lualine.themes.luna"] = nil
    vim.cmd("luafile " .. theme_file)

    -- Sincronizar Lualine con el tema nativo de luna
    local has_lualine, lualine = pcall(require, "lualine")
    if has_lualine then
      package.loaded["lualine.themes.luna"] = nil
      lualine.setup({ options = { theme = "luna" } })
    end
  end
end

function M.setup()
  -- Initial load on startup
  M.load_theme()

  -- Setup file watcher
  local uv = vim.uv or vim.loop
  local watch_path = vim.fn.expand("~/.cache/quickshell")

  -- Ensure directory exists
  if vim.fn.isdirectory(watch_path) == 0 then
    vim.fn.mkdir(watch_path, "p")
  end

  local handle = uv.new_fs_event()
  if handle then
    uv.fs_event_start(
      handle,
      watch_path,
      {},
      vim.schedule_wrap(function(err, filename, events)
        if err then
          return
        end

        -- If the theme file was changed or created, reload it
        if filename == "nvim_theme.lua" then
          M.load_theme()
        end
      end)
    )
  end
end

return M
