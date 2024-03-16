local Actions = require('neo_glance.actions')

local _g_util = require('_glance.utils')

local api = vim.api
local event = require('nui.utils.autocmd').event
local util = require('neo_glance.util')
local anchor = { 'NW', 'NE', 'SW', 'SE' }

local api = vim.api
local map_opt = { noremap = true, nowait = true }

---@class NeoGlanceUiPreview
---@field winid number
---@field bufnr number
---@field list_popup NuiPopup
---@field preview_popup NuiPopup
---@field parent_bufnr number
---@field parent_winid number
---@field current_location NeoGlanceLocation|NeoGlanceLocationItem|nil
---@field mappings table
local Preview = {}
Preview.__index = Preview

---@param opts {winid:number,bufnr:number,list_popup:NuiPopup,preview_popup:NuiPopup,parent_bufnr:number,parent_winid:number,mappings:table}
---@return NeoGlanceUiPreview
function Preview:new(opts)
  return setmetatable({
    winid = opts.winid,
    bufnr = opts.bufnr,
    list_popup = opts.list_popup,
    preview_popup = opts.preview_popup,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
    current_location = nil,
    mappings = opts.mappings,
  }, self)
end

---@param location_item NeoGlanceLocation|NeoGlanceLocationItem|nil
---@param initial? boolean
function Preview:update_buffer(location_item, initial)
  if not location_item or not location_item.is_group_item then
    return nil
  end
  if self.current_location ~= nil and vim.deep_equal(self.current_location, location_item) then
    return
  end
  initial = initial or false
  local winid = self.preview_popup.winid

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

  -- _g_util.win_set_options(winid, self.settings.preview.win_options)
  local preview_keymaps = self:setup_preview_keymaps(location_item)

  local augroup = api.nvim_create_augroup('neo-glance-preview', { clear = true })
  local autocmd_id
  autocmd_id = api.nvim_create_autocmd({ event.WinClosed }, {
    group = augroup,
    buffer = location_item.bufnr,
    callback = function()
      -- FIXME: fire on current event
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

function Preview:on_detach_preview_buffer(bufnr, preview_keymaps)
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

---@param location_item NeoGlanceLocation|NeoGlanceLocationItem
function Preview:setup_preview_keymaps(location_item)
  local keymap_opts = {
    buffer = location_item.bufnr,
    noremap = true,
    nowait = true,
    silent = true,
  }

  for key, action in pairs(self.mappings) do
    vim.keymap.set('n', key, action, keymap_opts)
  end

  return self.mappings
end

return Preview
