return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown() } },
      })
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")

      local builtin = require("telescope.builtin")
      local function map(lhs, rhs, desc, mode)
        vim.keymap.set(mode or "n", lhs, rhs, { desc = desc })
      end

      -- Doom Emacs-esque leader keybinds
      map("<leader><leader>", builtin.find_files, "[S]earch [F]iles")

      map("<leader>sh", builtin.help_tags, "Search Help")
      map("<leader>sk", builtin.keymaps, "Search Keymaps")
      map("<leader>ff", builtin.find_files, "Search Files")
      map("<leader>ss", builtin.builtin, "Search Select Telescope")
      map("<leader>*",  builtin.grep_string, "Search current Word", { "n", "v" })
      map("<leader>sp", builtin.live_grep, "Search Project")
      map("<leader>sd", builtin.diagnostics, "Search Diagnostics")
      map("<leader>'",  builtin.resume, "Resume")
      map("<leader>fr", builtin.oldfiles, 'Recent Files ("." for repeat)')
      map("<leader>sc", builtin.commands, "Search Commands")
      map("<leader>,",  builtin.buffers, "Find existing buffers")
      map("<leader>bb", builtin.buffers, "Find existing buffers")
      map("<leader>s/", function()
        builtin.live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" })
      end, "Search in Open Files")
      map("<leader>fe", function()
        builtin.find_files({ cwd = "~/.config/emacs", follow = true })
      end, "Search Emacs config")
      map("<leader>fv", function()
        builtin.find_files({ cwd = vim.g.dotfiles_nvim or vim.fn.stdpath("config"), follow = true })
      end, "Search Neovim config")

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
        callback = function(event)
          local function lmap(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
          end
          lmap("grr", builtin.lsp_references, "[G]oto [R]eferences")
          lmap("gri", builtin.lsp_implementations, "[G]oto [I]mplementation")
          lmap("grd", builtin.lsp_definitions, "[G]oto [D]efinition")
          lmap("grt", builtin.lsp_type_definitions, "[G]oto [T]ype Definition")
          lmap("gO", builtin.lsp_document_symbols, "Open Document Symbols")
          lmap("gW", builtin.lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
        end,
      })
    end,
  },
}
