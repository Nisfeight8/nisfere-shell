
local vars = require("modules.variables")

local function assign_workspaces()
  local monitors = hl.get_monitors()

  table.sort(monitors, function(a, b)
    local a_laptop = a.name:match("^eDP") ~= nil
    local b_laptop = b.name:match("^eDP") ~= nil
    if a_laptop ~= b_laptop then return a_laptop end
    return a.name < b.name
  end)

  local names = {}
  for _, m in ipairs(monitors) do
    table.insert(names, m.name)
  end

  if #names == 0 then return end
  
  local per_mon = vars.workspacesPerMonitor

  local ws = 1
  for _, mon in ipairs(names) do
    for _ = 1, per_mon do
      hl.workspace_rule({ workspace = tostring(ws), monitor = mon })
      hl.dsp.workspace.move({ workspace = ws, monitor = mon })
      ws = ws + 1
    end
  end

  hl.workspace_rule({ workspace = "1", monitor = names[1], default = true })
end

assign_workspaces()

hl.on("monitor.added", assign_workspaces)
hl.on("monitor.removed", assign_workspaces)
