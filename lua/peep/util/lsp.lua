local protocol = require('vim.lsp.protocol')
local snippet = require('vim.lsp._snippet')
local validate = vim.validate
local api = vim.api
local list_extend = vim.list_extend
local highlight = require('vim.highlight')
local uv = vim.loop

local npcall = vim.F.npcall
local split = vim.split

local M = {}

local default_border = {
  { '', 'NormalFloat' },
  { '', 'NormalFloat' },
  { '', 'NormalFloat' },
  { ' ', 'NormalFloat' },
  { '', 'NormalFloat' },
  { '', 'NormalFloat' },
  { '', 'NormalFloat' },
  { ' ', 'NormalFloat' },
}

---@private
--- Gets the zero-indexed lines from the given buffer.
--- Works on unloaded buffers by reading the file using libuv to bypass buf reading events.
--- Falls back to loading the buffer and nvim_buf_get_lines for buffers with non-file URI.
---
---@param bufnr integer bufnr to get the lines from
---@param rows integer[] zero-indexed line numbers
---@return table<integer, string> a table mapping rows to lines
local function get_lines(bufnr, rows)
  rows = type(rows) == 'table' and rows or { rows }

  -- This is needed for bufload and bufloaded
  if bufnr == 0 then
    bufnr = api.nvim_get_current_buf()
  end

  ---@private
  local function buf_lines()
    local lines = {}
    for _, row in ipairs(rows) do
      lines[row] = (
        api.nvim_buf_get_lines(bufnr, row, row + 1, false) or { '' }
      )[1]
    end
    return lines
  end

  -- use loaded buffers if available
  if vim.fn.bufloaded(bufnr) == 1 then
    return buf_lines()
  end

  local uri = vim.uri_from_bufnr(bufnr)

  -- load the buffer if this is not a file uri
  -- Custom language server protocol extensions can result in servers sending URIs with custom schemes. Plugins are able to load these via `BufReadCmd` autocmds.
  if uri:sub(1, 4) ~= 'file' then
    vim.fn.bufload(bufnr)
    return buf_lines()
  end

  local filename = api.nvim_buf_get_name(bufnr)

  -- get the data from the file
  local fd = uv.fs_open(filename, 'r', 438)
  if not fd then
    return ''
  end
  local stat = uv.fs_fstat(fd)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  local lines = {} -- rows we need to retrieve
  local need = 0 -- keep track of how many unique rows we need
  for _, row in pairs(rows) do
    if not lines[row] then
      need = need + 1
    end
    lines[row] = true
  end

  local found = 0
  local lnum = 0

  for line in string.gmatch(data, '([^\n]*)\n?') do
    if lines[lnum] == true then
      lines[lnum] = line
      found = found + 1
      if found == need then
        break
      end
    end
    lnum = lnum + 1
  end

  -- change any lines we didn't find to the empty string
  for i, line in pairs(lines) do
    if line == true then
      lines[i] = ''
    end
  end
  return lines
end

---@private
local function sort_by_key(fn)
  return function(a, b)
    local ka, kb = fn(a), fn(b)
    assert(#ka == #kb)
    for i = 1, #ka do
      if ka[i] ~= kb[i] then
        return ka[i] < kb[i]
      end
    end
    -- every value must have been equal here, which means it's not less than.
    return false
  end
end

local position_sort = sort_by_key(function(v)
  return { v.start.line, v.start.character }
end)

--- Returns the items with the byte position calculated correctly and in sorted
--- order, for display in quickfix and location lists.
---
--- The result can be passed to the {list} argument of |setqflist()| or
--- |setloclist()|.
---
---@param locations table list of `Location`s or `LocationLink`s
---@param offset_encoding string offset_encoding for locations utf-8|utf-16|utf-32
---@returns (table) list of items
function M.locations_to_items(locations, offset_encoding) -- from nvim
  if offset_encoding == nil then
    vim.notify_once(
      'locations_to_items must be called with valid offset encoding',
      vim.log.levels.WARN
    )
  end

  local items = {}
  local grouped = setmetatable({}, {
    __index = function(t, k)
      local v = {}
      rawset(t, k, v)
      return v
    end,
  })
  for _, d in ipairs(locations) do
    -- locations may be Location or LocationLink
    local uri = d.uri or d.targetUri
    local range = d.range or d.targetSelectionRange
    table.insert(grouped[uri], { start = range.start })
  end

  local keys = vim.tbl_keys(grouped)
  table.sort(keys)
  -- TODO(ashkan) I wish we could do this lazily.
  for _, uri in ipairs(keys) do
    local rows = grouped[uri]
    table.sort(rows, position_sort)
    local filename = vim.uri_to_fname(uri)

    -- list of row numbers
    local uri_rows = {}
    for _, temp in ipairs(rows) do
      local pos = temp.start
      local row = pos.line
      table.insert(uri_rows, row)
    end

    -- get all the lines for this uri
    local lines = get_lines(vim.uri_to_bufnr(uri), uri_rows)

    for _, temp in ipairs(rows) do
      local pos = temp.start
      local row = pos.line
      local line = lines[row] or ''
      local col = M._str_byteindex_enc(line, pos.character, offset_encoding)
      table.insert(items, {
        filename = filename,
        lnum = row + 1,
        col = col + 1,
        text = line,
      })
    end
  end
  return items
end

--- Convert UTF index to `encoding` index.
--- Convenience wrapper around vim.str_byteindex
---Alternative to vim.str_byteindex that takes an encoding.
---@param line string line to be indexed
---@param index integer UTF index
---@param encoding string utf-8|utf-16|utf-32|nil defaults to utf-16
---@return integer byte (utf-8) index of `encoding` index `index` in `line`
function M._str_byteindex_enc(line, index, encoding)
  if not encoding then
    encoding = 'utf-16'
  end
  if encoding == 'utf-8' then
    if index then
      return index
    else
      return #line
    end
  elseif encoding == 'utf-16' then
    return vim.str_byteindex(line, index, true)
  elseif encoding == 'utf-32' then
    return vim.str_byteindex(line, index)
  else
    error('Invalid encoding: ' .. vim.inspect(encoding))
  end
end

return M
