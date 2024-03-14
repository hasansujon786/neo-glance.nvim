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
  actions.ui:update_preview(item)
end

function actions.previous()
  local item = actions.list:previous()
  actions.ui:update_preview(item)
end

function actions.next_location()
  local item = actions.list:next({ cycle = true, skip_groups = true })
  actions.ui:update_preview(item)
end

function actions.previous_location()
  local item = actions.list:previous({ cycle = true, skip_groups = true })
  actions.ui:update_preview(item)
end

function actions.close()
  actions.list.popup:unmount()
  actions.list.preview_popup:unmount()
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

---@param opts {list:NeoGlanceUiList,preview:table,ui:NeoGlanceUI}
function actions:setup(opts)
  self.preview = opts.preview
  self.list = opts.list
  self.ui = opts.ui
end

return actions
