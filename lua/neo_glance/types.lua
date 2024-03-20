---@class UiRenderOpts
---@field preview_opts? nui_popup_options
---@field list_opts? nui_popup_options
---@field locations NeoGlanceLocation[]
---@field parent_bufnr number
---@field parent_winid number

---@class NeoGlanceLocation
---@field items NeoGlanceLocationItem[]
---@field filename string
---@field uri string
---@field is_group boolean

---@class NeoGlanceLocationItem
---@field bufnr  number
---@field end_col  number
---@field end_line  number
---@field filename string
---@field full_text string
---@field index  number
---@field is_starting boolean
---@field is_unreachable boolean
---@field is_group_item boolean
---@field start_col  number
---@field start_line  number
---@field uri string
---@field preview_line { value: { before: string, inside: string, after: string } }

---@alias NeoGlanceNodeExtractor fun(locations: NeoGlanceLocation[]): NuiTree.Node[], NeoGlanceLocationItem

---@class NeoGlanceConfig
---@field mappings NeoGlanceConfigMappings
---@field preview_win_opts table
---@field border BorderOpts
---@field winbar NeoGlanceWinbarOpts

---@class NeoGlanceUserConfig
---@field mappings? NeoGlanceConfigMappings
---@field preview_win_opts? table
---@field border? BorderOpts
---@field winbar? NeoGlanceWinbarOpts

---@class NeoGlanceConfigMappings
---@field list table
---@field preview table

---@class BorderOpts
---@field enable boolean
---@field top_char string
---@field bottom_char string

---@class NeoGlanceWinbarOpts
---@field enable boolean

---@class NeoGlancePopupOpts
---@field preview nui_popup_options
---@field list nui_popup_options
