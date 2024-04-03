local Layout = require('nui.layout')
local Popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

local Actions = require('neo_glance.actions')
local List = require('neo_glance.ui.list')
local Preview = require('neo_glance.ui.preview')

---@class NeoGlanceUI
---@field config NeoGlanceConfig
local Ui = {}
Ui.__index = Ui

---@param config NeoGlanceConfig
function Ui:init(config)
  Actions:init(config)

  return setmetatable({
    list = List:init({ config = config }),
    preview = Preview:init({ config = config }),
    config = config,
  }, self)
end

---@param opts UiRenderOpts
---@param node_extractor NeoGlanceNodeExtractor
function Ui:render(opts, node_extractor)
  self.list_pop = Popup(self.list:get_popup_opts(opts.list_opts))
  self.preview_pop = Popup(self.preview:get_popup_opts(opts.preview_opts))

  self.layout = Layout(
    {
      relative = 'win',
      position = { col = 0, row = 1 },
      size = { width = '100%', height = 20 },
    },
    Layout.Box({
      Layout.Box(self.preview_pop, { grow = 1 }),
      Layout.Box(self.list_pop, { size = { width = 50 } }),
    }, { dir = 'row' })
  )

  self.layout:mount()
  local exit_layout = function()
    self.layout:unmount()
  end
  self.preview_pop:on(event.WinClosed, exit_layout, { once = true })
  self.list_pop:on(event.WinClosed, exit_layout, { once = true })

  local augroup = vim.api.nvim_create_augroup('NeoGlance', { clear = true })

  local nodes, first_child = node_extractor(opts.locations)
  self:render_list(nodes, opts)

  self:render_preview(first_child, true, opts)

  Actions:create({
    list = self.list,
    preview = self.preview,
    preview_popup = self.preview_pop,
    list_popup = self.list_pop,
  })
end

---@param nodes NuiTree.Node[]
---@param opts UiRenderOpts
function Ui:render_list(nodes, opts)
  self.list = List:create({
    nodes = nodes,
    winid = self.list_pop.winid,
    bufnr = self.list_pop.bufnr,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
  })
  self.list:setup()
end

---@param location_item NeoGlanceLocation|NeoGlanceLocationItem|nil
---@param initial? boolean
function Ui:render_preview(location_item, initial, opts)
  self.preview = Preview:create({
    winid = self.preview_pop.winid,
    bufnr = self.preview_pop.bufnr,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
  })
  self.preview:update_buffer(location_item, initial)
end

---@param config NeoGlanceConfig
function Ui:configure(config)
  self.preview:configure(config)
  self.list:configure(config)
  Actions:configure(config)
  self.config = config
end

return Ui
