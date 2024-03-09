local util = require('neo_glance.util')
local util_lsp = require('neo_glance.util.lsp')

---@class Lsp
---@field ui NeoGlanceUI
local Lsp = {}
Lsp.__index = Lsp

---@param ui table
function Lsp:new(ui)
  return setmetatable({
    -- win_id = nil,
    -- bufnr = nil,
    -- active_list = nil,
    ui = ui,
  }, self)
end

---@param method string
---@param context? table
function Lsp:references(method, context)
  vim.validate({ context = { context, 't', true } })
  local params = vim.lsp.util.make_position_params()
  params.context = context or { includeDeclaration = true }

  local client_req_ids, cancel_all_reques = vim.lsp.buf_request(0, method, params, function(err, result, ctx, _)
    if err then
      error(err.message)
    end
    if result == nil or vim.tbl_isempty(result) then
      return vim.notify('No references found', nil, { title = 'Peek' })
    end

    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local offset_encoding = client.server_capabilities.offsetEncoding

    self:handle_lsp_results(result, params, offset_encoding)
  end)
end

function Lsp:handle_lsp_results(result, params, offset_encoding)
  local locations = util_lsp.procrss_locations(result, params, offset_encoding)

  ---@type UiRenderOpts
  local renderOpts = { locations = locations }
  self.ui:render(renderOpts, util.create_tree_nodes_from_locations)
end

---@param ui NeoGlanceUI
function Lsp:configure(ui)
  self.ui = ui
end

return Lsp
