local Config = require('peep.config')
local Ui = require('peep.ui')
local Lsp = require('peep.lsp')

---@class Peep
---@field config PeepConfig
---@field ui PeepUI
---@field lsp Lsp
---@field hooks_setup boolean
local Peep = {}
Peep.__index = Peep

---@return Peep
function Peep:new()
  local config = Config.get_default_config()

  local ui = Ui:new(config.settings)
  return setmetatable({
    config = config,
    hooks_setup = false,

    ui = ui,
    lsp = Lsp:new(ui),
  }, self)
end

local _peep = Peep:new()

---Peep setup
---@param new_config? PeepUserConfig
---@return Peep
function Peep:setup(new_config)
  if self ~= _peep then
    self = _peep
  end

  if new_config ~= nil then
    self.corfig = Config.merge_config(new_config, self.config)
  end
  self.ui:configure(self.config.settings)
  self.lsp:configure(self.ui)

  return self
end

-- 'textDocument/definition',
---@param method? string
function Peep:open(method)
  method = method or 'textDocument/references'
  self.lsp:references(method)
end

return _peep
