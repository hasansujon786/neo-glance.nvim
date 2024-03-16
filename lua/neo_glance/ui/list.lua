local Actions = require('neo_glance.actions')
local NuiTree = require('nui.tree')

local api = vim.api
local map_opt = { noremap = true, nowait = true }

---@class NeoGlanceUiList
---@field winid number
---@field bufnr number
---@field tree NuiTree
---@field list_popup NuiPopup
---@field preview_popup NuiPopup
---@field parent_bufnr number
---@field parent_winid number
---@field mappings table
local List = {}
List.__index = List

---@param opts {winid:number,bufnr:number,tree:NuiTree,list_popup:NuiPopup,preview_popup:NuiPopup,parent_bufnr:number,parent_winid:number,mappings:table}
---@return NeoGlanceUiList
function List:new(opts)
  return setmetatable({
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
    winid = opts.winid,
    bufnr = opts.bufnr,
    tree = opts.tree,
    list_popup = opts.list_popup,
    preview_popup = opts.preview_popup,
    mappings = opts.mappings
  }, self)
end

function List:get_cursor()
  return vim.api.nvim_win_get_cursor(self.winid)
end

function List:get_line()
  return self:get_cursor()[1]
end

function List:get_col()
  return self:get_cursor()[2]
end

---@param opts { start: integer, backwards?: boolean, cycle?: boolean }
function List:walk(opts)
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
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
    vim.api.nvim_win_set_cursor(self.winid, { idx, self:get_col() })
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
    search_from = vim.api.nvim_buf_line_count(self.bufnr)
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
    vim.api.nvim_win_set_cursor(self.winid, { target_idx, self:get_col() })
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

function List:setup_list_keymaps()
  local pop = self.list_popup
  local tree = self.tree

  local keymap_opts = {
    buffer = pop.bufnr,
    noremap = true,
    nowait = true,
    silent = true,
  }

  for key, action in pairs(self.mappings) do
    vim.keymap.set('n', key, action, keymap_opts)
  end

  vim.defer_fn(function()
    api.nvim_set_current_win(pop.winid)
  end, 50)
  --------------------------------------------------
  -- NuiTree mappings ------------------------------
  --------------------------------------------------

  -- print current node
  pop:map('n', '<CR>', function()
    local node = tree:get_node()
    _G.foo = node
    -- print(vim.inspect(node))
  end, map_opt)

  -- add new node under current node
  pop:map('n', 'a', function()
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
  pop:map('n', 'd', function()
    local node = tree:get_node()
    tree:remove_node(node:get_id())
    tree:render()
  end, map_opt)
end

return List
