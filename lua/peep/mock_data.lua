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
  {
    range = {
      ['end'] = { character = 5, line = 96 },
      start = { character = 4, line = 96 },
    },
    uri = 'file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/utils/file.lua',
  },
  {
    range = {
      ['end'] = { character = 7, line = 30 },
      start = { character = 6, line = 30 },
    },
    uri = 'file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/utils/reload.lua',
  },
  {
    range = {
      ['end'] = { character = 13, line = 176 },
      start = { character = 12, line = 176 },
    },
    uri = 'file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/utils/vinegar.lua',
  },
  {
    range = {
      ['end'] = { character = 3, line = 62 },
      start = { character = 2, line = 62 },
    },
    uri = 'file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/widgets/glance_mod.lua',
  },
  {
    range = {
      ['end'] = { character = 3, line = 35 },
      start = { character = 2, line = 35 },
    },
    uri = 'file:///e%3A/repoes/lua/peep.nvim/lua/peep/ui.lua',
  },
}

M.locations_from_results = {
  ['file:///c%3A/Users/hasan/AppData/Local/nvim/lua/core/global.lua'] = {
    {
      range = {
        ['end'] = {
          character = 3,
          line = 18,
        },
        start = {
          character = 4,
          line = 10,
        },
      },
    },
  },
  ['file:///c%3A/Users/hasan/dotfiles/nvim/lua/config/lsp/servers/dartls/pub.lua'] = {
    {
      range = {
        ['end'] = {
          character = 3,
          line = 16,
        },
        start = {
          character = 2,
          line = 16,
        },
      },
    },
  },
  ['file:///c%3A/Users/hasan/dotfiles/nvim/lua/core/global.lua'] = {
    {
      range = {
        ['end'] = {
          character = 1,
          line = 10,
        },
        start = {
          character = 0,
          line = 10,
        },
      },
    },
    {
      range = {
        ['end'] = {
          character = 3,
          line = 18,
        },
        start = {
          character = 4,
          line = 10,
        },
      },
    },
  },
  ['file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/utils/file.lua'] = {
    {
      range = {
        ['end'] = {
          character = 5,
          line = 96,
        },
        start = {
          character = 4,
          line = 96,
        },
      },
    },
  },
  ['file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/utils/reload.lua'] = {
    {
      range = {
        ['end'] = {
          character = 7,
          line = 30,
        },
        start = {
          character = 6,
          line = 30,
        },
      },
    },
  },
  ['file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/utils/vinegar.lua'] = {
    {
      range = {
        ['end'] = {
          character = 13,
          line = 176,
        },
        start = {
          character = 12,
          line = 176,
        },
      },
    },
  },
  ['file:///c%3A/Users/hasan/dotfiles/nvim/lua/hasan/widgets/glance_mod.lua'] = {
    {
      range = {
        ['end'] = {
          character = 3,
          line = 62,
        },
        start = {
          character = 2,
          line = 62,
        },
      },
    },
  },
  ['file:///e%3A/repoes/lua/peep.nvim/lua/peep/ui.lua'] = {
    {
      range = {
        ['end'] = {
          character = 3,
          line = 35,
        },
        start = {
          character = 2,
          line = 35,
        },
      },
    },
  },
}

return M
