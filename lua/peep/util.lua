local NuiLine = require('nui.line')
local NuiText = require('nui.text')
local NuiTree = require('nui.tree')
local mock_data = require('peep.mock_data')
local M = {}

M.merge = function(...)
  return vim.tbl_deep_extend('force', ...)
end

function M.create_tree_nodes_from_locations(locations)
  local nodes = {}

  for uri, buf_data in pairs(locations) do
    local child_nodes = {}

    for i, child_data in ipairs(buf_data.items) do
      local v = child_data.preview_line.value

      local line = NuiLine({
        NuiText(v.before),
        NuiText(v.inside, 'GlanceListMatch'),
        NuiText(v.after),
      })
      table.insert(child_nodes, NuiTree.Node({ id = 'child-' .. tostring(i) .. uri, text = line }))
    end

    table.insert(nodes, NuiTree.Node({ id = 'parent-' .. uri, text = buf_data.filename }, child_nodes))
  end
  return nodes
end

return M
