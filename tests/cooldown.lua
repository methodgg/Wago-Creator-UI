-- Regression checks for capacity refusal and failed replacement recovery.
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
local private = { modules = {} }
local namespace = { GetLibAddonProfilesInternal = function() return private end }
local layouts = { [1] = { layoutID = 1, layoutName = "Current", classAndSpecTag = 121 } }
local removes, restores = 0, 0
function geterrorhandler() return function() end end
local manager = {}
function manager:EnumerateLayouts() return nil, layouts end
function manager:AreLayoutsFullyMaxed() return true end
function manager:GetActiveLayoutID() return 1 end
function manager:RemoveLayout(id) layouts[id] = nil; removes = removes + 1 end
function manager:GetSerializer() return { SerializeLayouts = function() return "backup" end } end
function manager:CreateLayoutsFromSerializedData(data)
  if data == "throw" then error("Malformed layout") end
  if data == "backup" then
    restores = restores + 1
    layouts[2] = { layoutID = 2, layoutName = "Current", classAndSpecTag = 121 }
    return { 2 }
  end
end
function manager:SetActiveLayoutByID(id) assert(layouts[id]) end
function manager:SaveLayouts() end
CooldownViewerSettings = { GetLayoutManager = function() return manager end }
assert(loadfile("WagoUI_Libraries/LibAddonProfiles/modules/CooldownManager.lua"))("WagoUI", namespace)
local module = private.modules["Blizzard Cooldown Manager"]
assert(module:importProfile("new", "New") == false)
assert(removes == 0 and layouts[1], "Full manager deleted an existing layout")
assert(module:importProfile("broken", "Current") == false)
assert(removes == 1 and restores == 1 and layouts[2], "Failed update lost the previous layout")
assert(module:importProfile("throw", "Current") == false)
assert(removes == 2 and restores == 2 and layouts[2], "Throwing import lost the previous layout")
print("Cooldown Manager capacity and replacement checks passed.")
