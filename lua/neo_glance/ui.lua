local Actions = require('neo_glance.actions')
local Layout = require('nui.layout')
local NuiLine = require('nui.line')
local NuiTree = require('nui.tree')
local Popup = require('nui.popup')

local List = require('neo_glance.ui.list')
local _g_util = require('_glance.utils')

local api = vim.api
local event = require('nui.utils.autocmd').event
local util = require('neo_glance.util')
local anchor = { 'NW', 'NE', 'SW', 'SE' }

---@class NeoGlanceUI
-----@field win_id number
-----@field bufnr number
---@field settings NeoGlanceUiSettings
---@field mappings table
local Ui = {}
Ui.__index = Ui

---@param settings NeoGlanceUiSettings
---@param mappings table
function Ui:new(settings, mappings)
  return setmetatable({
    list = List:new({ bufnr = 0, winid = 0 }),
    settings = settings,
    mappings = mappings,
  }, self)
end

---@param opts UiRenderOpts
---@param node_extractor NeoGlanceNodeExtractor
function Ui:render(opts, node_extractor)
  local list_conf = util.merge(self.settings.list, opts.list_opts or {})
  local preview_conf = util.merge(self.settings.preview, opts.preview_opts or {})

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

  local nodes, first_child = node_extractor(opts.locations)
  self:render_list(nodes, opts)

  self:update_preview(first_child, true)
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
        line:append(node:is_expanded() and ' ' or ' ', 'SpecialChar')
      else
        line:append('  ')
      end

      line:append(node.text)

      return line
    end,
  })

  tree:render()
  self.list = List:new({
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
    winid = self.list_pop.winid,
    bufnr = self.list_pop.bufnr,
    popup = self.list_pop,
    preview_popup = self.preview_pop,
    tree = tree,
  })
  Actions:setup({ list = self.list, ui = self })
  self.list:setup_list_keymaps(self)
end

---@param location_item NeoGlanceLocation|NeoGlanceLocationItem
function Ui:setup_preview_keymaps(location_item)
  local list_winid = self.list_pop.winid
  local preview_winid = self.preview_pop.winid

  local preview_keymaps = {
    ['<leader>l'] = function()
      api.nvim_set_current_win(list_winid)
    end,
  }

  local keymap_opts = {
    buffer = location_item.bufnr,
    noremap = true,
    nowait = true,
    silent = true,
  }

  for key, action in pairs(preview_keymaps) do
    vim.keymap.set('n', key, action, keymap_opts)
  end

  return preview_keymaps
end

---@param location_item NeoGlanceLocation|NeoGlanceLocationItem|nil
---@param initial? boolean
function Ui:update_preview(location_item, initial)
  if not location_item or not location_item.is_group_item then
    return nil
  end
  if self.current_location ~= nil and vim.deep_equal(self.current_location, location_item) then
    return
  end
  initial = initial or false
  local winid = self.preview_pop.winid

  api.nvim_win_set_buf(winid, location_item.bufnr)
  api.nvim_win_set_cursor(winid, { location_item.start_line + 1, location_item.start_col })
  api.nvim_win_call(winid, function()
    vim.cmd('norm! zv')
    vim.cmd('norm! zz')
  end)

  if not initial and self.current_location ~= nil and self.current_location.bufnr == location_item.bufnr then
    self.current_location = location_item -- exit if buffer but update cursor
    return
  end
  self.current_location = location_item -- got a new item

  _g_util.win_set_options(winid, self.settings.preview.win_options)
  local preview_keymaps = self:setup_preview_keymaps(location_item)

  local augroup = api.nvim_create_augroup('neo-glance-preview', { clear = true })
  local autocmd_id
  autocmd_id = api.nvim_create_autocmd({ event.WinClosed }, {
    group = augroup,
    buffer = location_item.bufnr,
    callback = function()
      self:on_detach_preview_buffer(location_item.bufnr, preview_keymaps)
    end,
  })
  self.clear_preview_autocmd = function()
    pcall(api.nvim_del_autocmd, autocmd_id)
    -- if on_change_timer then
    --   on_change_timer:close()
    --   on_change_timer = nil
    -- end
  end
end

function Ui:on_detach_preview_buffer(bufnr, preview_keymaps)
  if type(self.clear_autocmd) == 'function' then
    self.clear_autocmd()
    self.clear_autocmd = nil
  end

  if bufnr ~= nil and api.nvim_buf_is_valid(bufnr) then
    for lhs, _ in pairs(preview_keymaps) do
      pcall(api.nvim_buf_del_keymap, bufnr, 'n', lhs)
    end
  end
end

---@param settings NeoGlanceUiSettings
---@param mappings table
function Ui:configure(settings, mappings)
  self.settings = settings
  self.mappings = mappings
end

return Ui
