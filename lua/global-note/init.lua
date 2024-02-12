local utils = require("global-note.utils")

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

---@class GlobalNote_Preset
---@field filename string|fun(): string Filename of the note.
---@field directory string|fun(): string Directory to keep notes.
---@field title string|fun(): string Floating window title.
---@field command_name? string Ex command name.
---@field window_config table|fun(): table A nvim_open_win config.
---@field post_open fun() It's called after the window creation.
---@field autosave boolean Whether to use autosave.

---@param preset_name? string
---@param preset GlobalNote_Preset
M._setup_preset = function(preset_name, preset)
  vim.validate({
    ["options.filename"] = {
      preset.filename,
      { "string", "function" },
    },
    ["options.directory"] = {
      preset.directory,
      { "string", "function" },
    },
    ["options.title"] = {
      preset.title,
      { "string", "function" },
    },
    ["options.command_name"] = {
      preset.command_name,
      { "string", "nil" },
    },
    ["options.window_config"] = {
      preset.window_config,
      { "table", "function" },
    },
    ["options.post_open"] = {
      preset.post_open,
      { "function" },
    },
    ["options.autosave"] = {
      preset.autosave,
      { "boolean" },
    },
  })

  if type(preset.command_name) == "string" and preset.command_name ~= "" then
    local open_note = function()
      M.open_note(preset_name)
    end

    local desc = "Open note in a floating window"
    if preset_name ~= nil then
      desc = string.format("Open %s note in a floating window", preset_name)
    end

    vim.api.nvim_create_user_command(preset.command_name, open_note, {
      nargs = 0,
      desc = desc
    })
  end
end

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
  M._default_preset =
    vim.tbl_extend("force", M._default_preset_default_values, user_options)
  M._default_preset.additional_presets = nil
  M._setup_preset(nil, M._default_preset)

  -- Setup other presets
  M._presets = {}
  for key, value in pairs(user_options.additional_presets) do
    M._presets[key] = vim.tbl_extend("force", M._default_preset, value)
    if M._presets[key].command_name == M._default_preset.command_name then
      M._presets[key].command_name = nil
    end
    M._setup_preset(key, M._presets[key])
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

  local filename = preset.filename
  if type(filename) == "function" then
    filename = filename()
    if type(filename) ~= "string" or filename == "" then
      error("Filename function should return a non empty string")
    end
  end

  local directory = preset.directory
  if type(directory) == "function" then
    directory = directory()
    if type(directory) ~= "string" or directory == "" then
      error("Directory function should return a non empty string")
    end
  end
  directory = vim.fn.expand(directory)

  local filepath = vim.fs.joinpath(directory, filename)
  utils.ensure_directory_exists(directory)
  utils.ensure_file_exists(filepath)

  local buffer_id = vim.fn.bufadd(filepath)
  if buffer_id == nil then
    error("Unreachable: The file should exist, but it doesn't: " .. filepath)
  end

  local window_config = preset.window_config
  if type(window_config) == "function" then
    window_config = window_config()
    if type(window_config) ~= "table" then
      error("Window_config should return a table")
    end
  end

  local title = preset.title
  if type(title) == "function" then
    title = title()
    if type(title) ~= "string" and title ~= nil then
      error("Title function should return a string or a nil")
    end
  end

  if title ~= nil then
    window_config.title = title
  end

  vim.api.nvim_open_win(buffer_id, true, window_config)

  if preset.autosave then
    vim.api.nvim_create_autocmd({ "BufWinLeave", "ExitPre" }, {
      callback = function(event)
        if event.buf ~= buffer_id then
          return
        end
        if vim.bo[buffer_id].modified then
          vim.cmd.write({ mods = { silent = true } })
        end
        return true
      end
    })
  end

  preset.post_open()
end

return M
