local Actions = require('neo_glance.actions')
local Config = require('neo_glance.config')
local Layout = require('nui.layout')
local NuiLine = require('nui.line')
local NuiTree = require('nui.tree')
local Popup = require('nui.popup')

local List = require('neo_glance.ui.list')
local Preview = require('neo_glance.ui.preview')

local event = require('nui.utils.autocmd').event
local util = require('neo_glance.util')

---@class NeoGlanceUI
---@field config NeoGlanceConfig
local Ui = {}
Ui.__index = Ui

---@type NeoGlancePopupOpts
local popup_opts = {
  list = {},
  preview = {},
}

---@param config NeoGlanceConfig
function Ui:init(config)
  Actions:init(config)
  popup_opts = Config.get_popup_opts(config)

  return setmetatable({
    list = List:init({ config = config }),
    preview = Preview:init({ config = config }),
    config = config,
  }, self)
end

---@param opts UiRenderOpts
---@param node_extractor NeoGlanceNodeExtractor
function Ui:render(opts, node_extractor)
  local list_conf = util.merge(popup_opts.list, opts.list_opts or {})
  local preview_conf = util.merge(popup_opts.preview, opts.preview_opts or {})

  self.list_pop = Popup(list_conf)
  self.preview_pop = Popup(preview_conf)

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

---@param nodes table
---@param opts UiRenderOpts
function Ui:render_list(nodes, opts)
  local tree = NuiTree({
    bufnr = self.list_pop.bufnr,
    -- winid = split.winid,
    nodes = nodes,
    prepare_node = function(node)
      local line = NuiLine()

      line:append(string.rep('  ', node:get_depth() - 1))

      if node:has_children() then
        -- TODO: fix cursor col position while navigating
        line:append(node:is_expanded() and '  ' or '  ', 'SpecialChar')
      else
        line:append('  ')
      end

      line:append(node.text)

      return line
    end,
  })

  tree:render()
  self.list = List:create({
    tree = tree,
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
  Actions:configure(config)
  self.config = config
  popup_opts = Config.get_popup_opts(config)
end

return Ui
