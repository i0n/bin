return {
  {
    "stevearc/aerial.nvim",
    opts = function(_, opts)
      -- Neovim 0.12 changed Tree-sitter match/capture behavior in ways Aerial's
      -- treesitter backend does not currently tolerate. Keep Aerial enabled, but
      -- prefer stable backends until upstream catches up.
      opts.backends = { "lsp", "markdown", "man" }
      return opts
    end,
  },
}
