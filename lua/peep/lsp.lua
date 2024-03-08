local util = require('peep.util')
local lsp_util = require('peep.util.lsp')
local vim_util = require('vim.lsp.util')

---@class Lsp
---@field ui PeepUI
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

function Lsp:references(method, context)
  vim.validate({ context = { context, 't', true } })
  local params = vim.lsp.util.make_position_params()
  params.context = context or { includeDeclaration = true }
  -- 'textDocument/definition',

  local client_req_ids, cancel_all_reques = vim.lsp.buf_request(
    0,
    'textDocument/references',
    params,
    function(err, result, ctx, _)
      if err then
        error(err.message)
      end
      if result == nil or vim.tbl_isempty(result) then
        return vim.notify('No references found', nil, { title = 'Peek' })
      end

      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local offset_encoding = client.server_capabilities.offsetEncoding

      self:handle_lsp_results(result, params, offset_encoding)
    end
  )
end

function Lsp:handle_lsp_results(result, params, offset_encoding)
  -- local x = lsp_util.locations_to_items(result, offset_encoding)
  -- -- local x = vim_util.locations_to_items(results, offset_encoding)
  -- _G.foo = x
  local locations = util.lsp_results_to_locations(result)
  self.ui:render({ locations = locations, offset_encoding = offset_encoding })
end

---@param ui PeepUI
function Lsp:configure(ui)
  self.ui = ui
end

return Lsp

-- -- location may be LocationLink or Location (more useful for the former)
-- -- local context = 15
-- -- local before_context = 0

--   local location = results
--   if vim.tbl_islist(results) then
--     location = results[1]
--   end

--   local uri = location.targetUri or location.uri
--   if uri == nil then
--     Foo = location
--     return
--   end
--   local bufnr = vim.uri_to_bufnr(uri)
--   if not vim.api.nvim_buf_is_loaded(bufnr) then
--     vim.fn.bufload(bufnr)
--   end

-- -- local range = location.targetRange or location.range
-- -- local contents = vim.api.nvim_buf_get_lines(
-- --   bubufnrfnr,
-- --   range.start.line - before_context,
-- --   range['end'].line + 1 + context,
-- --   false
-- -- )
-- -- local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
-- -- return vim.lsp.util.open_floating_preview(
-- --   contents,
-- --   filetype,
-- --   { border = ui.border.style }
-- -- )
