local M = {}

local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local project = require("project_nvim.project")

function M.change_working_directory(prompt_bufnr, prompt)
  local selected_entry = state.get_selected_entry(prompt_bufnr)
  -- if selected_entry == nil then
  --   actions.close(prompt_bufnr)
  --   return
  -- end
  local project_path = selected_entry.value
  P("project_path")
  P(project_path)
  -- if prompt == true then
  --   actions._close(prompt_bufnr, true)
  -- else
  --   actions.close(prompt_bufnr)
  -- end
  local cd_successful = project.set_pwd(project_path.filename, "global")
  return project_path, cd_successful
end

return M
