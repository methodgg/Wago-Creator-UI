-- Run from the repository root: lua tests/profile_names.lua (Lua 5.1).
-- Checks the warnings creators get for profile names players already have.
local function read(path)
  local file = assert(io.open(path, "r"))
  local text = file:read("*a")
  file:close()
  return text
end
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
C_AddOns = { GetAddOnMetadata = function() end }
function LibStub() return {} end
function UnitName() return "Nnoggie" end
function GetRealmName() return "Tarren Mill" end
CLASS_SORT_ORDER = { "WARRIOR", "MAGE" }
local classes = { { "Mage", { "Arcane", "Frost" } }, { "Warrior", { "Arms" } } }
function GetNumClasses() return #classes end
function GetClassInfo(classID) return classes[classID][1] end
function GetNumSpecializationsForClassID(classID) return #classes[classID][2] end
function GetSpecializationInfoForClassID(classID, index) return index, classes[classID][2][index] end

local private = { modules = {} }
local namespace = { GetLibAddonProfilesInternal = function() return private end }
local root = "WagoUI_Libraries/LibAddonProfiles/"
for path in read(root .. "load.xml"):gmatch('<Script file%s*=%s*["\']([^"\']+%.lua)') do
  if path:find("^modules") or path == "Utils.lua" then
    assert(loadfile(root .. path:gsub("\\", "/")))("WagoUI", namespace)
  end
end
assert(not private.modules["NaowhQOL"] and not private.modules["ElvUI Style Filters"], "Removed integration still loads")

local count = 0
for name, module in pairs(private.modules) do
  for index, profileName in pairs(module.commonProfileNames or {}) do
    assert(type(index) == "number" and type(profileName) == "string", name .. ": common profile names must be a list")
  end
  count = count + 1
end
assert(count > 50, "Modules did not load")

local function warns(moduleName, profileKey)
  return private:GetProfileNameWarning(moduleName, profileKey) ~= nil
end
-- "Default" is shared in every addon, whatever its case.
assert(warns("Plater", "Default") and warns("Method Raid Tools", "default") and warns("ElvUI", "DEFAULT"))
assert(not warns("Plater", "Nnoggie UI") and not warns("Plater", "Default 2"))
-- Per-addon extras, matched case-insensitively.
assert(warns("Plater", "MyNewProfile") and warns("Plater", "mynewprofile") and not warns("ElvUI", "MyNewProfile"))
assert(warns("HidingBar", "Profile 1") and warns("OmniCC", "Défaut") and warns("Blizzard Edit Mode", "Modern"))
-- AceDB's class profiles keep the token's case.
assert(warns("Bartender4", "WARRIOR") and not warns("Bartender4", "Warrior UI"))
-- The Cooldown Manager names unsaved layouts after class and spec.
assert(warns("Blizzard Cooldown Manager", "Mage - Frost") and not warns("Blizzard Cooldown Manager", "Mage Frost"))
-- Names taken from the creator's character or realm.
local character = private:GetProfileNameWarning("Bartender4", "Nnoggie - Tarren Mill")
assert(character and character:find("character", 1, true))
assert(warns("Details", "Nnoggie-Tarren Mill") and warns("Bartender4", "Tarren Mill") and not warns("Bartender4", "Nnoggie"))
-- Imports that ignore the name, or never replace a profile, are not flagged.
assert(not warns("Enhance QoL", "Default") and not warns("MPlusTimer", "default") and not warns("SexyMap", "Nnoggie-Tarren Mill"))
-- Settings without profiles always install as "Global".
assert(not warns("BugSack", "Global") and not warns("Unknown", "Default"))
local message = private:GetProfileNameWarning("Plater", "Default")
assert(message:find("\"Default\"", 1, true) and message:find("Rename it in Plater", 1, true))
print("Profile name warnings passed for " .. count .. " modules.")
