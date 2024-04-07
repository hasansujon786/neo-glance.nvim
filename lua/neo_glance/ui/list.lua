local Config = require('neo_glance.config')
local NuiLine = require('nui.line')
local NuiTree = require('nui.tree')
local Winbar = require('neo_glance.ui.winbar')
local _utils = require('_glance.utils')
local util = require('neo_glance.util')

local api = vim.api

---@class NeoGlanceUiList
---@field winid number
---@field bufnr number
---@field tree NuiTree
---@field parent_bufnr number
---@field parent_winid number
---@field winbar NeoGlanceUiWinbar
---@field raw_locations NeoGlanceLocation[]
local List = {}
List.__index = List

local winhl = {
  'Normal:GlanceListNormal',
  'CursorLine:GlanceListCursorLine',
  'EndOfBuffer:GlanceListEndOfBuffer',
}
local border_style = nil
local winbar_enable = false
local win_opts = {
  winbar = nil,
  winfixwidth = true,
  winfixheight = true,
  cursorline = true,
  wrap = false,
  signcolumn = 'no',
  foldenable = false,
  winhighlight = table.concat(winhl, ','),
}

local buf_opts = {
  bufhidden = 'wipe',
  buftype = 'nofile',
  swapfile = false,
  buflisted = false,
  filetype = 'Glance',
}

---@param opts NeoGlanceUiList.Create
---@return NeoGlanceUiList
function List:create(opts)
  local scope = {
    winid = opts.winid,
    bufnr = opts.bufnr,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
    tree = self:generate_tree(opts.nodes, opts.bufnr, opts.winid),
    winbar = nil,
  }

  if winbar_enable then
    scope.winbar = Winbar:new(opts.winid, {
      { name = 'title', hl = 'GlanceWinBarTitle' },
    })
  end

  return setmetatable(scope, self)
end

---@param opts {config:NeoGlanceConfig}
---@return NeoGlanceUiList
function List:init(opts)
  self:configure(opts.config)

  local scope = {
    winid = nil,
    bufnr = nil,
    parent_winid = nil,
    parent_bufnr = nil,
    tree = nil,
    winbar = nil,
  }

  return setmetatable(scope, self)
end

function List:get_popup_opts(opts)
  return util.merge({
    enter = false,
    focusable = true,
    border = {
      style = border_style,
    },
    buf_options = buf_opts,
    win_options = win_opts,
  }, opts or {})
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

function List:get_current_node(id)
  id = id or self:get_line() or 1
  return self.tree:get_node(id)
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
  self.winbar:render({ title = string.format('%s (%d)', get_lsp_method_label(), 23) })
  self:on_attach_buffer()
end

---@param nodes NuiTree.Node[]
---@param bufnr number
---@param winid number
function List:generate_tree(nodes, bufnr, winid)
  local config = Config.get_config()
  local icons = {
    ellipsis = config.folds.ellipsis,
    fold_closed = string.format(' %s ', config.folds.fold_closed),
    fold_open = string.format(' %s ', config.folds.fold_open),
    indent = string.format(' %s  ', config.indent_lines.icon),
  }
  local win_width = api.nvim_win_get_width(winid)
  local nodes_has_parent = nodes[1]:has_children()
  if nodes_has_parent then
    nodes[1]:expand()
  end

  local tree = NuiTree({
    bufnr = bufnr,
    nodes = nodes,
    prepare_node = function(node)
      local available_space = win_width
      local line = NuiLine()

      if node:has_children() then
        -- TODO: fix cursor col position while navigating
        line:append(node:is_expanded() and icons.fold_open or icons.fold_closed, 'GlanceFoldIcon')
        line:append(vim.fn.fnamemodify(node.text, ':t'), 'GlanceListFilename')
        line:append(' ')
        local ref_count = string.format(' %d ', #node:get_child_ids())
        available_space = available_space - (line:width() + string.len(ref_count))

        local file_path = vim.fn.fnamemodify(node.text, ':p:.:h')
        if string.len(file_path) <= available_space then
          line:append(file_path, 'GlanceListFilepath')
          available_space = available_space - string.len(file_path)
        else
          local shorten_path = string.sub(file_path, 0, (available_space - 1)) .. icons.ellipsis
          line:append(shorten_path, 'GlanceListFilepath')
          available_space = available_space - string.len(shorten_path)
        end

        line:append(string.rep(' ', available_space), 'GlanceListFilepath')
        line:append(ref_count, 'GlanceListCount')
      else
        if nodes_has_parent and config.indent_lines.enable then
          line:append(string.rep(icons.indent, node:get_depth() - 1), 'GlanceIndent') -- add depth on children node
        else
          line:append(' ')
        end
        line:append(node.text)
      end

      return line
    end,
  })

  return tree
end

function List:on_attach_buffer()
  local config = Config.get_config()

  if not config.folds.folded then
    self:expand_all()
  end

  local keymap_opts = {
    buffer = self.bufnr,
    noremap = true,
    nowait = true,
    silent = true,
  }
  for key, action in pairs(config.mappings.list) do
    vim.keymap.set('n', key, action, keymap_opts)
  end

  self.tree:render()

  local nodes_has_parent = self.tree:get_nodes()[1]:has_children()
  local row = nodes_has_parent and 2 or 1
  vim.defer_fn(function()
    api.nvim_set_current_win(self.winid)
    api.nvim_win_set_cursor(self.winid, { row, 1 })
  end, 50)
  --------------------------------------------------
  -- NuiTree mappings ------------------------------
  --------------------------------------------------

  -- print current node
  vim.keymap.set('n', '.', function()
    local node = self.tree:get_node()
    -- _G.foo = node
    print(vim.inspect(node:get_parent_id()))
  end, keymap_opts)

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

---@param opts? {nodes:NuiTree.Node[]}
---@return NuiTree.Node[]
function List:get_active_group_nodes(opts)
  if opts ~= nil and type(opts.nodes) == 'table' then
    if opts.nodes[1]:has_children() then
      return self.tree:get_nodes(opts.nodes[1]:get_id())
    end
    return opts.nodes
  end

  local current_node = self:get_current_node()
  if current_node ~= nil then
    local id = current_node:has_children() and current_node:get_id() or current_node:get_parent_id()
    return self.tree:get_nodes(id)
  end

  return self.tree:get_nodes()
end

function List:close()
  if vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_close(self.winid, true)
  end

  if vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, {})
  end
end

-- function List:destroy() end

---@param config NeoGlanceConfig
function List:configure(config)
  winbar_enable = config.winbar.enable
  border_style = Config.get_popup_opts(config, 'GlanceListBorderBottom')

  if winbar_enable then
    win_opts.winbar = '...'
  end
end

return List
