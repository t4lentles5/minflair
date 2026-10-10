return {
  "tjgao/quickbuf.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local quickbuf = require("quickbuf")

    local function get_opts()
      local colors = require("plugins.colorscheme").colors
      return {
        picker = {
          include_special = false,
          auto_jump_single = false,
          isolate_keymaps = true,
          fuzzy_key = "/",
          fuzzy_backend = "telescope",
          alternate_key = "<Tab>",
          alternate_key_display = "⇄",
          alternate_without_label = true,
          label_before_name = true,
          move_up_key = "<Up>",
          move_down_key = "<Down>",
          show_icons = true,
          pin_display = "📌",
        },
        persistence = {
          enabled = true,
          debounce_ms = 5000,
        },
        highlights = {
          border = { fg = colors.accent },
          label = { fg = colors.accent, bold = true },
          pinned = { fg = colors.accent, bold = true },
          flags = { fg = colors.muted },
          alternate = { fg = colors.accentComplementary, bold = true },
          filename = { fg = colors.fg },
          path = { fg = colors.muted, italic = true },
          muted = { fg = colors.muted },
          cursorline = { bg = colors.bgSecondary },
          footer_svt = { fg = colors.accentComplementary },
        },
        window = {
          border = "rounded",
          width = 0.6,
          height = 0.5,
          max_width = 80,
          min_width = 36,
          padding = 2,
          vertical_padding = 1,
        },
      }
    end

    -- Initial setup
    quickbuf.setup(get_opts())

    -- Update highlights dynamically when colorscheme changes
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("QuickBufColorsSync", { clear = true }),
      callback = function()
        quickbuf.setup(get_opts())
      end,
    })
  end,
}
