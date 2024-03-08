local NuiTree = require('nui.tree')
local M = {}

M.merge = function(...)
  return vim.tbl_deep_extend('force', ...)
end

function M.lsp_results_to_locations(results)
  local loc = {}

  for _, value in ipairs(results) do
    if loc[value.uri] == nil then
      loc[value.uri] = { { range = value.range } }
    else
      table.insert(loc[value.uri], { range = value.range })
    end
  end

  return loc
  -- return require('peep.mock_data').locations_from_results
end

function M.create_tree_nodes(locations)
  local nodes = {}

  for uri, childrensData in pairs(locations) do
    local childNodes = {}

    for childIdx, childLocationData in ipairs(childrensData) do
      table.insert(
        childNodes,
        NuiTree.Node({ text = 'child-' .. tostring(childIdx) })
      )
    end

    table.insert(nodes, NuiTree.Node({ text = uri }, childNodes))
  end
  return nodes
end

return M
