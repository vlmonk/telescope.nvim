local a = vim.api
local log = require "telescope.log"

local highlights = {}

local ns_telescope_selection = a.nvim_create_namespace "telescope_selection"
local ns_telescope_multiselection = a.nvim_create_namespace "telescope_mulitselection"
local ns_telescope_entry = a.nvim_create_namespace "telescope_entry"

local Highlighter = {}
Highlighter.__index = Highlighter

function Highlighter:new(picker)
  return setmetatable({
    picker = picker,
  }, self)
end

function Highlighter:hi_display(row, prefix, display_highlights)
  -- This is the bug that made my highlight fixes not work.
  -- We will leave the solutino commented, so the test fails.
  if not display_highlights or vim.tbl_isempty(display_highlights) then
    return
  end

  local results_bufnr = assert(self.picker.results_bufnr, "Must have a results bufnr")

  a.nvim_buf_clear_namespace(results_bufnr, ns_telescope_entry, row, row + 1)
  local len_prefix = #prefix

  for _, hl_block in ipairs(display_highlights) do
    a.nvim_buf_add_highlight(
      results_bufnr,
      ns_telescope_entry,
      hl_block[2],
      row,
      len_prefix + hl_block[1][1],
      len_prefix + hl_block[1][2]
    )
  end
end

function Highlighter:clear_display()
  if
    not self
    or not self.picker
    or not self.picker.results_bufnr
    or not vim.api.nvim_buf_is_valid(self.picker.results_bufnr)
  then
    return
  end

  a.nvim_buf_clear_namespace(self.picker.results_bufnr, ns_telescope_entry, 0, -1)
end

function Highlighter:hi_sorter(row, prompt, display)
  local picker = self.picker
  if not picker.sorter or not picker.sorter.highlighter then
    return
  end

  local results_bufnr = assert(self.picker.results_bufnr, "Must have a results bufnr")
  picker:highlight_one_row(results_bufnr, prompt, display, row)
end

function Highlighter:hi_selection(row, caret)
  local results_bufnr = assert(self.picker.results_bufnr, "Must have a results bufnr")

  a.nvim_buf_clear_namespace(results_bufnr, ns_telescope_selection, 0, -1)
  a.nvim_buf_add_highlight(results_bufnr, ns_telescope_selection, "TelescopeSelectionCaret", row, 0, #caret)

  a.nvim_buf_add_highlight(results_bufnr, ns_telescope_selection, "TelescopeSelection", row, #caret, -1)
end

function Highlighter:hi_multiselect(row, is_selected)
  local results_bufnr = assert(self.picker.results_bufnr, "Must have a results bufnr")

  if is_selected then
    vim.api.nvim_buf_add_highlight(results_bufnr, ns_telescope_multiselection, "TelescopeMultiSelection", row, 0, -1)
  else
    local existing_marks = vim.api.nvim_buf_get_extmarks(
      results_bufnr,
      ns_telescope_multiselection,
      { row, 0 },
      { row, -1 },
      {}
    )

    -- This is still kind of weird to me, since it seems like I'm erasing stuff
    -- when i shouldn't... perhaps it's a bout the gravity of the extmark?
    if #existing_marks > 0 then
      log.trace("Clearning row: ", row)

      vim.api.nvim_buf_clear_namespace(results_bufnr, ns_telescope_multiselection, row, row + 1)
    end
  end
end

highlights.new = function(...)
  return Highlighter:new(...)
end

return highlights
