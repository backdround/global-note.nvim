local utils = require("global-note.utils")

---@class GlobalNote_PresetOptions
---@field name string
---@field filename string|fun(): string? Filename of the note.
---@field directory string|fun(): string? Directory to keep notes.
---@field title string|fun(): string? Floating window title.
---@field command_name? string Ex command name.
---@field window_config table|fun(): table A nvim_open_win config.
---@field post_open fun() It's called after the window creation.
---@field autosave boolean Whether to use autosave.

---@class GlobalNote_ExpandedPreset
---@field name string
---@field filename string Filename of the note.
---@field directory string Directory to keep notes.
---@field window_config table A nvim_open_win config.
---@field post_open function It's called after the window creation.
---@field autosave boolean Whether to use autosave.

---@class GlobalNote_Preset: GlobalNote_PresetOptions

---Creates a new preset from data.
---@param options GlobalNote_PresetOptions
---@return GlobalNote_Preset
local new = function(options)
  vim.validate({
    ["options.filename"] = {
      options.filename,
      { "string", "function" },
    },
    ["options.directory"] = {
      options.directory,
      { "string", "function" },
    },
    ["options.title"] = {
      options.title,
      { "string", "function" },
    },
    ["options.command_name"] = {
      options.command_name,
      { "string", "nil" },
    },
    ["options.window_config"] = {
      options.window_config,
      { "table", "function" },
    },
    ["options.post_open"] = {
      options.post_open,
      { "function" },
    },
    ["options.autosave"] = {
      options.autosave,
      { "boolean" },
    },
  })

  ---@class GlobalNote_Preset
  local p = vim.deepcopy(options)

  if type(p.command_name) == "string" and p.command_name ~= "" then
    local desc = "Toggle note in a floating window"
    if p.name ~= "" then
      desc = string.format("Toggle %s note in a floating window", p.name)
    end

    vim.api.nvim_create_user_command(p.command_name, function()
      p:toggle()
    end, {
      nargs = 0,
      desc = desc
    })
  end

  ---Expands preset fields to a finite values.
  ---If user can't produce a critical value then nil is returned.
  ---@return GlobalNote_ExpandedPreset?
  function p:_expand_options()
    local filename = self.filename
    if type(filename) == "function" then
      ---@diagnostic disable-next-line: cast-local-type
      filename = filename()
      if filename == nil then
        return
      end
      if type(filename) ~= "string" or filename == "" then
        error("Filename function should return a non empty string")
      end
    end

    local directory = self.directory
    if type(directory) == "function" then
      ---@diagnostic disable-next-line: cast-local-type
      directory = directory()
      if directory == nil then
        return
      end
      if type(directory) ~= "string" or directory == "" then
        error("Directory function should return a non empty string")
      end
    end
    directory = vim.fn.expand(directory)

    local window_config = self.window_config
    if type(window_config) == "function" then
      window_config = window_config()
      if type(window_config) ~= "table" then
        error("Window_config should return a table")
      end
    end

    local title = self.title
    if type(title) == "function" then
      ---@diagnostic disable-next-line: cast-local-type
      title = title()
      if type(title) ~= "string" and title ~= nil then
        error("Title function should return a string or a nil")
      end
    end

    if title ~= nil then
      window_config.title = title
    end

    return {
      name = self.name,
      filename = filename,
      directory = directory,
      window_config = window_config,
      post_open = self.post_open,
      autosave = self.autosave,
    }
  end

  ---Opens or closes the preset in a floating window.
  function p:toggle()
    local expanded_preset = self:_expand_options()
    if expanded_preset == nil then
      return
    end

    -- Get buffer
    local filepath =
      vim.fs.joinpath(expanded_preset.directory, expanded_preset.filename)
    utils.ensure_directory_exists(expanded_preset.directory)
    utils.ensure_file_exists(filepath)

    local buffer_id = vim.fn.bufadd(filepath)
    if buffer_id == nil then
      error("Unreachable: The file should exist, but it doesn't: " .. filepath)
    end

    -- Close windows from current preset if they are already open.
    local something_was_closed = false
    local window_ids = vim.api.nvim_tabpage_list_wins(0)
    for _, window_id in ipairs(window_ids) do
      if vim.w[window_id].global_note_window == expanded_preset.name then
        vim.api.nvim_win_close(window_id, false)
        something_was_closed = true
      end
    end

    if something_was_closed then
      return
    end

    -- Open a new floating window
    local window_id =
      vim.api.nvim_open_win(buffer_id, true, expanded_preset.window_config)
    vim.w[window_id].global_note_window = expanded_preset.name

    if expanded_preset.autosave then
      local save_file = function()
        vim.api.nvim_buf_call(buffer_id, function()
          if vim.bo[buffer_id].modified then
            vim.cmd.write({ mods = { silent = true } })
          end
        end)
      end

      vim.api.nvim_create_autocmd({ "WinClosed", "ExitPre" }, {
        callback = function(event)
          local win_closed_event = event.event == "WinClosed"
            and event.match == tostring(window_id)
          local exit_pre_event = event.event == "ExitPre"

          if win_closed_event or exit_pre_event then
            save_file()
            return true
          end
        end,
      })
    end

    expanded_preset.post_open()
  end

  return p
end

return {
  new = new,
}
