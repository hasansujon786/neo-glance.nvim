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
function NeoGlance:init()
  local config = Config.get_default_config()

  local ui = Ui:init(config)
  return setmetatable({
    config = config,
    hooks_setup = false,

    ui = ui,
    lsp = Lsp:new(ui),
  }, self)
end

local _neo_glance = NeoGlance:init()

---NeoGlance setup
---@param new_config? NeoGlanceUserConfig
---@return NeoGlance
function NeoGlance.setup(new_config)
  if new_config ~= nil then
    _neo_glance.config = Config.merge_config(new_config, _neo_glance.config)
    _neo_glance.ui:configure(_neo_glance.config)
    _neo_glance.lsp:configure(_neo_glance.ui)
  end

  return _neo_glance
end

-- 'textDocument/definition',
---@param method? string
function NeoGlance:open(method)
  method = method or 'textDocument/references'
  self.lsp:references(method)
end

return _neo_glance
