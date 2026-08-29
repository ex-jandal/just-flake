return {
  {
    "CRAG666/code_runner.nvim",
    lazy = false,
    config = function ()
      require('code_runner').setup({
        filetype = {
          java = {
            -- "cd $dir &&",
            "echo $dir ' - ' $rootdir \\n &&",
            -- "cd $rootdir &&",
            "gradle run -q",
            -- "javac $fileName &&",
            -- "java $fileNameWithoutExt.class",
          },
          python = "python3 -u",
          typescript = "node run",
          rust = {
            "cd $dir &&",
            "cargo r",
            -- "cat /tmp/$fileNameWithoutExt"
          },
          c = "cd $dir && gcc $fileName -o /tmp/$fileNameWithoutExt && /tmp/$fileNameWithoutExt",
        },
      })
    end
  },
}
