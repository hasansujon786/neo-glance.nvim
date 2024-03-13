---@class NeoGlanceUiList
---@field winid number
---@field bufnr number
---@field tree NuiTree

local List = {}
List.__index = List

---@param initial_opts NeoGlanceUiList
function List:new(initial_opts)
  return setmetatable(initial_opts, self)
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
  local item = self.tree:get_node(idx)
  if not item or idx > line_count then
    return nil
  end
  return idx, item
end

---@param opts? { skip_groups: boolean, offset: number, cycle: boolean }
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
    return node
  end
  return nil
end

---@param opts? { skip_groups: boolean, offset: number, cycle: boolean }
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
    return target_node
  end
  return nil
end

---@param opts NeoGlanceUiList
function List:configure(opts)
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  self.tree = opts.tree
end

return List
