return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { styles = { comments = { italic = false } } },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      -- matugen's palette if it's been rendered, else tokyonight
      if not pcall(vim.cmd.colorscheme, "matugen") then
        vim.cmd.colorscheme("tokyonight-night")
      end
    end,
  },
}
