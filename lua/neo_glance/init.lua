local Config = require('neo_glance.config')
local Lsp = require('neo_glance.lsp')
local Ui = require('neo_glance.ui')

---@class NeoGlance
---@field config NeoGlanceConfig
---@field ui NeoGlanceUI
---@field lsp Lsp
---@field hooks_setup boolean
local NeoGlance = {}
NeoGlance.__index = NeoGlance

---@return NeoGlance
function NeoGlance:new()
  local config = Config.get_default_config()

  local ui = Ui:new(config.settings)
  return setmetatable({
    config = config,
    hooks_setup = false,

    ui = ui,
    lsp = Lsp:new(ui),
  }, self)
end

local _neo_glance = NeoGlance:new()

---NeoGlance setup
---@param new_config? NeoGlanceUserConfig
---@return NeoGlance
function NeoGlance:setup(new_config)
  if self ~= _neo_glance then
    self = _neo_glance
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
function NeoGlance:open(method)
  method = method or 'textDocument/references'
  self.lsp:references(method)
end

return _neo_glance
