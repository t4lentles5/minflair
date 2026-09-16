local M = {
  "t4lentles5/luna.nvim",
  dir = vim.fn.expand("~/Projects/luna.nvim"),
  lazy = false,
  priority = 1000,
  opts = {},
}

M.colors = setmetatable({}, {
  __index = function(_, key)
    local defaults = {
      bg = "#09080c",
      bgSecondary = "#110f19",
      fg = "#e4dff6",
      muted = "#535062",
      cyan = "#7f65cc",
      purple = "#7f65cc",
      red = "#7f65cc",
      yellow = "#7f65cc",
      blue = "#7f65cc",
      green = "#7f65cc",
    }
    if vim.g.qs_colors and vim.g.qs_colors[key] then
      return vim.g.qs_colors[key]
    end
    return defaults[key]
  end,
})

return M
