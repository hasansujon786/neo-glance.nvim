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
  ['e:\\repoes\\lua\\peep.nvim_local\\lua\\peep\\lsp.lua'] = {
    filename = 'e:\\repoes\\lua\\peep.nvim_local\\lua\\peep\\lsp.lua',
    uri = 'file:///e%3A/repoes/lua/peep.nvim_local/lua/peep/lsp.lua',
    items = {
      {
        bufnr = 2,
        end_col = 17,
        end_line = 46,
        filename = 'e:\\repoes\\lua\\peep.nvim_local\\lua\\peep\\lsp.lua',
        full_text = '  local locations = util_lsp.process_locations(result, params, offset_encoding)',
        index = 1,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = ' = util_lsp.process_locations(result, params, offset_encoding)',
            before = 'local ',
            inside = 'locations',
          },
        },
        start_col = 8,
        start_line = 46,
        uri = 'file:///e%3A/repoes/lua/peep.nvim_local/lua/peep/lsp.lua',
      },
      {
        bufnr = 2,
        end_col = 20,
        end_line = 48,
        filename = 'e:\\repoes\\lua\\peep.nvim_local\\lua\\peep\\lsp.lua',
        full_text = '  _G.foo = locations',
        index = 2,
        is_starting = false,
        is_unreachable = false,
        preview_line = {
          value = {
            after = '',
            before = '_G.foo = ',
            inside = 'locations',
          },
        },
        start_col = 11,
        start_line = 48,
        uri = 'file:///e%3A/repoes/lua/peep.nvim_local/lua/peep/lsp.lua',
      },
    },
  },
}

return M
