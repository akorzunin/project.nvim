local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")
local conf = require("telescope.config").values

M = {}
M.filtered_builtin = function(opts)
  opts.include_extensions = vim.F.if_nil(opts.include_extensions, false)
  opts.use_default_opts = vim.F.if_nil(opts.use_default_opts, false)
  local filter_list = opts.list or { find_files = true }

  local objs = {}

  for k, v in pairs(require("telescope.builtin")) do
    local debug_info = debug.getinfo(v)
    if filter_list[k] then
      table.insert(objs, {
        filename = string.sub(debug_info.source, 2),
        text = k,
      })
    end
  end
  local title = "Telescope Builtin"

  if opts.include_extensions then
    title = "Telescope Pickers"
    for ext, funcs in pairs(require("telescope").extensions) do
      for func_name, func_obj in pairs(funcs) do
        -- Only include exported functions whose name doesn't begin with an underscore
        if type(func_obj) == "function" and string.sub(func_name, 0, 1) ~= "_" then
          local debug_info = debug.getinfo(func_obj)
          table.insert(objs, {
            filename = string.sub(debug_info.source, 2),
            text = string.format("%s : %s", ext, func_name),
          })
        end
      end
    end
  end

  -- Define a comparison function to sort the second table based on the order of keys in the first table
  local function compare(a, b)
    local indexA, indexB
    for k, v in pairs(filter_list) do
      if k == a.text then
        indexA = v
      elseif k == b.text then
        indexB = v
      end
    end
    if indexA ~= nil and indexB ~= nil then
      return indexA < indexB
    end
    return indexA ~= nil
  end

  -- Sort the second table based on the order of keys in the first table
  table.sort(objs, compare)

  opts.bufnr = vim.api.nvim_get_current_buf()
  opts.winnr = vim.api.nvim_get_current_win()
  pickers
    .new(opts, {
      prompt_title = title,
      finder = finders.new_table({
        results = objs,
        entry_maker = function(entry)
          return make_entry.set_default_entry_mt({
            value = entry,
            text = entry.text,
            display = entry.text,
            ordinal = entry.text,
            filename = entry.filename,
          }, opts)
        end,
      }),
      previewer = false,
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(_)
        actions.select_default:replace(function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if not selection then
            utils.__warn_no_selection("builtin.builtin")
            return
          end

          -- we do this to avoid any surprises
          opts.include_extensions = nil

          local picker_opts
          if not opts.use_default_opts then
            picker_opts = opts
          end

          actions.close(prompt_bufnr)
          if string.match(selection.text, " : ") then
            -- Call appropriate function from extensions
            local split_string = vim.split(selection.text, " : ")
            local ext = split_string[1]
            local func = split_string[2]
            require("telescope").extensions[ext][func](picker_opts)
          else
            -- Call appropriate telescope builtin
            require("telescope.builtin")[selection.text](picker_opts)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
