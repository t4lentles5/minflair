return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      json = { "fixjson", "prettierd", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      sh = { "shfmt" },
      qml = { "qmlformat" },
      svg = { "svg_prettierd" },
    },
    format_on_save = { timeout_ms = 500, lsp_fallback = true },
    formatters = {
      svg_prettierd = {
        command = "prettierd",
        args = function(self, ctx)
          return { ctx.filename .. ".html" }
        end,
      },
    },
  },
}
