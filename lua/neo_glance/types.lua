---@class UiRenderOpts
---@field preview_opts? nui_popup_options
---@field list_opts? nui_popup_options
---@field locations NeoGlanceLocation[]
---@field parent_bufnr number
---@field parent_winid number

---@class NeoGlanceUiSettings
---@field preview nui_popup_options
---@field list nui_popup_options

---@class NeoGlanceConfig
---@field settings NeoGlanceUiSettings
---@field mappings table

---@class NeoGlanceUserConfig
---@field settings? NeoGlanceUiSettings
---@field mappings? table

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
