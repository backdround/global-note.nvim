local utils = require("global-note.utils")

local M = {}

---@class GlobalNote_Preset
---@field filename string|fun(): string Filename of the note.
---@field directory string|fun(): string Directory to keep notes.
---@field title string|fun(): string Floating window title.
---@field command_name? string Ex command name.
---@field window_config table|fun(): table A nvim_open_win config.
---@field post_open fun() It's called after the window creation.
---@field autosave boolean Whether to use autosave.

---Validates the given preset.
---@param preset GlobalNote_Preset
M.validate = function(preset)
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
end

---@class GlobalNote_ExpandedPreset
---@field filename string Filename of the note.
---@field directory string Directory to keep notes.
---@field window_config table A nvim_open_win config.
---@field post_open function It's called after the window creation.
---@field autosave boolean Whether to use autosave.

---Expands a preset.
---@param preset GlobalNote_Preset
---@return GlobalNote_ExpandedPreset
M.expand = function(preset)
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

  return {
    filename = filename,
    directory = directory,
    window_config = window_config,
    post_open = preset.post_open,
    autosave = preset.autosave,
  }
end

---@param preset GlobalNote_ExpandedPreset
M.open_in_float_window = function(preset)
  local filepath = vim.fs.joinpath(preset.directory, preset.filename)
  utils.ensure_directory_exists(preset.directory)
  utils.ensure_file_exists(filepath)

  local buffer_id = vim.fn.bufadd(filepath)
  if buffer_id == nil then
    error("Unreachable: The file should exist, but it doesn't: " .. filepath)
  end

  vim.api.nvim_open_win(buffer_id, true, preset.window_config)

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
