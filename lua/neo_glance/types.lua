---@class UiRenderOpts
---@field preview_opts? nui_popup_options
---@field list_opts? nui_popup_options
---@field locations NeoGlanceLocation[]

---@class NeoGlanceUiSettings
---@field preview nui_popup_options
---@field list nui_popup_options

---@class NeoGlanceConfig
---@field settings NeoGlanceUiSettings

---@class NeoGlanceUserConfig
---@field settings? NeoGlanceUiSettings

---@class NeoGlanceLocation
---@field items NeoGlanceLocationItem[]
---@field filename string
---@field uri string

---@class NeoGlanceLocationItem
---@field bufnr  number
---@field end_col  number
---@field end_line  number
---@field filename string
---@field full_text string
---@field index  number
---@field is_starting boolean
---@field is_unreachable boolean
---@field start_col  number
---@field start_line  number
---@field uri string
---@field preview_line { value: { before: string, inside: string, after: string } }

---@alias NeoGlanceNodeExtractor fun(locations: NeoGlanceLocation[]): NuiTree.Node[], NeoGlanceLocationItem
