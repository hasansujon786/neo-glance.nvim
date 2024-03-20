---@class NeoGlanceUiWinbarSectin
---@field name string
---@field hl string

---@class NeoGlanceUiWinbar
---@field winnr number
---@field sections NeoGlanceUiWinbarSectin[]
---@field last_values NeoGlanceUiWinbarSectin[]
local Winbar = {}
Winbar.__index = Winbar

---@param winnr number
---@param sections NeoGlanceUiWinbarSectin[]
---@return table
function Winbar:new(winnr, sections)
  local scope = { sections = sections, winnr = winnr, last_values = {} }
  setmetatable(scope, self)
  return scope
end

function Winbar:render(section_values)
  if vim.deep_equal(section_values, self.last_values) then
    return
  end

  local winbar_value = ''
  for _, value in ipairs(self.sections) do
    winbar_value = string.format('%s%%#%s# %s', winbar_value, value.hl, section_values[value.name])
  end

  self.last_values = section_values
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(self.winnr) then
      vim.api.nvim_win_set_option(self.winnr, 'winbar', winbar_value)
    end
  end)
end

return Winbar
