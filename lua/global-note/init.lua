local utils = require("global-note.utils")

local M = {
  _inited = false,

  _default_main_preset = {
    filename = "global.md",
    ---@diagnostic disable-next-line: param-type-mismatch
    directory = vim.fs.joinpath(vim.fn.stdpath("data"), "global-note"),
    title = "Global",
    command_name = "GlobalNote",
    get_window_config = function()
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
  },
}

---@class GlobalNote_Preset
---@field filename? string|fun(): string Filename of the note.
---@field directory? string Directory to keep notes.
---@field title? string Floating window title.
---@field command_name? string Ex command name.
---@field get_window_config? fun(): table It should return a nvim_open_win config.
---@field post_open? function It's called after the window creation.

---@param preset? GlobalNote_Preset
M.setup = function(preset)
  preset = preset or {}
  vim.validate({
    ["options.filename"] = {
      preset.filename,
      { "string", "function", "nil" },
    },
    ["options.directory"] = {
      preset.directory,
      { "string", "nil" },
    },
    ["options.title"] = {
      preset.title,
      { "string", "nil" },
    },
    ["options.command_name"] = {
      preset.command_name,
      { "string", "nil" },
    },
    ["options.get_window_config"] = {
      preset.get_window_config,
      { "function", "nil" },
    },
    ["options.post_open"] = {
      preset.post_open,
      { "function", "nil" },
    },
  })

  M._main_preset = vim.tbl_extend("force", M._default_main_preset, preset)
  if M._main_preset.command_name ~= "" then
    local desc = string.format("Open %s note in a floating window", "default")
    vim.api.nvim_create_user_command(M._main_preset.command_name, M.open_note, {
      nargs = 0,
      desc = desc
    })
  end
  M._inited = true
end

---Opens default preset note in a floating window.
M.open_note = function()
  if not M._inited then
    M.setup()
  end

  local preset = M._main_preset

  local filepath = vim.fs.joinpath(preset.directory, preset.filename)
  utils.ensure_directory_exists(preset.directory)
  utils.ensure_file_exists(filepath)

  local buffer_id = vim.fn.bufadd(filepath)
  if buffer_id == nil then
    error("The file should exist, but it doesn't: " .. filepath)
  end

  local window_config = preset.get_window_config()
  if preset.title ~= nil then
    window_config.title = preset.title
  end

  vim.api.nvim_open_win(buffer_id, true, window_config)
  preset.post_open()
end

return M
