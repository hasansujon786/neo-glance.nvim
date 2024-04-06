---@class UiRenderOpts
---@field preview_opts? nui_popup_options
---@field list_opts? nui_popup_options
---@field locations NeoGlanceLocation[]
---@field parent_bufnr number
---@field parent_winid number
---@field params NeoGlanceLpsParams

---@class NeoGlanceUiList.Create
---@field winid number
---@field bufnr number
---@field nodes NuiTree.Node[]
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

---@class NeoGlanceLpsParams
---@field context table
---@field position table
---@field textDocument table

-- Config type --
---@class NeoGlanceConfig
---@field height number
---@field zindex number
---@field detached fun(winid:number): boolean
---@field list NeoGlanceListOpts
---@field preview_win_opts table
---@field border NeoGlanceBorderOpts
---@field winbar NeoGlanceWinbarOpts
---@field folds NeoGlanceFoldsrOpts
---@field indent_lines NeoGlanceIndentOpts
---@field mappings NeoGlanceConfigMappings

---@class NeoGlanceUserConfig
---@field height? number
---@field zindex? number
---@field detached? fun(winid:number): boolean
---@field list? NeoGlanceListOpts
---@field preview_win_opts? table
---@field border? NeoGlanceBorderOpts
---@field winbar? NeoGlanceWinbarOpts
---@field folds? NeoGlanceFoldsrOpts
---@field indent_lines? NeoGlanceIndentOpts
---@field mappings? NeoGlanceConfigMappings

---@class NeoGlanceListOpts
---@field position 'left'|'right'
---@field width number

---@class NeoGlanceConfigMappings
---@field list table
---@field preview table

---@class NeoGlanceBorderOpts
---@field enable boolean
---@field top_char string
---@field bottom_char string

---@class NeoGlancePopupOpts
---@field preview nui_popup_options
---@field list nui_popup_options

---@class NeoGlanceWinbarOpts
---@field enable boolean

---@class NeoGlanceFoldsrOpts
---@field folded boolean
---@field fold_closed string
---@field fold_open string
---@field ellipsis string

---@class NeoGlanceIndentOpts
---@field enable boolean
---@field icon string
