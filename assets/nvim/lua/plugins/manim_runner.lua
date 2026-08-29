return {
  {
    "ahmeds0s/manim_runner.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "akinsho/toggleterm.nvim",
    },
    keys = {
      {
        "<Leader>rm",
        function()
            require("manim.render").render_scene()
        end,
        desc = "Render manim scene under cursor",
      },
    },
  }
}
