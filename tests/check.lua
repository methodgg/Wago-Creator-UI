-- Run from the repository root: lua tests/check.lua (Lua 5.1).
local addon = { db = {}, dbC = {}, state = {}, frames = {} }
local modules, imports, errors, prompts = {}, {}, {}, {}
local LAP = {}
function LAP:GetModule(name) return modules[name] end
function LAP:GetAllModules() return modules end
function LAP:CanEnableAnyAddOn() return true end
function LAP:EnableAddOns() end
function LAP:DisableConflictingAddons() end
local asyncLib = {}
function asyncLib:Await(register) register(function() end); coroutine.yield() end
function LibStub(name) return name == "LibAsync" and asyncLib or LAP end
C_Timer = { After = function(_, callback) callback() end }
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
function UnitName() return "Creator" end
function UnitGUID() return "Player-1-001" end
function GetRealmName() return "Realm" end
local clock = 100
function GetServerTime() return clock end
date = os.date
function GetBuildInfo() return "", "", "", 120100 end
function InCombatLockdown() return false end
C_AddOns = { LoadAddOn = function() end, IsAddOnLoaded = function() return false end }
function CopyTable(value)
  local out = {}
  for k, v in pairs(value) do out[k] = type(v) == "table" and CopyTable(v) or v end
  return out
end
function addon:RefreshWorkspace() end
function addon:SuppressAddOnSpam() end
function addon:ToggleReloadIndicator() end
function addon:AddonPrintError(message) table.insert(errors, message) end
function addon:ShowPrompt(message, yes) table.insert(prompts, { message, yes }) end
function addon:Async(callback)
  local thread = coroutine.create(callback)
  repeat
    local ok, problem = coroutine.resume(thread)
    assert(ok, problem)
  until coroutine.status(thread) == "dead"
end
local function load(path) assert(loadfile(path))("WagoUI", addon) end
load("WagoUI/core/Packs.lua")
load("WagoUI/core/Capture.lua")
load("WagoUI/core/Install.lua")
addon:InitializePacks()
local P = addon.Packs
local function rejects(callback)
  assert(not pcall(callback), "Expected rejection")
