local utils = require("global-note.utils")

local M = {
  _inited = false,

  _default_config = {
    ---@diagnostic disable-next-line: param-type-mismatch
    directory = vim.fs.joinpath(vim.fn.stdpath("data"), "global-note"),

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

---@class GlobalNote_Options
---@field directory? string Directory to keep notes.
---@field get_window_config? fun(): table It should return a nvim_open_win config.
---@field post_open? function It's called after the window creation.

M.setup = function(options)
  options = options or {}
  vim.validate({
    ["options.directory"] = {
      options.directory,
      { "string", "nil" },
    },
    ["options.get_window_config"] = {
      options.get_window_config,
      { "function", "nil" },
    },
    ["options.post_open"] = {
      options.post_open,
      { "function", "nil" },
    },
  })

  M._directory = options.directory or M._default_config.directory
  M._get_window_config = options.get_window_config
    or M._default_config.get_window_config
  M._post_open = options.post_open or M._default_config.post_open

  utils.ensure_directory_exists(M._directory)
  M._inited = true
end

---Opens the given note in a floating window.
---@param filename string filename
---@param title? string title for a floating window.
M.open_note = function(filename, title)
  vim.validate({
    filename = { filename, "string" },
    title = { title, { "string", "nil" } },
  })

  if not M._inited then
    M.setup()
  end

  local filepath = vim.fs.joinpath(M._directory, filename)
  utils.ensure_file_exists(filepath)

  local buffer_id = vim.fn.bufadd(filepath)
  if buffer_id == nil then
    error("The file should exist, but it doesn't: " .. filepath)
  end

  local window_config = M._get_window_config()
  if title ~= nil then
    window_config.title = title
  end

  vim.api.nvim_open_win(buffer_id, true, window_config)
  M._post_open()
end

return M
