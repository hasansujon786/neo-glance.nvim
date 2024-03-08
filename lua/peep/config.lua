local M = {}

---@return PeepConfig
function M.get_default_config()
  ---@type PeepConfig
  local config = {
    settings = {
      preview = {
        enter = false,
        focusable = true,
        border = { style = 'single' },
        buf_options = {
          modifiable = true,
          readonly = false,
        },
        win_options = {
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          winbar = '',
        },
      },
      list = {
        enter = false,
        focusable = true,
        border = { style = 'single' },
        buf_options = {
          modifiable = true,
          readonly = false,
        },
        win_options = {
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
      },
    },
  }

  return config
end

---@param user_config PeepUserConfig
---@param config PeepConfig
---@return PeepConfig
function M.merge_config(user_config, config)
  user_config = user_config or {}
  local _config = config or M.get_default_config()
  _config = vim.tbl_extend('force', config, user_config)
  return _config
end

return M
