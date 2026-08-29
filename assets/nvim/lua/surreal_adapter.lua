local function M()
  -- lua/surreal_adapter.lua
  if vim.g.loaded_dadbod_surreal then
    return
  end
  vim.g.loaded_dadbod_surreal = true

  -- Delay until dadbod is available
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      if vim.fn.exists("*db#adapter#register") == 0 then
        return
      end

      vim.fn["db#adapter#register"]({
        name = "surreal",
        pattern = "^surreal://",
        format = function(url)
          -- Example: surreal://user:pass@localhost:8000/ns/db
          return url
        end,
        query = function(url, query)
          -- TODO: parse url to extract ns/db
          local cmd = {
            "surreal",
            "sql",
            "--conn", "http://localhost:8000",
            "--ns", "test",
            "--db", "test",
          }
          local full_cmd = table.concat(cmd, " ")
          return vim.fn.system(full_cmd, query)
        end,
      })
    end,
  })
end

return M
