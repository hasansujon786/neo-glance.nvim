local Lsp = {}
Lsp.__index = Lsp

---@param ui table
function Lsp:new(ui)
  return setmetatable({
    -- win_id = nil,
    -- bufnr = nil,
    -- active_list = nil,
    ui = ui,
  }, self)
end

---@param ui table
function Lsp:configure(ui)
  self.ui = ui
end
-- Ui:configure({ foo = 'moobar' })

return Lsp
