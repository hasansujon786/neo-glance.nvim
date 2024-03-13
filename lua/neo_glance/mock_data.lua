local M = {}

M.lsp_results = {
  {
    range = {
      ['end'] = { character = 3, line = 18 },
      start = { character = 4, line = 10 },
    },
    uri = 'file:///c%3A/Users/hasan/AppData/Local/nvim/lua/core/global.lua',
  },
  {
    range = {
      ['end'] = { character = 3, line = 16 },
      start = { character = 2, line = 16 },
    },
    uri = 'file:///c%3A/Users/hasan/dotfiles/nvim/lua/config/lsp/servers/dartls/pub.lua',
  },
  {
    range = {
      ['end'] = { character = 1, line = 10 },
      start = { character = 0, line = 10 },
    },
    uri = 'file:///c%3A/Users/hasan/dotfiles/nvim/lua/core/global.lua',
  },
  {
    range = {
      ['end'] = { character = 3, line = 18 },
      start = { character = 4, line = 10 },
    },
    uri = 'file:///c%3A/Users/hasan/dotfiles/nvim/lua/core/global.lua',
  },
}

M.process_locations = {
  ['global.lua'] = {
    filename = 'global.lua',
    is_group = true,
    items = {
      {
        bufnr = 167,
        end_col = 3,
        end_line = 18,
        filename = 'global.lua',
        full_text = 'P = function(...)\r',
        index = 1,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = '',
            before = 'P = ',
            inside = 'function(...)\r',
          },
        },
        start_col = 4,
        start_line = 10,
        uri = 'file:///c%3A/Users/hasan/AppData/Local/nvim/lua/core/global.lua',
      },
    },
    uri = 'file:///c%3A/Users/hasan/AppData/Local/nvim/lua/core/global.lua',
  },
  ['foo.lua'] = {
    filename = 'foo.lua',
    is_group = true,
    items = {
      {
        bufnr = 168,
        end_col = 1,
        end_line = 3,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\foo.lua',
        full_text = 'P(idx)\r',
        index = 1,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = '(idx)',
            before = '',
            inside = 'P',
          },
        },
        start_col = 0,
        start_line = 3,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/foo.lua',
      },
      {
        bufnr = 168,
        end_col = 1,
        end_line = 3,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\foo.lua',
        full_text = 'P(idx)\r',
        index = 1,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = '(idx)',
            before = '',
            inside = 'P',
          },
        },
        start_col = 0,
        start_line = 3,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/foo.lua',
      },
    },
    uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/foo.lua',
  },
  ['ui.lua'] = {
    filename = 'ui.lua',
    is_group = true,
    items = {
      {
        bufnr = 2,
        end_col = 5,
        end_line = 192,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\ui.lua',
        full_text = "    P('xxxxxxx ' .. math.random())",
        index = 1,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = "('xxxxxxx ' .. math.random())",
            before = '',
            inside = 'P',
          },
        },
        start_col = 4,
        start_line = 192,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui.lua',
      },
      {
        bufnr = 2,
        end_col = 5,
        end_line = 302,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\ui.lua',
        full_text = "    P('same item ' .. math.random())",
        index = 2,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = "('same item ' .. math.random())",
            before = '',
            inside = 'P',
          },
        },
        start_col = 4,
        start_line = 302,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui.lua',
      },
      {
        bufnr = 2,
        end_col = 5,
        end_line = 302,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\ui.lua',
        full_text = "    P('same item ' .. math.random())",
        index = 2,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = "('same item ' .. math.random())",
            before = '',
            inside = 'P',
          },
        },
        start_col = 4,
        start_line = 302,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui.lua',
      },
      {
        bufnr = 2,
        end_col = 5,
        end_line = 317,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\ui.lua',
        full_text = "    P('different place in same buffer ' .. math.random())",
        index = 3,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = "('different place in same buffer ' .. math.random())",
            before = '',
            inside = 'P',
          },
        },
        start_col = 4,
        start_line = 317,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui.lua',
      },
      {
        bufnr = 2,
        end_col = 3,
        end_line = 321,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\ui.lua',
        full_text = "  P('new item ' .. math.random())",
        index = 4,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = "('new item ' .. math.random())",
            before = '',
            inside = 'P',
          },
        },
        start_col = 2,
        start_line = 321,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui.lua',
      },
    },
    uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui.lua',
  },
  ['list.lua'] = {
    filename = 'list.lua',
    is_group = true,
    items = {
      {
        bufnr = 3,
        end_col = 5,
        end_line = 83,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\ui\\list.lua',
        full_text = '    P({ idx, vim.api.nvim_buf_line_count(self.bufnr) })',
        index = 1,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = '({ idx, vim.api.nvim_buf_line_count(self.bufnr) })',
            before = '',
            inside = 'P',
          },
        },
        start_col = 4,
        start_line = 83,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui/list.lua',
      },
      {
        bufnr = 168,
        end_col = 1,
        end_line = 3,
        filename = 'e:\\repoes\\lua\\neo-glance.nvim_local\\lua\\neo_glance\\foo.lua',
        full_text = 'P(idx)\r',
        index = 1,
        is_group_item = true,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = '(idx)',
            before = '',
            inside = 'P',
          },
        },
        start_col = 0,
        start_line = 3,
        uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/foo.lua',
      },
    },
    uri = 'file:///e%3A/repoes/lua/neo-glance.nvim_local/lua/neo_glance/ui/list.lua',
  },
}

return M
