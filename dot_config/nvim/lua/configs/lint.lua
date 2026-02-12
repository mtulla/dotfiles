local lint = require "lint"
local pythonUtils = require "utils.python"
local mypy = lint.linters.mypy

-- Get python path from current workspace
local function get_python_path()
  local workspace = vim.fn.getcwd()
  return pythonUtils.getPythonPath(workspace)
end

mypy.cmd = get_python_path()
mypy.args = {
  "-m",
  "mypy",
  "--strict",
  "--show-column-numbers",
  "--show-error-end",
  "--hide-error-codes",
  "--hide-error-context",
  "--no-color-output",
  "--no-error-summary",
  "--no-pretty",
}
