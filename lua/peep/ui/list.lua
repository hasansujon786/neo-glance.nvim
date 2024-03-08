local glance_utils = require('glance.utils')
local Range = require('glance.range')
local M = {}

---@private
--- from: https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/util.lua
--- Gets the zero-indexed lines from the given buffer.
--- Works on unloaded buffers by reading the file using libuv to bypass buf reading events.
--- Falls back to loading the buffer and nvim_buf_get_lines for buffers with non-file URI.
---
---@param bufnr number bufnr to get the lines from
---@param rows number[] zero-indexed line numbers
---@return table<number, string> | nil a table mapping rows to lines
local function get_lines(bufnr, uri, rows)
  rows = type(rows) == 'table' and rows or { rows }

  -- This is needed for bufload and bufloaded
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  ---@private
  local function buf_lines()
    local lines = {}
    for _, row in pairs(rows) do
      lines[row] = (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false) or { '', })[1]
    end
    return lines
  end

  -- load the buffer if this is not a file uri
  -- Custom language server protocol extensions can result in servers sending URIs with custom schemes. Plugins are able to load these via `BufReadCmd` autocmds.
  if uri:sub(1, 4) ~= 'file' then
    vim.fn.bufload(bufnr)
    return buf_lines()
  end

  -- use loaded buffers if available
  if vim.fn.bufloaded(bufnr) == 1 then
    return buf_lines()
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)

  -- get the data from the file
  local fd = vim.loop.fs_open(filename, 'r', 438)

  if not fd then
    return nil
  end

  local stat = vim.loop.fs_fstat(fd)
  local data = vim.loop.fs_read(fd, stat.size, 0)
  vim.loop.fs_close(fd)

  local lines = {} -- rows we need to retrieve
  local rows_needed = 0 -- keep track of how many unique rows we need
  for _, row in pairs(rows) do
    if not lines[row] then
      rows_needed = rows_needed + 1
    end
    lines[row] = true
  end

  local found = 0
  local lnum = 0

  for line in string.gmatch(data, '([^\n]*)\n?') do
    if lines[lnum] == true then
      lines[lnum] = line
      found = found + 1
      if found == rows_needed then
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

local function is_starting_location(
  position_params,
  location_uri,
  location_range
)
  if location_uri ~= position_params.textDocument.uri then
    return false
  end

  local range = Range:new(
    location_range.start.line,
    location_range.start.character,
    location_range.finish.line,
    location_range.finish.character
  )

  return range:contains_position({
    line = position_params.position.line,
    col = position_params.position.character,
  })
end

local function get_preview_line(range, offset, text)
  local word =
    glance_utils.get_word_until_position(range.start_col - offset, text)

  if range.end_line > range.start_line then
    range.end_col = string.len(text) + 1
  end

  local before = glance_utils
    .get_value_in_range(word.start_col, range.start_col, text)
    :gsub('^%s+', '')
  local inside =
    glance_utils.get_value_in_range(range.start_col, range.end_col, text)
  local after = glance_utils
    .get_value_in_range(range.end_col, string.len(text) + 1, text)
    :gsub('%s+$', '')

  return {
    value = {
      before = before,
      inside = inside,
      after = after,
    },
  }
end

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

function M.process_locations(locations, position_params, offset_encoding)
  -- _G.locations = locations
  -- _G.position_params = position_params
  -- _G.offset_encoding = offset_encoding

  local result = {}

  local grouped = setmetatable({}, {
    __index = function(t, k)
      local v = {}
      rawset(t, k, v)
      return v
    end,
  })

  for _, location in ipairs(locations) do
    local uri = location.uri or location.targetUri
    local range = location.range or location.targetSelectionRange
    table.insert(grouped[uri], { start = range.start, finish = range['end'] })
  end

  local keys = vim.tbl_keys(grouped)
  table.sort(keys)

  for _, uri in ipairs(keys) do
    local rows = grouped[uri]
    table.sort(rows, position_sort)
    local filename = vim.uri_to_fname(uri)
    local bufnr = vim.uri_to_bufnr(uri)
    result[filename] = {
      filename = filename,
      uri = uri,
      items = {},
    }

    -- list of row numbers
    local uri_rows = {}

    for _, position in ipairs(rows) do
      local row = position.start.line
      table.insert(uri_rows, row)
    end

    -- get all the lines for this uri
    local lines = get_lines(bufnr, uri, uri_rows)

    for index, position in ipairs(rows) do
      local preview_line
      local is_unreachable = false
      local start = position.start
      local finish = position.finish
      local start_col = start.character
      local end_col = finish.character
      local row = start.line
      local line = lines and lines[row]

      if not line then
        line = ('%s:%d:%d'):format(
          vim.fn.fnamemodify(filename, ':t'),
          start_col + 1,
          end_col + 1
        )
        is_unreachable = true
      else
        start_col = glance_utils.get_line_byte_from_position(line, start, offset_encoding)
        end_col = glance_utils.get_line_byte_from_position(
          line,
          finish,
          offset_encoding
        )

        preview_line = get_preview_line({
          start_line = row,
          start_col = start_col,
          end_col = end_col,
          end_line = finish.line,
        }, 8, line)
      end

      local location = {
        filename = filename,
        bufnr = bufnr,
        index = index,
        uri = uri,
        preview_line = preview_line,
        is_unreachable = is_unreachable,
        full_text = line or '',
        start_line = start.line,
        end_line = finish.line,
        start_col = start_col,
        end_col = end_col,
        is_starting = is_starting_location(
          position_params,
          uri,
          { start = start, finish = finish }
        ),
      }

      table.insert(result[filename].items, location)
    end
  end

  return result
end

return M