end
local pack = addon:NewPack("My UI")
local first = P.AddProfile(pack, "Test", "Raid", "Raid")
assert(pack.profiles[first].variations.default)
rejects(function() P.AddProfile(pack, "Test", "Other", "Other") end)
local compact = P.SaveVariation(pack, nil, "Compact", { { width = 1920, height = 1080 } }, "")
local second = P.AddProfile(pack, "Test", "Other", "Other", { [compact] = true, default = true })
P.SetMembership(pack, first, { [compact] = true })
assert(not pack.profiles[first].variations.default)
P.SaveVariation(pack, compact, "Small", nil, "Optional")
assert(pack.profiles[first].variations[compact] and pack.variations[compact].resolutions == nil)
rejects(function() P.SaveVariation(pack, nil, "small") end)
rejects(function() P.SaveVariation(pack, nil, "Bad", { { width = 0, height = 1080 } }) end)
rejects(function() P.SetMembership(pack, first, { missing = true }) end)
rejects(function() P.AddProfile(pack, "Test", "Raid", "Duplicate", { default = true }) end)
local shared = P.SaveVariation(pack, nil, "Shared", nil, "", true)
assert(pack.profiles[second].variations[shared] and not pack.profiles[first].variations[shared])
P.RemoveVariation(pack, compact)
assert(pack.profiles[first] and not next(pack.profiles[first].variations))
assert(pack.profiles[second].variations.default)
rejects(function() P.RemoveVariation(pack, "default") end)
assert(P.Validate(pack))
local bad = CopyTable(pack)
bad.profiles[first].variations.gone = true
assert(not P.Validate(bad))
bad = CopyTable(pack); bad.profileOrder[2] = first; assert(not P.Validate(bad))
bad = CopyTable(pack); bad.profiles[first].kind = "group"; assert(not P.Validate(bad))
assert(not P.Validate({ schemaVersion = 1 }))
local loose = P.New("loose", "Loose")
P.AddProfile(loose, "Test", "Raid", "Raid")
local unassigned = P.AddProfile(loose, "Test", "Other", "Other", {})
assert(not next(loose.profiles[unassigned].variations) and P.Validate(loose), "Explicitly unassigned alternate was rejected")
local exports = 0
modules.Test = {
  moduleName = "Test", addonNames = { "Test" },
  needsInitialization = function() return false end,
  isLoaded = function() return true end, isUpdated = function() return true end,
  getProfileKeys = function() return { Raid = true, Other = true } end,
  exportProfile = function(_, key) exports = exports + 1; return "payload-" .. key end,
  areProfileStringsEqual = function(_, a, b) return a == b end,
  importProfile = function(_, data, key) table.insert(imports, key); return key ~= "Other" end,
}
local captured, changes
addon:CapturePack(pack, nil, function(p, c) captured, changes = p, c end)
pack = captured
assert(exports == 2, "Shared profile exported more than once")
assert(pack.profiles[first].data == "payload-Raid" and #changes > 0)
addon:SaveCapturedPack(pack, "First")
P.SetMembership(pack, first, { default = true, [shared] = true })
addon:CapturePack(pack, nil, function(p, c) captured, changes = p, c end)
pack = captured
assert(#changes == 1 and changes[1] == "Pack settings", "Metadata-only edit lost")
addon:SaveCapturedPack(pack, "Tags")
local saved = addon.db.creator.saved[pack.id]
local oldExport = modules.Test.exportProfile
modules.Test.exportProfile = function() return nil, false end
local issues
addon:CapturePack(pack, nil, function(p, _, i) captured, issues = p, i end)
pack = captured
assert(#issues == 2 and pack.profiles[first].data == "payload-Raid")
assert(saved.profiles[first].data == "payload-Raid")
modules.Test.exportProfile = oldExport
addon.dbC.selection.packID, addon.dbC.selection.variationID = pack.id, "default"
assert(addon:BuildInstallPlan(pack, "default") == nil, "Ambiguous ordinary profiles auto-selected")
local choices = addon:InstallChoices(pack, "default")
choices.Test = first
local plan = addon:BuildInstallPlan(pack, "default")
assert(#plan == 1 and plan[1].id == first)
addon:ImportProfiles(pack, plan, function(count, failed) assert(count == 1 and #failed == 0) end)
assert(addon:GetProfileHistory(pack.id, first).profileKey == "Raid")
addon.dbC.selection.variationID = shared
assert(addon:GetProfileHistory(pack.id, first), "Shared history lost after switching variation")
addon:ImportProfiles(pack, { pack.profiles[second] }, function(count, failed) assert(count == 0 and #failed == 1) end)
assert(not addon:GetProfileHistory(pack.id, second), "Rejected import recorded as success")
local oldLoaded, oldUpdated = modules.Test.isLoaded, modules.Test.isUpdated
modules.Test.isLoaded = function() return false end
modules.Test.isUpdated = function() error("Disabled addon API must not be queried") end
assert(addon:ProfileStatus(pack.profiles[first]) == "Enable addon")
modules.Test.isLoaded, modules.Test.isUpdated = oldLoaded, oldUpdated
choices.Test = false
assert(#addon:BuildInstallPlan(pack, "default") == 0)
local another = addon:NewPack("Other pack")
assert(not next(another.profiles) and another.id ~= pack.id)
-- Cached layouts retain provenance and class eligibility.
local layout = P.AddProfile(another, "Blizzard Cooldown Manager", "Layout", "Layout", nil, "cdm", "Alt - Realm", 121)
addon.db.creator.cdmCache["Alt - Realm"] = { Layout = { data = "cdm", classAndSpecTag = 121 } }
CooldownViewerSettings = {}
CooldownViewerUtil = { GetCurrentClassAndSpecTag = function() return 122 end }
modules["Blizzard Cooldown Manager"] = {
  needsInitialization = function() return false end,
  isLoaded = function() return true end, isUpdated = function() return true end,
  getProfileKeys = function() return {} end,
}
addon:CapturePack(another, nil, function(p) captured = p end)
assert(captured.profiles[layout].data == "cdm")
assert(addon:ProfileStatus(captured.profiles[layout]) == "Ready")
CooldownViewerUtil.GetCurrentClassAndSpecTag = function() return 71 end
assert(addon:ProfileStatus(captured.profiles[layout]) == "Class incompatible")
-- Multiple global snapshots capture independently, then remain frozen on Save All.
modules.Global = CopyTable(modules.Test)
modules.Global.moduleName = "Global"
modules.Global.getProfileKeys = function() return { Global = true } end
local snapshots = addon:NewPack("Snapshots")
local a = P.AddProfile(snapshots, "Global", "Global", "One", nil, "snapshot")
local b = P.AddProfile(snapshots, "Global", "Global", "Two", { default = true }, "snapshot")
addon:CapturePack(snapshots, nil, function(p) captured = p end)
snapshots = captured
modules.Global.exportProfile = function() return "changed" end
addon:CapturePack(snapshots, nil, function(p) captured = p end)
assert(captured.profiles[a].data == "payload-Global")
addon:CapturePack(captured, b, function(p) captured = p end)
assert(captured.profiles[a].data == "payload-Global" and captured.profiles[b].data == "changed")
-- Creator order retains loaded/disabled/missing groups and the established order within each.
local fixtures = {
  { "Blizzard Edit Mode", "loaded" }, { "ElvUI", "outdated" }, { "BigWigs", "loaded" },
  { "Details", "disabled" }, { "Plater", "disabled" }, { "BugSack", "initialize" },
  { "Bartender4", "missing" }, { "Cell", "missing" },
}
for _, fixture in ipairs(fixtures) do
  local name, state = fixture[1], fixture[2]
  assert(not modules[name])
  modules[name] = {
    moduleName = name, addonNames = { state },
    isLoaded = function() return state == "loaded" or state == "outdated" end,
    isUpdated = function()
      assert(state == "loaded" or state == "outdated", "Queried version of an unloaded addon")
      return state ~= "outdated"
    end,
    needsInitialization = function() return state == "initialize" end,
    getProfileKeys = function() return {} end,
  }
end
local oldCanEnable, oldEnable = LAP.CanEnableAnyAddOn, LAP.EnableAddOns
local oldReload, oldPending = addon.state.needReload, addon.state.creatorEnabled
local enabled
function LAP:CanEnableAnyAddOn(names) return names and (names[1] == "disabled" or names[1] == "initialize") end
function LAP:EnableAddOns(names) enabled = names[1] end
local ordered, positions, states = addon:CreatorAddons(), {}, {}
for index, info in ipairs(ordered) do positions[info.name], states[info.name] = index, info.status end
local previous = 0
for _, fixture in ipairs(fixtures) do
  assert(positions[fixture[1]] > previous, "Creator order changed: " .. fixture[1])
  previous = positions[fixture[1]]
end
assert(positions.Test < positions.Details, "Known disabled addon sorted before a loaded addon")
assert(states.ElvUI == "Outdated - update required" and states.Details == "Addon disabled")
assert(states.Bartender4 == "Not installed" and states.BugSack == "Needs setup")
addon:EnableCreatorAddon("Details")
assert(enabled == "disabled" and addon.state.needReload)
for _, info in ipairs(addon:CreatorAddons()) do
  if info.name == "Details" or info.name == "Plater" then assert(info.status == "Enabled after reload") end
end
LAP.CanEnableAnyAddOn, LAP.EnableAddOns = oldCanEnable, oldEnable
addon.state.needReload, addon.state.creatorEnabled = oldReload, oldPending
for _, fixture in ipairs(fixtures) do modules[fixture[1]] = nil end
modules.Test.getCurrentProfileKey = function() return "Raid" end
local sources = addon:ProfileSources("Test")
assert(sources[1].key == "Raid" and sources[1].label == "Raid (active)" and sources[2].key == "Other")
modules.Test.getCurrentProfileKey = nil
-- Release notes compare against the published capture, including cancelled saves and removals.
local release = addon:NewPack("Release test")
local releaseProfile = P.AddProfile(release, "Test", "Raid", "Raid")
local releaseVariation = P.SaveVariation(release, nil, "Wide", nil, "")
P.SetMembership(release, releaseProfile, { default = true, [releaseVariation] = true })
local progress = {}
addon:CapturePack(release, nil, function(p) release = p end, function(current, total)
  assert(total == 1 and addon.state.busy)
  progress[#progress + 1] = current
end)
assert(#progress == 2 and progress[1] == 0 and progress[2] == 1)
local notes, changed = addon:BuildReleaseNotes(release)
assert(changed and notes:find("### Default\n- Test: Raid", 1, true) and notes:find("### Wide\n- Test: Raid", 1, true))
addon:CapturePack(release, nil, function(p) release = p end)
assert(addon:BuildReleaseNotes(release) == notes, "Cancelled save lost release notes")
assert(not pcall(addon.SaveCapturedPack, addon, release, string.rep("x", 100001)), "Oversized edited release notes accepted")
assert(not addon.db.creator.saved[release.id], "Invalid release notes replaced the saved snapshot")
addon:SaveCapturedPack(release, notes)
local _, unchanged = addon:BuildReleaseNotes(release)
assert(not unchanged, "Unchanged release generates update notes")
P.SetMembership(release, releaseProfile, { default = true })
notes, changed = addon:BuildReleaseNotes(release)
assert(changed and notes:find("## Removed:\n### Wide\n- Test: Raid", 1, true))
P.RemoveProfile(release, releaseProfile)
addon:CapturePack(release, nil, function(p) release = p end)
notes, changed = addon:BuildReleaseNotes(release)
assert(changed and notes:find("## Removed:", 1, true) and notes:find("### Default\n- Test: Raid", 1, true))
addon:SaveCapturedPack(release, notes)
assert(#addon.db.creator.saved[release.id].profileOrder == 0, "Removal-only release was not saved")
release.additionalAddons.extra = "Additional test"
notes, changed = addon:BuildReleaseNotes(release)
assert(changed and notes:find("- Additional addon: Additional test", 1, true))
print("Pack, capture, installation and creator ordering/status checks passed.")
return addon, modules, asyncLib
