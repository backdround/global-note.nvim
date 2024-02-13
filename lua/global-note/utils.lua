local M = {}

---Creates the given file if it doesn't exist
---@param filepath string
M.ensure_file_exists = function(filepath)
  vim.validate({ file_path = { filepath, "string" } })

  local stat = vim.loop.fs_stat(filepath)
  if stat and stat.type == "file" then
    return
  end

  if stat and stat.type ~= "file" then
    local template = "Path %s already exists and it's not a file!"
    error(template:format(filepath))
  end

  local file, err = io.open(filepath, "w")
  if not file then
    error(err)
  end

  file:close()
end

---Creates the given directory if it doesn't exist
---@param path string
M.ensure_directory_exists = function(path)
  vim.validate({ directory_path = { path, "string" } })

  local stat = vim.loop.fs_stat(path)
  if stat and stat.type == "directory" then
    return
  end

  if stat and stat.type ~= "directory" then
    local template = "Path %s already exists and it's not a directory!"
    error(template:format(path))
  end

  local status, err = vim.loop.fs_mkdir(path, 493)

  if not status then
    error("Unable to create a directory: " .. err)
  end
end

---Checks if the given buffer is opened in a floating window.
---@param buffer_id number
---@return number? window_id
M.get_floating_window_id_with_buffer = function(buffer_id)
  local window_ids = vim.api.nvim_tabpage_list_wins(0)

  for _, window_id in ipairs(window_ids) do
    local config = vim.api.nvim_win_get_config(window_id)
    local window_buffer = vim.api.nvim_win_get_buf(window_id)

    if config.relative ~= "" and window_buffer == buffer_id then
      return window_id
    end
  end

  return nil
end

return M
