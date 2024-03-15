local actions = require('neo_glance.actions')
local M = {}

---@return NeoGlanceConfig
function M.get_default_config()
  ---@type NeoGlanceConfig
  local config = {
    mappings = {
      list = {
        ['<tab>'] = actions.next_location,
        ['<s-tab>'] = actions.previous_location,
        ['<leader>h'] = actions.enter_win('preview'),
        ['o'] = actions.jump,
        ['v'] = actions.jump_vsplit,
        ['s'] = actions.jump_split,
        ['t'] = actions.jump_tab,
        ['<cr>'] = actions.jump,
        ['j'] = actions.next,
        ['k'] = actions.previous,
        ['q'] = actions.close,
        ['l'] = actions.open_fold,
        ['h'] = actions.close_fold,
        ['L'] = actions.expand_all,
        ['H'] = actions.collapse_all,
      },
    },
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
          cursorline = true,
          relativenumber = true,
          signcolumn = 'no', -- TODO: make sure my statuscolumn works
          number = true,
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
          cursorline = true,
        },
      },
    },
  }

  return config
end

---@param user_config NeoGlanceUserConfig
---@param config NeoGlanceConfig
---@return NeoGlanceConfig
function M.merge_config(user_config, config)
  user_config = user_config or {}
  local _config = config or M.get_default_config()
  _config = vim.tbl_extend('force', config, user_config)
  return _config
end

return M
