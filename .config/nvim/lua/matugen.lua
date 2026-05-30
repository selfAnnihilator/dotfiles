local M = {}

function M.setup()
  require("base16-colorscheme").setup({
    -- Background tones
    base00 = "#1a1a1a", -- Default Background
    base01 = "#333333", -- Lighter Background (status bars)
    base02 = "#2e2e2e", -- Selection Background
    base03 = "#696969", -- Comments, Invisibles
    -- Foreground tones
    base04 = "#b6afaf", -- Dark Foreground (status bars)
    base05 = "#f3f2f2", -- Default Foreground
    base06 = "#f3f2f2", -- Light Foreground
    base07 = "#f3f2f2", -- Lightest Foreground
    -- Accent colors
    base08 = "#fd4663", -- Variables, XML Tags, Errors
    base09 = "#5af1f1", -- Integers, Constants
    base0A = "#d65c5c", -- Classes, Search Background
    base0B = "#7aecec", -- Strings, Diff Inserted
    base0C = "#81e5e5", -- Regex, Escape Chars
    base0D = "#cc6666", -- Functions, Methods
    base0E = "#e46767", -- Keywords, Storage
    base0F = "#900017", -- Deprecated, Embedded Tags
  })
end
--[[
primary: #e46767
on_primary: #251818
primary_container: #8d0c0c
on_primary_container: #e6e6e6
primary_fixed: #f4bebe
primary_fixed_dim: #ec9393
on_primary_fixed: #2c2121
on_primary_fixed_variant: #3b2b2b

secondary: #d65c5c
on_secondary: #251818
secondary_container: #6f1010
on_secondary_container: #e6e6e6
secondary_fixed: #f4bebe
secondary_fixed_dim: #e99696
on_secondary_fixed: #2c2121
on_secondary_fixed_variant: #3b2b2b

tertiary: #cc6666
on_tertiary: #251818
tertiary_container: #691616
on_tertiary_container: #e6e6e6
tertiary_fixed: #f4bebe
tertiary_fixed_dim: #e99696
on_tertiary_fixed: #2c2121
on_tertiary_fixed_variant: #3b2b2b

error: #fd4663
on_error: #251818
error_container: #900017
on_error_container: #fecdd4

surface: #1f1f1f
on_surface: #f3f2f2
surface_variant: #292929
on_surface_variant: #b6afaf
surface_dim: #141414
surface_bright: #3d3d3d
surface_container_lowest: #0f0f0f
surface_container_low: #1a1a1a
surface_container: #333333
surface_container_high: #2e2e2e
surface_container_highest: #383838

outline: #696969
outline_variant: #696969
shadow: #1f1f1f
scrim: #000000

inverse_surface: #e8e3e3
inverse_on_surface: #282424
inverse_primary: #993333

background: #1f1f1f
on_background: #f3f2f2

hued: #e4cf67
invert: #1b9898
invert: #29a3a3
invert: #339999
--]]
-- Register a signal handler for SIGUSR1 (matugen updates)
local signal = vim.uv.new_signal()
signal:start(
  "sigusr1",
  vim.schedule_wrap(function()
    package.loaded["matugen"] = nil
    require("matugen").setup()
  end)
)

return M
