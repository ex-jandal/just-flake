vim.keymap.set("n", "<leader>ln", function()
  require("lint").try_lint()
end, { desc = "Run linter" })

vim.keymap.set("n", "<leader>rl", function()
  vim.cmd("!nasm -f elf64 % -o %:r.o && ld %:r.o -o %:r && ./%:r")
end, { desc = "Assemble & run" })

return {
  {
    "mfussenegger/nvim-lint",
    lazy = false,
    -- optional = true,
    opts = {
      linters_by_ft = {
        dockerfile = { "hadolint" },
        linuxtype = { "shellcheck" },
        sh = { "shellcheck" },
        zig = { "zlint" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")

      -- Merge your opts with custom asm config
      lint.linters_by_ft = vim.tbl_extend("force", opts.linters_by_ft or {}, {
        asm = { "nasm" },
      })

      -- Define nasm linter
      lint.linters.nasm = {
        cmd = "nasm",
        stdin = false,
        args = { "-f", "elf64" }, -- ensures 64-bit mode
        stream = "stderr",
        ignore_exitcode = true,
        parser = require("lint.parser").from_errorformat(
          "%f:%l: %m",
          {
            source = "nasm",
            severity = vim.diagnostic.severity.ERROR,
          }
        ),
      }

      -- Run lint on save
      vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  }
}
