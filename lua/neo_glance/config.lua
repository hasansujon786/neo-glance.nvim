local actions = require('neo_glance.actions')
local M = {
  hl_ns = 'Glance',
  namespace = vim.api.nvim_create_namespace('Glance'),
}

---@return NeoGlanceConfig
function M.get_default_config()
  ---@type NeoGlanceConfig
  local config = {
    height = 18,
    zindex = 45,
    detached = function(winid)
      return vim.api.nvim_win_get_width(winid) < 100
    end,
    list = {
      position = 'right',
      width = 0.33, -- 33% width relative to the active window, min 0.1, max 0.5
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
      ellipsis = '…', -- ⋯ 
    },
    indent_lines = {
      enable = true,
      icon = '│',
    },
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
---@param bottom_hl string
function M.get_popup_opts(config, bottom_hl)
  ---@type table|string
  local border_style = 'none'
  if config.border.enable then
    -- stylua: ignore
    border_style =  {
      top_left    = '', top = {config.border.top_char, 'GlanceBorderTop'},  top_right = '',
      left        = '',                                                         right = '',
      bottom_left = '', bottom = {config.border.bottom_char, bottom_hl}, bottom_right = '',
    }
  end
  return border_style
end

---@param winid number
---@param config NeoGlanceConfig
---@return number
function M.get_preview_win_height(winid, config)
  return math.min(vim.fn.winheight(winid), config.height)
end

return M
