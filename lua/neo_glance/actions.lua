---@class NeoGlanceActions
---@field list NeoGlanceUiList
---@field preview NeoGlanceUiPreview
---@field list_popup NuiPopup
---@field preview_popup NuiPopup
---@field config NeoGlanceConfig
local actions = {}
actions.__index = actions

---@param config NeoGlanceConfig
function actions:init(config)
  self:configure(config)
end

---@param opts {list:NeoGlanceUiList,preview:NeoGlanceUiPreview,list_popup:NuiPopup,preview_popup:NuiPopup}
function actions:create(opts)
  actions.list = opts.list
  actions.preview = opts.preview
  actions.list_popup = opts.list_popup
  actions.preview_popup = opts.preview_popup
  -- return setmetatable({
  --   list = opts.list,
  --   preview = opts.preview,
  -- }, self)
end

function actions.next()
  local item = actions.list:next()
  local group_nodes = actions.list:get_active_group_nodes()
  actions.preview:update_buffer(item, group_nodes)
end

function actions.previous()
  local item = actions.list:previous()
  local group_nodes = actions.list:get_active_group_nodes()
  actions.preview:update_buffer(item, group_nodes)
end

function actions.next_location()
  local item = actions.list:next({ cycle = true, skip_groups = true })
  local group_nodes = actions.list:get_active_group_nodes()
  actions.preview:update_buffer(item, group_nodes)
end

function actions.previous_location()
  local item = actions.list:previous({ cycle = true, skip_groups = true })
  local group_nodes = actions.list:get_active_group_nodes()
  actions.preview:update_buffer(item, group_nodes)
end

function actions.close()
  vim.api.nvim_del_augroup_by_name('NeoGlance')
  actions.list:close()
  actions.preview:close()
  actions.list_popup:unmount()
  actions.preview_popup:unmount()
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
      vim.api.nvim_set_current_win(actions.preview.winid)
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

---@param config NeoGlanceConfig
function actions:configure(config)
  self.config = config
end

return actions
