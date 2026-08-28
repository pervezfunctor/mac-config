-- if true then return {} end

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
local theme = require "theme"

return {
  -- Add the community repository of plugin specifications
  "AstroNvim/astrocommunity",
  -- example of importing a plugin
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  theme.plugin,
  {
    "AstroNvim/astroui",
    opts = { colorscheme = theme.colorscheme },
  },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.pack.lua" },
  -- { import = "astrocommunity.pack.rust" },
  -- { import = "astrocommunity.pack.cpp" },
  -- { import = "astrocommunity.pack.python" },
}
