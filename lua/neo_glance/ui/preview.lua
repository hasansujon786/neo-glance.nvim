local Config = require('neo_glance.config')
local Winbar = require('neo_glance.ui.winbar')

local _g_util = require('_glance.utils')

---@class NeoGlanceUiPreview
---@field winid number
---@field bufnr number
---@field parent_bufnr number
---@field parent_winid number
---@field current_location NeoGlanceLocation|NeoGlanceLocationItem|nil
---@field winbar NeoGlanceUiWinbar
local Preview = {}
Preview.__index = Preview

local touched_buffers = {}

local winhl = {
  'Normal:GlancePreviewNormal',
  'CursorLine:GlancePreviewCursorLine',
  'SignColumn:GlancePreviewSignColumn',
  'EndOfBuffer:GlancePreviewEndOfBuffer',
  'LineNr:GlancePreviewLineNr',
}

-- Fails to set winhighlight in 0.7.2 for some reason
if vim.fn.has('nvim-0.8') == 1 then
  table.insert(winhl, 'GlanceNone:GlancePreviewMatch')
end

local win_opts = {
  winfixwidth = true,
  winfixheight = true,
  cursorbind = false,
  scrollbind = false,
  winhighlight = table.concat(winhl, ','),
}
local winbar_enable = false

local float_win_opts = {
  'number',
  'relativenumber',
  'cursorline',
  'cursorcolumn',
  'foldcolumn',
  'spell',
  'list',
  'signcolumn',
  'colorcolumn',
  'fillchars',
  'winhighlight',
  'statuscolumn',
}

-- local function clear_hl(bufnr)
--   if vim.api.nvim_buf_is_valid(bufnr) then
--     vim.api.nvim_buf_clear_namespace(bufnr, config.namespace, 0, -1)
--   end
-- end

---@param opts {config:NeoGlanceConfig}
---@return NeoGlanceUiPreview
function Preview:init(opts)
  winbar_enable = opts.config.winbar.enable
  win_opts = vim.tbl_extend('keep', win_opts, opts.config.preview_win_opts or {})

  local scope = {
    winid = nil,
    bufnr = nil,
    parent_winid = nil,
    parent_bufnr = nil,
    current_location = nil,
    winbar = nil,
  }

  return setmetatable(scope, self)
end

---@param opts {winid:number,bufnr:number,parent_bufnr:number,parent_winid:number}
---@return NeoGlanceUiPreview
function Preview:create(opts)
  opts = opts or {}
  local scope = {
    winid = opts.winid,
    bufnr = opts.bufnr,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
    current_location = nil,
    winbar = nil,
  }

  if winbar_enable then
    scope.winbar = Winbar:new(opts.winid, {
      { name = 'filename', hl = 'GlanceWinBarFilename' },
      { name = 'filepath', hl = 'GlanceWinBarFilepath' },
    })
  end

  return setmetatable(scope, self)
end

---@param bufnr number
---@param keymaps table
function Preview:on_attach_buffer(bufnr, keymaps)
  if bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
    local throttled_on_change, on_change_timer = _g_util.throttle_leading(function()
      local is_active_buffer = self.current_location and bufnr == self.current_location.bufnr
      local is_listed = vim.fn.buflisted(bufnr) == 1

      if is_active_buffer and not is_listed then
        vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)
        vim.api.nvim_buf_set_option(bufnr, 'bufhidden', '')
      end
    end, 1000)

    local autocmd_id = vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
      group = 'NeoGlance',
      buffer = bufnr,
      callback = throttled_on_change,
    })

    self.clear_autocmd = function()
      pcall(vim.api.nvim_del_autocmd, autocmd_id)
      if on_change_timer then
        on_change_timer:close()
        on_change_timer = nil
      end
    end

    local keymap_opts = {
      buffer = bufnr,
      noremap = true,
      nowait = true,
      silent = true,
    }

    for key, action in pairs(keymaps) do
      vim.keymap.set('n', key, action, keymap_opts)
    end
  end
end

function Preview:on_detach_buffer(bufnr, keymaps)
  if type(self.clear_autocmd) == 'function' then
    self.clear_autocmd()
    self.clear_autocmd = nil
  end

  if bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
    for lhs, _ in pairs(keymaps) do
      pcall(vim.api.nvim_buf_del_keymap, bufnr, 'n', lhs)
    end
  end
end

function Preview:restore_win_opts()
  for opt, _ in pairs(win_opts) do
    if not vim.tbl_contains(float_win_opts, opt) then
      local value = vim.api.nvim_win_get_option(self.parent_winid, opt)
      vim.api.nvim_win_set_option(self.winid, opt, value)
    end
  end

  for _, opt in ipairs(float_win_opts) do
    local value = vim.api.nvim_win_get_option(self.parent_winid, opt)
    vim.api.nvim_win_set_option(self.winid, opt, value)
  end
end

---@param item NeoGlanceLocation|NeoGlanceLocationItem|nil
---@param initial? boolean
function Preview:update_buffer(item, initial)
  if not vim.api.nvim_win_is_valid(self.winid) then
    return
  end

  if not item or item.is_group or item.is_unreachable then
    return
  end

  if vim.deep_equal(self.current_location, item) then
    return
  end

  local current_bufnr = (self.current_location or {}).bufnr

  if current_bufnr ~= item.bufnr then
    local config = Config.get_config()
    self:restore_win_opts()
    self:on_detach_buffer(current_bufnr, config.mappings.preview)
    vim.api.nvim_win_set_buf(self.winid, item.bufnr)
    self:restore_win_opts()
    _g_util.win_set_options(self.winid, win_opts)

    if config.winbar.enable and self.winbar then
      local filename = vim.fn.fnamemodify(item.filename, ':t')
      local filepath = vim.fn.fnamemodify(item.filename, ':p:~:h')
      self.winbar:render({ filename = filename, filepath = filepath })
    end

    vim.api.nvim_buf_call(item.bufnr, function()
      if vim.api.nvim_buf_get_option(item.bufnr, 'filetype') == '' then
        vim.cmd('do BufRead')
      end
    end)

    self:on_attach_buffer(item.bufnr, config.mappings.preview)
  end

  vim.api.nvim_win_set_cursor(self.winid, { item.start_line + 1, item.start_col })

  vim.api.nvim_win_call(self.winid, function()
    vim.cmd('norm! zv')
    vim.cmd('norm! zz')
  end)

  self.current_location = item

  -- if not vim.tbl_contains(touched_buffers, item.bufnr) then
  --   for _, location in pairs(group.items) do
  --     self:hl_buf(location)
  --   end
  --   table.insert(touched_buffers, item.bufnr)
  -- end
end

---@param config NeoGlanceConfig
function Preview:configure(config)
  winbar_enable = config.winbar.enable
  win_opts = vim.tbl_extend('keep', win_opts, config.preview_win_opts or {})
end

return Preview
