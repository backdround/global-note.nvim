local preset = require("global-note.preset")

local M = {
  _inited = false,

  _default_preset_default_values = {
    filename = "global.md",
    ---@diagnostic disable-next-line: param-type-mismatch
    directory = vim.fs.joinpath(vim.fn.stdpath("data"), "global-note"),
    title = "Global note",
    command_name = "GlobalNote",
    window_config = function()
      local window_height = vim.api.nvim_list_uis()[1].height
      local window_width = vim.api.nvim_list_uis()[1].width
      return {
        relative = "editor",
        border = "single",
        title = "Note",
        title_pos = "center",
        width = math.floor(0.7 * window_width),
        height = math.floor(0.85 * window_height),
        row = math.floor(0.05 * window_height),
        col = math.floor(0.15 * window_width),
      }
    end,
    post_open = function() end,
    autosave = true,
  },
}

---@class GlobalNote_UserPreset
---@field filename? string|fun(): string Filename of the note.
---@field directory? string|fun(): string Directory to keep notes.
---@field title? string|fun(): string Floating window title.
---@field command_name? string Ex command name.
---@field window_config? table|fun(): table A nvim_open_win config.
---@field post_open? fun() It's called after the window creation.
---@field autosave? boolean Whether to use autosave.

---@class GlobalNote_UserConfig: GlobalNote_UserPreset
---@field additional_presets? { [string]: GlobalNote_UserPreset }

---@param options? GlobalNote_UserConfig
M.setup = function(options)
  local user_options = vim.deepcopy(options or {})

  -- Setup default preset
  local default_preset_options =
    vim.tbl_extend("force", M._default_preset_default_values, user_options)
  default_preset_options.additional_presets = nil
  M._default_preset = preset.new(nil, default_preset_options)

  -- Setup additional presets
  M._presets = {}
  for key, value in pairs(user_options.additional_presets) do
    local preset_options = vim.tbl_extend("force", M._default_preset, value)
    preset_options.command_name = value.command_name
    M._presets[key] = preset.new(key, preset_options)
  end

  M._inited = true
end

---Opens a note in a floating window.
---@param preset_name? string preset to use. If it's not set, use default preset.
M.open_note = function(preset_name)
  if not M._inited then
    M.setup()
  end

  local p = M._default_preset
  if preset_name ~= nil and preset_name ~= "" then
    p = M._presets[preset_name]
    if p == nil then
      local template = "The preset with the name %s doesn't eixst"
      local message = string.format(template, preset_name)
      error(message)
    end
  end

  p:open()
end

return M
