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

        ['<A-n>'] = actions.next_location, -- Bring the cursor to the next location skipping groups in the list
        ['<A-p>'] = actions.previous_location, -- Bring the cursor to the previous location skipping groups in the list
        ['<BS>'] = actions.enter_win('preview'), -- Focus preview window
        ['<leader>l'] = actions.enter_win('preview'), -- Focus preview window
        ['<leader>h'] = actions.enter_win('preview'), -- Focus preview window
        ['<leader>q'] = actions.close,
      },
      preview = {
        -- ['<A-n>'] = actions.next_location, -- Bring the cursor to the next location skipping groups in the list
        -- ['<A-p>'] = actions.previous_location, -- Bring the cursor to the previous location skipping groups in the list
        -- ['<BS>'] = actions.enter_win('list'), -- Focus list window
        ['<leader>l'] = actions.enter_win('list'), -- Focus list window
        -- ['<leader>h'] = actions.enter_win('list'), -- Focus list window
        -- ['<leader>q'] = actions.close,
      },
    },
    winbar = { enable = true },
    border = {
      enable = false,
      top_char = '─',
      bottom_char = '─',
    },
    preview_win_opts = {
      cursorline = true,
      number = true,
      wrap = true,
    },
    folds = {
      fold_closed = '',
      fold_open = '',
      folded = true,
      ellipsis = '⋯', -- ⋯ 
    },
    indent_lines = {
      enable = true,
      icon = '│',
    },
  }

  return config
end

---@param user_config NeoGlanceUserConfig
---@param old_config NeoGlanceConfig
---@return NeoGlanceConfig
function M.merge_config(user_config, old_config)
  return vim.tbl_deep_extend('force', {}, old_config, user_config or {})
end

---@return NeoGlanceConfig
function M.get_config()
  return require('neo_glance').config
end

---@param config NeoGlanceConfig
function M.get_popup_opts(config)
  ---@type table|string
  local border_style = 'none'
  if config.border.enable then
    -- stylua: ignore
    border_style =  {
      top_left    = '', top    = config.border.top_char,       top_right = '',
      left        = '',                                            right = '',
      bottom_left = '', bottom = config.border.bottom_char, bottom_right = '',
    }
  end
  return border_style
end

return M
