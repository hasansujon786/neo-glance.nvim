local Config = require('neo_glance.config')
local Winbar = require('neo_glance.ui.winbar')
local _utils = require('_glance.utils')

local api = vim.api

---@class NeoGlanceUiList
---@field winid number
---@field bufnr number
---@field tree NuiTree
---@field parent_bufnr number
---@field parent_winid number
---@field winbar NeoGlanceUiWinbar
local List = {}
List.__index = List

local winbar_enable = false

---@param opts {config:NeoGlanceConfig}
---@return NeoGlanceUiList
function List:init(opts)
  winbar_enable = opts.config.winbar.enable

  local scope = {
    tree = nil,
    winid = nil,
    bufnr = nil,
    parent_winid = nil,
    parent_bufnr = nil,
    winbar = nil,
  }

  return setmetatable(scope, self)
end

---@param opts NeoGlanceUiList.Create
---@return NeoGlanceUiList
function List:create(opts)
  local scope = {
    tree = opts.tree,
    winid = opts.winid,
    bufnr = opts.bufnr,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
    winbar = nil,
  }

  if winbar_enable then
    scope.winbar = Winbar:new(opts.winid, {
      { name = 'title', hl = 'GlanceWinBarTitle' },
    })
  end

  return setmetatable(scope, self)
end

function List:get_cursor()
  return api.nvim_win_get_cursor(self.winid)
end

function List:get_line()
  return self:get_cursor()[1]
end

function List:get_col()
  return self:get_cursor()[2]
end

---@param opts { start: integer, backwards?: boolean, cycle?: boolean }
function List:walk(opts)
  local line_count = api.nvim_buf_line_count(self.bufnr)
  local idx = opts.start + (opts.backwards and -1 or 1)
  if opts.cycle then
    idx = ((idx - 1) % line_count) + 1
  end
  local node = self.tree:get_node(idx)
  if not node or idx > line_count then
    return nil
  end
  return idx, node
end

---@param opts? { skip_groups: boolean, offset: number, cycle: boolean }
---@return NeoGlanceLocation|NeoGlanceLocationItem|nil, NuiTreeNode|nil
function List:next(opts)
  opts = opts or {}
  local idx, node = self:walk({
    start = self:get_line() + (opts.offset or 0),
    cycle = opts.cycle,
  })
  if not node then
    return nil
  end
  if opts.skip_groups and node.data.is_group then
    if not node:is_expanded() and node:expand() then
      self.tree:render()
    end
    return self:next({
      offset = idx - self:get_line(), -- offset by how far we've already iterated prior to unfolding
      cycle = opts.cycle,
      skip_groups = true,
    })
  end
  if not (opts.skip_groups and node.data.is_group) then
    api.nvim_win_set_cursor(self.winid, { idx, self:get_col() })
    return node.data, node
  end
  return nil
end

---@param opts? { skip_groups: boolean, offset: number, cycle: boolean }
---@return NeoGlanceLocation|NeoGlanceLocationItem|nil, NuiTreeNode|nil
function List:previous(opts)
  opts = opts or {}
  local start = self:get_line()
  local search_from = start - 2

  local target_node = nil
  local target_idx = 0

  if opts.cycle and search_from <= 0 then
    search_from = api.nvim_buf_line_count(self.bufnr)
  end

  for i = 0, search_from, 1 do
    local idx, node = self:walk({
      start = start - i,
      cycle = opts.cycle,
      backwards = true,
    })
    if not node or not idx then
      return nil
    end

    if opts.skip_groups and node.data.is_group then
      if not node:is_expanded() and node:expand() then
        self.tree:render()
        target_idx = #node:get_child_ids() + idx
        target_node = self.tree:get_node(target_idx)
        break
      end
    else
      target_node = node
      target_idx = idx
      break
    end
  end

  if target_node and target_idx > 0 and not (opts.skip_groups and target_node.data.is_group) then
    api.nvim_win_set_cursor(self.winid, { target_idx, self:get_col() })
    return target_node.data, target_node
  end
  return nil
end

function List:toggle_fold()
  local node = self.tree:get_node()
  if not node then
    return
  end

  local updated = false
  local is_open = node:is_expanded()

  if is_open then
    updated = node:collapse() or updated
  else
    updated = node:expand() or updated
  end

  if updated then
    self.tree:render()
  end
end
function List:open_fold()
  local node = self.tree:get_node()
  if not node then
    return
  end

  if node:expand() then
    self.tree:render()
  end
end
function List:close_fold()
  local node = self.tree:get_node()
  if not node then
    return
  end

  if node:collapse() then
    self.tree:render()
  end
end
function List:collapse_all()
  local updated = false

  for _, node in pairs(self.tree.nodes.by_id) do
    updated = node:collapse() or updated
  end

  if updated then
    self.tree:render()
  end
end
function List:expand_all()
  local updated = false

  for _, node in pairs(self.tree.nodes.by_id) do
    updated = node:expand() or updated
  end

  if updated then
    self.tree:render()
  end
end

local function get_lsp_method_label(method_name)
  return _utils.capitalize('references')
  -- return _utils.capitalize(lsp.methods[method_name].label)
end

function List:setup()
  -- TODO: get lsp method_name and lenght
  self.winbar:render({
    title = string.format('%s (%d)', get_lsp_method_label(), 23),
  })

  self:setup_list_keymaps()
end

function List:setup_list_keymaps()
  local config = Config.get_config()
  local keymap_opts = {
    buffer = self.bufnr,
    noremap = true,
    nowait = true,
    silent = true,
  }

  for key, action in pairs(config.mappings.list) do
    vim.keymap.set('n', key, action, keymap_opts)
  end

  vim.defer_fn(function()
    api.nvim_set_current_win(self.winid)
  end, 50)
  --------------------------------------------------
  -- NuiTree mappings ------------------------------
  --------------------------------------------------

  -- print current node
  -- pop:map('n', '<CR>', function()
  --   local node = tree:get_node()
  --   _G.foo = node
  --   -- print(vim.inspect(node))
  -- end, map_opt)

  -- -- add new node under current node
  -- pop:map('n', 'a', function()
  --   local node = tree:get_node()
  --   tree:add_node(
  --     NuiTree.Node({ text = 'd' }, {
  --       NuiTree.Node({ text = 'd-1' }),
  --     }),
  --     node:get_id()
  --   )
  --   tree:render()
  -- end, map_opt)

  -- -- delete current node
  -- pop:map('n', 'd', function()
  --   local node = tree:get_node()
  --   tree:remove_node(node:get_id())
  --   tree:render()
  -- end, map_opt)
end

return List
