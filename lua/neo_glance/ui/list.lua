---@class NeoGlanceUiList
---@field winid number

local List = {}
List.__index = List

---@param initial_opts NeoGlanceUiList
function List:new(initial_opts)
  return setmetatable({
    winid = initial_opts.winid,
  }, self)
end

function List:get_cursor()
  return vim.api.nvim_win_get_cursor(self.winid)
end

function List:get_line()
  return self:get_cursor()[1]
end

function List:get_col()
  return self:get_cursor()[2]
end

---@param opts NeoGlanceUiList
function List:configure(opts)
  self.winid = opts.winid
end

return List
