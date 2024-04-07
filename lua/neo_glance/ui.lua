local Layout = require('nui.layout')
local Popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

local Actions = require('neo_glance.actions')
local List = require('neo_glance.ui.list')
local Preview = require('neo_glance.ui.preview')

local function get_win_above(winnr)
  return vim.api.nvim_win_call(winnr, function()
    return vim.fn.win_getid(vim.fn.winnr('k'))
  end)
end

local function get_offset_top(winnr)
  local win_above = get_win_above(winnr)
  if winnr ~= win_above and not require('_glance.utils').is_float_win(win_above) then
    -- plus 1 for the border
    return vim.fn.winheight(win_above) + get_offset_top(win_above) + 1
  end
  return 0
end

---@param winnr number
---@param config NeoGlanceConfig
---@return boolean
local function is_detached(winnr, config)
  local detached = config.detached
  if type(detached) == 'function' then
    return detached(winnr)
  end
  return detached
end

---@class NeoGlanceUI
---@field config NeoGlanceConfig
local Ui = {}
Ui.__index = Ui

---@param config NeoGlanceConfig
function Ui:init(config)
  Actions:init(config)

  return setmetatable({
    list = List:init({ config = config }),
    preview = Preview:init({ config = config }),
    config = config,
  }, self)
end

---@param opts UiRenderOpts
---@param node_extractor NeoGlanceNodeExtractor
function Ui:render(opts, node_extractor)
  local row = self:scroll_into_view(opts.parent_winid, opts.params.position)
  -- local push_tagstack = utils.create_push_tagstack(opts.winnr)
  local layout, preview_pop, list_pop = self:get_win_opts(opts.parent_winid, row, opts)

  -- if true then
  --   return
  -- end

  self.layout = layout
  self.preview_pop = preview_pop
  self.list_pop = list_pop

  self.layout:mount()
  local exit_layout = function()
    self.layout:unmount()
  end
  self.preview_pop:on(event.WinClosed, exit_layout, { once = true })
  self.list_pop:on(event.WinClosed, exit_layout, { once = true })

  vim.api.nvim_create_augroup('NeoGlance', { clear = true })

  local nodes, first_node_child_data = node_extractor(opts.locations)
  self:render_list(nodes, opts)
  self:render_preview(first_node_child_data, opts, nodes)

  Actions:create({
    list = self.list,
    preview = self.preview,
    preview_popup = self.preview_pop,
    list_popup = self.list_pop,
  })
end

---@param nodes NuiTree.Node[]
---@param opts UiRenderOpts
function Ui:render_list(nodes, opts)
  self.list = List:create({
    nodes = nodes,
    winid = self.list_pop.winid,
    bufnr = self.list_pop.bufnr,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
    raw_locations = opts.locations,
  })
  self.list:setup()
end

---@param location_item NeoGlanceLocation|NeoGlanceLocationItem|nil
---@param opts UiRenderOpts
---@param nodes NuiTree.Node[]
function Ui:render_preview(location_item, opts, nodes)
  self.preview = Preview:create({
    winid = self.preview_pop.winid,
    bufnr = self.preview_pop.bufnr,
    parent_winid = opts.parent_winid,
    parent_bufnr = opts.parent_bufnr,
  })

  local current_group_nodes = self.list:get_active_group_nodes({ nodes = nodes })
  self.preview:update_buffer(location_item, current_group_nodes)
end

---@param winid number
---@param line any
---@param opts UiRenderOpts
---@return table
---@return table
---@return table
function Ui:get_win_opts(winid, line, opts)
  local config = self.config
  local detached = is_detached(winid, config)
  local height = require('neo_glance.config').get_preview_win_height(winid, config) + (config.border.enable and 2 or 0)
  local row = line

  -- local win_width = detached and vim.o.columns or vim.fn.winwidth(winid)
  -- local list_width = require('_glance.utils').round(win_width * math.min(0.5, math.max(0.1, config.list.width)))
  -- local preview_width = win_width - list_width

  if detached then
    local winbar_space = vim.api.nvim_win_call(winid, function()
      if vim.fn.has('nvim-0.8') ~= 0 then
        return vim.o.winbar ~= '' and 1 or 0
      end
      return 0
    end)

    local tabline_space = vim.api.nvim_win_call(winid, function()
      return vim.o.tabline ~= '' and 1 or 0
    end)

    local offset = get_offset_top(winid)
    row = offset + line + winbar_space + tabline_space
  end

  local list_pop = Popup(self.list:get_popup_opts(opts.list_opts))
  local preview_pop = Popup(self.preview:get_popup_opts(opts.preview_opts))
  local preview_box = Layout.Box(preview_pop, { grow = 1 })
  local list_box = Layout.Box(list_pop, {
    size = { width = math.min(0.5, math.max(0.1, config.list.width)) },
  })

  local layout = Layout(
    {
      relative = detached and 'editor' or 'win',
      position = { col = 0, row = row },
      size = { width = '100%', height = height },
    },
    Layout.Box(
      config.list.position == 'right' and { preview_box, list_box } or { list_box, preview_box },
      { dir = 'row' }
    )
  )

  return layout, preview_pop, list_pop
end

function Ui:scroll_into_view(winnr, position)
  -- User might have moved cursor during the lsp request
  -- Set the cursor position just in case
  vim.api.nvim_win_set_cursor(winnr, { position.line + 1, position.character })
  local win_height = vim.fn.winheight(winnr)
  local row = vim.fn.winline()
  local bottom_offset = 2
  local border_height = self.config.border.enable and 2 or 0
  local preview_height = require('neo_glance.config').get_preview_win_height(winnr, self.config)
    + border_height
    + bottom_offset

  if preview_height >= win_height then
    return 0
  end

  local scrolloff_value = vim.wo.scrolloff
  vim.wo.scrolloff = 0

  -- Scroll the window down until we have enough rows to render the preview window.
  -- Needs to be done row by row because the <C-e> command scrolls over lines and not rows
  -- some lines can take more than 1 row when 'wrap' is enabled
  -- which makes it hard to calculate the scroll distance beforehand.
  while win_height - row < preview_height do
    vim.cmd([[exec "norm! \<C-e>"]])
    row = vim.fn.winline()
  end

  vim.wo.scrolloff = scrolloff_value

  return row
end

---@param config NeoGlanceConfig
function Ui:configure(config)
  self.preview:configure(config)
  self.list:configure(config)
  Actions:configure(config)
  self.config = config
end

return Ui
