return {
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, "Jump to next git [c]hange")
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, "Jump to previous git [c]hange")
        map("v", "<leader>gs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "git [s]tage hunk")
        map("v", "<leader>gr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "git [r]eset hunk")
        map("n", "<leader>gs", gitsigns.stage_hunk, "git [s]tage hunk")
        map("n", "<leader>gr", gitsigns.reset_hunk, "git [r]eset hunk")
        map("n", "<leader>gS", gitsigns.stage_buffer, "git [S]tage buffer")
        map("n", "<leader>gR", gitsigns.reset_buffer, "git [R]eset buffer")
        map("n", "<leader>gp", gitsigns.preview_hunk, "git [p]review hunk")
        map("n", "<leader>gb", function()
          gitsigns.blame_line({ full = true })
        end, "git [b]lame line")
        map("n", "<leader>gd", gitsigns.diffthis, "git [d]iff against index")
        map("n", "<leader>tb", gitsigns.toggle_current_line_blame, "[T]oggle git show [b]lame line")
        map({ "o", "x" }, "ih", gitsigns.select_hunk, "text object [i]nside [h]unk")
      end,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    -- lang.lua adds to this too
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "nix",
        "query",
        "vim",
        "vimdoc",
      },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      ts.install(opts.ensure_installed)

      -- the main branch doesn't highlight anything on its own
      local function attach(buf, lang)
        if not vim.treesitter.language.add(lang) or not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        vim.treesitter.start(buf, lang)
        if vim.treesitter.query.get(lang, "indents") then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      local available = ts.get_available()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter-attach", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then
            return
          end
          if vim.tbl_contains(ts.get_installed("parsers"), lang) then
            attach(args.buf, lang)
          elseif vim.tbl_contains(available, lang) then
            ts.install(lang):await(function()
              attach(args.buf, lang)
            end)
          else
            attach(args.buf, lang)
          end
        end,
      })
    end,
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
    config = function(_, opts)
      local autopairs = require("nvim-autopairs")
      autopairs.setup(opts)
      -- ' is quote in a lisp, not a delimiter
      for _, rule in ipairs(autopairs.get_rules("'") or {}) do
        rule.not_filetypes =
          vim.list_extend(rule.not_filetypes or {}, { "clojure", "elisp", "janet", "lisp", "scheme" })
      end
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        icons_enabled = vim.g.have_nerd_font,
        globalstatus = true,
        section_separators = "",
        component_separators = "",
      },
    },
  },

  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = { mappings = { around_next = "aa", inside_next = "ii" }, n_lines = 500 },
  },

  {
    -- s is flash's, so gs. visual S is surround's though.
    "nvim-mini/mini.surround",
    event = "VeryLazy",
    keys = {
      { "S", [[:<C-u>lua MiniSurround.add("visual")<CR>]], mode = "x", desc = "Add Surrounding" },
    },
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  },

  {
    "nvim-mini/mini.icons",
    lazy = true,
    enabled = vim.g.have_nerd_font,
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
    opts = {},
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 600,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { "<leader>s", group = "[S]earch", mode = { "n", "v" } },
        { "<leader>t", group = "[T]oggle" },
        { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
        { "gr", group = "LSP Actions", mode = { "n" } },
      },
    },
  },

  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
  },

  { "NMAC427/guess-indent.nvim", event = "VeryLazy", opts = {} },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",
    opts = {
      indent = {
        char = "│", -- the default ▎ is a quarter block, which reads as 2px
        highlight = { "IblIndent1", "IblIndent2", "IblIndent3", "IblIndent4" },
      },
    },
    init = function()
      -- colors/matugen.lua defines the shades; one shade for anything else
      local function fallback()
        for i = 1, 4 do
          vim.api.nvim_set_hl(0, "IblIndent" .. i, { link = "IblIndent", default = true })
        end
      end
      vim.api.nvim_create_autocmd("ColorScheme", { callback = fallback })
      fallback()
    end,
  },

  {
    -- no elisp grammar, so no rainbow there; janet and the rest are fine
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- it only hooks FileType, so be early
  },
}
