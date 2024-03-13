local Input = require('nui.input')
local Layout = require('nui.layout')
local Menu = require('nui.menu')
local NuiLine = require('nui.line')
local NuiTree = require('nui.tree')
local Popup = require('nui.popup')
local Text = require('nui.text')

local List = require('neo_glance.ui.list')
local _g_util = require('_glance.utils')

local api = vim.api
local event = require('nui.utils.autocmd').event
local async = require('plenary.async')
local util = require('neo_glance.util')
local anchor = { 'NW', 'NE', 'SW', 'SE' }

---@class NeoGlanceUI
-----@field win_id number
-----@field bufnr number
---@field settings NeoGlanceUiSettings
local Ui = {}
Ui.__index = Ui

local map_opt = { noremap = true, nowait = true }

---@param settings NeoGlanceUiSettings
function Ui:new(settings)
  return setmetatable({
    -- win_id = nil,
    -- bufnr = nil,
    -- active_list = nil,
    settings = settings,
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
  self:setup_list_keymaps(tree)

  vim.defer_fn(function()
    api.nvim_set_current_win(self.list_pop.winid)
  end, 50)
end

---@param tree NuiTree
function Ui:setup_list_keymaps(tree)
  local list_pop = self.list_pop
  local preview_winid = self.preview_pop.winid
  local list = List:new({ winid = list_pop.winid, bufnr = list_pop.bufnr, tree = tree })

  -- focus preview
  list_pop:map('n', '<leader>h', function()
    api.nvim_set_current_win(self.preview_pop.winid)
  end, map_opt)

  -- quit
  list_pop:map('n', 'q', function()
    list_pop:unmount()
  end, map_opt)

  ---@param opts {start:number,cycle?:boolean,backwards?:boolean}
  local function move(opts)
    local start_node = tree:get_node(opts.start)
    local line_count = vim.api.nvim_buf_line_count(self.list_pop.bufnr)
    local idx = opts.start + (opts.backwards and -1 or 1)
    local col = list:get_col()

    if opts.cycle then
      idx = ((idx - 1) % line_count) + 1
    end

    local node, linenr = tree:get_node(idx)
    if not node or idx > line_count then
      return nil
    end

    -- Fixup cursor col position
    if start_node and col > 0 then
      if start_node:has_children() and not node:has_children() then
        col = col - 2
      elseif not start_node:has_children() and node:has_children() then
        col = col + 2
      end
    end

    vim.api.nvim_win_set_cursor(list.winid, { idx, col })
    if node:has_children() then
      return -- don't update preview if it is a group
    end
    self:update_preview(node.data)
  end

  list_pop:map('n', 'j', function()
    local node = list:next({ cycle = false })
    if node then
      self:update_preview(node.data)
    end
  end, map_opt)
  list_pop:map('n', 'k', function()
    local node = list:previous({ cycle = false })
    if node then
      self:update_preview(node.data)
    end
  end, map_opt)

  list_pop:map('n', '<tab>', function()
    local node = list:next({ cycle = true, skip_groups = true })
    if node then
      self:update_preview(node.data)
    end
  end, map_opt)

  list_pop:map('n', '<s-tab>', function()
    local node = list:previous({ cycle = true, skip_groups = true })
    if node then
      self:update_preview(node.data)
    end
  end, map_opt)

  list_pop:map('n', 'o', function()
    local node = tree:get_node()
    if not node or not node.data then
      return
    end
    local locations = node.data

    -- TODO: get parent winid
    api.nvim_set_current_win(preview_winid)
    api.nvim_win_set_cursor(preview_winid, { locations.start_line + 1, locations.start_col })
    api.nvim_win_call(preview_winid, function()
      vim.cmd('norm! zv')
      vim.cmd('norm! zz')
    end)
  end, map_opt)

  --------------------------------------------------
  -- NuiTree mappings ------------------------------
  --------------------------------------------------

  -- print current node
  list_pop:map('n', '<CR>', function()
    local node = tree:get_node()
    _G.foo = node
    -- print(vim.inspect(node))
  end, map_opt)

  -- collapse current node
  list_pop:map('n', 'h', function()
    local node = tree:get_node()

    if node:collapse() then
      tree:render()
    end
  end, map_opt)

  -- collapse all nodes
  list_pop:map('n', 'H', function()
    local updated = false

    for _, node in pairs(tree.nodes.by_id) do
      updated = node:collapse() or updated
    end

    if updated then
      tree:render()
    end
  end, map_opt)

  -- expand current node
  list_pop:map('n', 'l', function()
    local node = tree:get_node()

    if node:expand() then
      tree:render()
    end
  end, map_opt)

  -- expand all nodes
  list_pop:map('n', 'L', function()
    local updated = false

    for _, node in pairs(tree.nodes.by_id) do
      updated = node:expand() or updated
    end

    if updated then
      tree:render()
    end
  end, map_opt)

  -- add new node under current node
  list_pop:map('n', 'a', function()
    local node = tree:get_node()
    tree:add_node(
      NuiTree.Node({ text = 'd' }, {
        NuiTree.Node({ text = 'd-1' }),
      }),
      node:get_id()
    )
    tree:render()
  end, map_opt)

  -- delete current node
  list_pop:map('n', 'd', function()
    local node = tree:get_node()
    tree:remove_node(node:get_id())
    tree:render()
  end, map_opt)
end

---@param location_item NeoGlanceLocationItem
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

---@param location_item NeoGlanceLocationItem|nil
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
function Ui:configure(settings)
  self.settings = settings
end

return Ui
