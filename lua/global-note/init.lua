local presets = require("global-note.presets")

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

  local create_preset_autocmd = function(command_name, preset_name)
    if type(command_name) ~= "string" or command_name == "" then
      return
    end

    local open_note = function()
      M.open_note(preset_name)
    end

    local desc = "Open note in a floating window"
    if preset_name ~= nil then
      desc = string.format("Open %s note in a floating window", preset_name)
    end

    vim.api.nvim_create_user_command(command_name, open_note, {
      nargs = 0,
      desc = desc
    })
  end

  -- Setup default preset
  M._default_preset =
    vim.tbl_extend("force", M._default_preset_default_values, user_options)
  M._default_preset.additional_presets = nil
  presets.validate(M._default_preset)
  create_preset_autocmd(M._default_preset.command_name)

  -- Setup other presets
  M._presets = {}
  for key, value in pairs(user_options.additional_presets) do
    M._presets[key] = vim.tbl_extend("force", M._default_preset, value)
    M._presets[key].command_name = value.command_name
    presets.validate(M._presets[key])
    create_preset_autocmd(M._presets[key].command_name, key)
  end

  M._inited = true
end

---Opens a note in a floating window.
---@param preset_name? string preset to use. If it's not set, use default preset.
M.open_note = function(preset_name)
  if not M._inited then
    M.setup()
  end

  local preset = M._default_preset
  if preset_name ~= nil and preset_name ~= "" then
    preset = M._presets[preset_name]
    if preset == nil then
      local template = "The preset with the name %s doesn't eixst"
      local message = string.format(template, preset_name)
      error(message)
    end
  end

  local expanded_preset = presets.expand(preset)
  presets.open_in_float_window(expanded_preset)
end

return M
