# Global-note.nvim
It's a simple Neovim plugin that provides a global note in a float window.
It could also provide other global, project local, file local notes (if it's required).

### Simple configuration
```lua
local global_note = require("global-note")
global_note.setup()

vim.keymap.set("n", "<leader>n", global_note.open_note, {
  desc = "Open global note",
})
```

### Options
<details><summary>click</summary>
All options here are default:

```lua
{
  -- Filename to use for default note (preset).
  -- string or fun(): string
  filename = "global.md",

  -- Directory to keep default note (preset).
  -- string or fun(): string
  directory = vim.fs.joinpath(vim.fn.stdpath("data"), "global-note"),

  -- Floating window title.
  -- string or fun(): string
  title = "Global note",

  -- Ex command name.
  -- string
  command_name = "GlobalNote",

  -- A nvim_open_win config to show float window.
  -- table or fun(): table
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

  -- It's called after the window creation.
  -- fun()
  post_open = function() end,


  -- Whether to use autosave.
  -- boolean
  autosave = true,

  -- Additional presets to create other global, project local, file local
  -- and other notes.
  -- { [name]: table } - tables there have the same fields as the current table.
  additional_presets = {},
}
```

</details>

---

### Additional presets
You can use additional presets to have other global notes, project
local notes, file local notes or anything you can come up with.

A preset is a list of options that can be used during opening a note.
All additional presets inherit `default` preset. `default` preset is a
list of options that are in the setup's root).

Simple example:

```lua
require("global-note").setup({
  filename = "global.md",
  directory = "~/notes/",

  additional_presets = {
    projects = {
      filename = "projects-to-do.md",
      title = "List of projects",
      command_name = "ProjectsNote",
      -- All not specified options are used from the root.
    }

    food = {
      filename = "want-to-eat.md",
      title = "List of food",
      command_name = "FoodNote",
      -- All not specified options are used from the root.
    }
  }
})

-- Functions to open:
require("global-note").open_note()
require("global-note").open_note("projects")
require("global-note").open_note("food")

-- Commands to open (command_name field):
-- :GlobalNote -- by default
-- :ProjectsNote
-- :FoodNote
```
---

### Additional project-local notes (example):
<details><summary>get_project_name by cwd</summary>

```lua
local get_project_name = function()
  local project_directory, err = vim.loop.cwd()
  if project_directory == nil then
    error(err)
  end

  local project_name = vim.fs.basename(project_directory)
  if project_name == nil then
    error("Unable to get the project name")
  end

  return project_name
end
```

</details>

<details><summary>get_project_name by git</summary>

```lua
local get_project_name = function()
  local result = vim.system({
    "git",
    "rev-parse",
    "--show-toplevel",
  }, {
    text = true,
  }):wait()

  if result.stderr ~= "" then
    error(result.stderr)
  end

  local project_directory = result.stdout:gsub("\n", "")

  local project_name = vim.fs.basename(project_directory)
  if project_name == nil then
    error("Unable to get the project name")
  end

  return project_name
end
```

</details>

```lua
local global_note = require("global-note")
global_note.setup({
  additional_presets = {
    -- Presets that have the same fields as the table root (default preset).
    project_local = {
      filename = function()
        return get_project_name() .. ".md"
      end,
      title = "Project note",
      command_name = "ProjectNote",
    }
  }
})

vim.keymap.set("n", "<leader><S-n>", function()
  global_note.open_note("project_local")
end), {
  desc = "Open project note",
})
```

---