local function is_empty_buffer(bufnr)
  if vim.api.nvim_buf_get_name(bufnr) ~= "" then return false end
  if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then return false end
  if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then return false end
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines > 1 or (#lines == 1 and lines[1] ~= "") then return false end
  
  return true
end

vim.api.nvim_create_autocmd("BufHidden", {
  desc = "Delete empty [No Name] buffers when hidden",
  callback = function(event)
    if is_empty_buffer(event.buf) then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(event.buf) and vim.fn.bufwinnr(event.buf) < 0 then
          pcall(vim.api.nvim_buf_delete, event.buf, {})
        end
      end)
    end
  end,
})
