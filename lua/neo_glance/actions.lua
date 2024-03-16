---@class NeoGlanceActions
---@field preview table
---@field list NeoGlanceUiList
---@field ui NeoGlanceUI
local actions = {}
actions.__index = actions

---@param initial_opts {list:NeoGlanceUiList,preview:table,ui:NeoGlanceUI}
function actions:new(initial_opts)
  return setmetatable({
    preview = initial_opts.preview,
    list = initial_opts.list,
    ui = initial_opts.ui,
  }, self)
end

function actions.next()
  local item = actions.list:next()
  actions.ui.preview:update_buffer(item)
end

function actions.previous()
  local item = actions.list:previous()
  actions.ui.preview:update_buffer(item)
end

function actions.next_location()
  local item = actions.list:next({ cycle = true, skip_groups = true })
  actions.ui.preview:update_buffer(item)
end

function actions.previous_location()
  local item = actions.list:previous({ cycle = true, skip_groups = true })
  actions.ui.preview:update_buffer(item)
end

function actions.close()
  actions.list.list_popup:unmount()
  actions.list.preview_popup:unmount()
end

function actions:_jump(opts)
  opts = opts or {}
  local node = self.list.tree:get_node()
  if not node or not node.data then
    return
  end
  -- if not current_item or current_item.is_unreachable then
  --   return
  -- end
  if node.data.is_group then
    return self.toggle_fold()
  end
  ---@type NeoGlanceLocationItem
  local current_item = node.data

  self.close()

  if opts.cmd then
    vim.cmd(opts.cmd)
  end

  if vim.fn.buflisted(current_item.bufnr) == 1 then
    vim.cmd(('buffer %s'):format(current_item.bufnr))
  else
    vim.cmd(('edit %s'):format(vim.fn.fnameescape(current_item.filename)))
  end

  vim.api.nvim_win_set_cursor(0, { current_item.start_line + 1, current_item.start_col })
  vim.cmd('norm! zz')

  -- glance.push_tagstack()
  -- self:destroy()
end

function actions.jump()
  actions:_jump()
end
function actions.jump_split()
  actions:_jump({ cmd = 'split' })
end
function actions.jump_vsplit()
  actions:_jump({ cmd = 'vsplit' })
end
function actions.jump_tab()
  actions:_jump({ cmd = 'tabe' })
end

function actions.enter_win(win)
  return function()
    if win == 'preview' then
      vim.api.nvim_set_current_win(actions.list.preview_popup.winid)
    end

    if win == 'list' then
      vim.api.nvim_set_current_win(actions.list.winid)
    end
  end
end

function actions.toggle_fold()
  actions.list:toggle_fold()
end
function actions.open_fold()
  actions.list:open_fold()
end
function actions.close_fold()
  actions.list:close_fold()
end
function actions.collapse_all()
  actions.list:collapse_all()
end
function actions.expand_all()
  actions.list:expand_all()
end

---@param opts {list:NeoGlanceUiList,preview:table,ui:NeoGlanceUI}
function actions:setup(opts)
  self.preview = opts.preview
  self.list = opts.list
  self.ui = opts.ui
end

return actions
