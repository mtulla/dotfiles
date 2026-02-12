local dap = require "dap"

-- Go adapter configuration using delve
dap.adapters.go = {
  type = "server",
  port = "${port}",
  executable = {
    command = "dlv",
    args = { "dap", "-l", "127.0.0.1:${port}" },
  },
}

-- Go debugging configurations
dap.configurations.go = {
  {
    type = "go",
    name = "Debug",
    request = "launch",
    program = "${file}",
  },
  {
    type = "go",
    name = "Debug (current package)",
    request = "launch",
    program = "${fileDirname}",
  },
  {
    type = "go",
    name = "Debug test",
    request = "launch",
    mode = "test",
    program = "${file}",
  },
  {
    type = "go",
    name = "Debug test (current package)",
    request = "launch",
    mode = "test",
    program = "${fileDirname}",
  },
  {
    type = "go",
    name = "Attach to process",
    request = "attach",
    mode = "local",
    processId = require("dap.utils").pick_process,
  },
}
