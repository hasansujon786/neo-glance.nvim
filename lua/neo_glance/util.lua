local NuiLine = require('nui.line')
local NuiText = require('nui.text')
local NuiTree = require('nui.tree')
local mock_data = require('neo_glance.mock_data')
local M = {}

M.merge = function(...)
  return vim.tbl_deep_extend('force', ...)
end

function M.create_tree_nodes_from_locations(locations)
  local nodes = {}
  local first_node_child = nil

  for uri, parent_data in pairs(locations) do
    local child_nodes = {}

    for i, child_data in ipairs(parent_data.items) do
      if first_node_child == nil then
        first_node_child = child_data
      end

      local v = child_data.preview_line.value

      local line = NuiLine({
        NuiText(v.before),
        NuiText(v.inside, 'GlanceListMatch'),
        NuiText(v.after),
      })
      table.insert(child_nodes, NuiTree.Node({ id = 'child-' .. tostring(i) .. uri, text = line, data = child_data }))
    end

    table.insert(nodes, NuiTree.Node({ id = 'parent-' .. uri, text = parent_data.filename }, child_nodes))
  end
  return nodes, first_node_child
end

return M
