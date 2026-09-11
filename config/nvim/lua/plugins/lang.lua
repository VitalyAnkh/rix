-- nvim calls *.el `lisp`, i.e. common lisp. close, but not close enough.
vim.filetype.add({
  extension = {
    el = "elisp",
    eld = "elisp",
  },
  filename = {
    [".emacs"] = "elisp",
    ["Cask"] = "elisp",
  },
})

-- no zsh grammar, and janet's is named oddly. (elisp has none at all.)
vim.treesitter.language.register("bash", "zsh")
vim.treesitter.language.register("janet_simple", "janet")

-- zsh's language server is bashls; see plugins/lsp.lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "janet_simple" },
    },
  },
}
