local Input = require('nui.input')
local Layout = require('nui.layout')
local Menu = require('nui.menu')
local NuiTree = require('nui.tree')
local Popup = require('nui.popup')
local Text = require('nui.text')
local event = require('nui.utils.autocmd').event

local NuiLine = require('nui.line')

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
---@param node_extractor fun(locations)
function Ui:render(opts, node_extractor)
  local preview_conf = util.merge(self.settings.preview, opts.preview_opts or {})
  local list_conf = util.merge(self.settings.list, opts.list_opts or {})

  local list_pop = Popup(list_conf)
  local preview_pop = Popup(preview_conf)

  local layout = Layout(
    {
      relative = 'win',
      position = { col = 0, row = 1 },
      size = { width = '100%', height = 20 },
    },
    Layout.Box({
      Layout.Box(preview_pop, { grow = 1 }),
      Layout.Box(list_pop, { size = { width = 50 } }),
    }, { dir = 'row' })
  )

  layout:mount()

  local exit = function()
    layout:unmount()
  end

  preview_pop:on(event.WinClosed, exit, { once = true })
  list_pop:on(event.WinClosed, exit, { once = true })

  list_pop:map('n', '<C-c>', exit, map_opt)
  list_pop:map('n', 'q', exit, map_opt)
  list_pop:map('n', 'p', exit, map_opt)

  local nodes, first_child = node_extractor(opts.locations)
  self:render_list(list_pop, opts, nodes)
  preview_pop:update_layout()
end

---comment
---@param list_pop NuiPopup
---@param opts UiRenderOpts
---@param nodes table
function Ui:render_list(list_pop, opts, nodes)
  local tree = NuiTree({
    bufnr = list_pop.bufnr,
    -- winid = split.winid,
    nodes = nodes,
    prepare_node = function(node)
      local line = NuiLine()

      line:append(string.rep('  ', node:get_depth() - 1))

      if node:has_children() then
        line:append(node:is_expanded() and ' ' or ' ', 'SpecialChar')
      else
        line:append('  ')
      end

      line:append(node.text)

      return line
    end,
  })

  self:add_list_maps(list_pop, tree)
  tree:render()
  -- list_pop:mount()
end

---@param list_pop NuiPopup
---@param tree NuiTree
function Ui:add_list_maps(list_pop, tree)
  -- quit
  list_pop:map('n', 'q', function()
    list_pop:unmount()
  end, { noremap = true })

  -- print current node
  list_pop:map('n', '<CR>', function()
    local node = tree:get_node()
    print(vim.inspect(node))
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

-- Win:render_preview({})
-- require('neo_glance.lsp').references()

---@param settings NeoGlanceUiSettings
function Ui:configure(settings)
  self.settings = settings
end

return Ui
