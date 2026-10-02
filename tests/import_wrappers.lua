-- Exercise the actual synchronous API wrappers with success, rejection and errors.
local function read(path)
  local file = assert(io.open(path, "r"))
  local text = file:read("*a"):gsub("\r\n", "\n")
  file:close()
  return text
end
local reported = 0
function geterrorhandler() return function() reported = reported + 1 end end
local count = 0
local root = "WagoUI_Libraries/LibAddonProfiles/"
for path in read(root .. "load.xml"):gmatch('file%s*=%s*["\']([^"\']+%.lua)') do
  local source = read(root .. path:gsub("\\", "/"))
  local body = source:match("  importProfile = (function.-)\n  end,")
  if body and body:find("local ok, accepted = xpcall", 1, true) and not body:find("local E = ElvUI[1]", 1, true) then
    local target = assert(body:match("return ([%w_%.:]+)%("))
    local parts = {}
    for part in target:gmatch("[%w_]+") do table.insert(parts, part) end
    local parent = _G
    for index = 1, #parts - 1 do parent[parts[index]] = {}; parent = parent[parts[index]] end
    local import = assert(loadstring("return " .. body .. "\nend", path))()
    local key = parts[#parts]
    parent[key] = function() end
    assert(import({}, "payload", "Raid") == true, path .. ": void success rejected")
    parent[key] = function() return false end
    assert(import({}, "payload", "Raid") == false, path .. ": rejection lost")
    parent[key] = function() error("failed import") end
    assert(import({}, "payload", "Raid") == false, path .. ": error lost")
    count = count + 1
  end
end
assert(count >= 33 and reported == count, "Import wrapper coverage missing")
print(count .. " synchronous import wrappers passed success/rejection/error checks.")

local function importer(filename)
  local body = assert(read(root .. "modules/" .. filename):match("  importProfile = (function.-)\n  end,"))
  return assert(loadstring("return " .. body .. "\nend", filename))()
end
for _, filename in ipairs({ "ElvUI.lua", "ElvUIAuraFilters.lua", "ElvUIGlobal.lua", "ElvUIStyleFilters.lua" }) do
  local distributor = { Decode = function() return "profile", nil, {} end, SetImportedProfile = function() end }
  ElvUI = { { GetModule = function() return distributor end } }
  local import = importer(filename)
  assert(import({}, "payload", "Raid") == true)
  distributor.SetImportedProfile = function() return false end
  assert(import({}, "payload", "Raid") == false, filename .. ": API rejection lost")
  distributor.SetImportedProfile = function() error("Import failed") end
  assert(import({}, "payload", "Raid") == false, filename .. ": import error lost")
  distributor.Decode = function() end
  assert(import({}, "payload", "Raid") == false, filename .. ": invalid payload accepted")
end
ElvPrivateDB = { profileKeys = {}, profiles = {} }
local distributor = { Decode = function() end, blacklistedKeys = { private = {} } }
ElvUI = { { mynameRealm = "Character", GetModule = function() return distributor end,
  FilterTableFromBlacklist = function(_, data) return data end } }
local privateImport = importer("ElvUIPrivate.lua")
assert(privateImport({}, "payload", "Raid") == false)
distributor.Decode = function() return nil, nil, {} end
privateImport({}, "payload", "Raid")
assert(ElvPrivateDB.profiles.Raid)

local wa = importer("WeakAuras.lua")
decodeWeakAuraString = function() return {} end
WeakAuras = { Import = function() end }
assert(wa({}, "payload") == true)
WeakAuras.Import = function() return false end
assert(wa({}, "payload") == false)
WeakAuras.Import = function() error("Aura import failed") end
assert(wa({}, "payload") == false, "WeakAura import error swallowed")
decodeWeakAuraString = function() end
assert(wa({}, "payload") == false, "Invalid WeakAura payload accepted")

local activated = false
local msuf = importer("MidnightSimpleUnitFrames.lua")
local module = { setProfile = function() activated = true end }
MSUF_ImportExternal = function() return false end
assert(msuf(module, "payload", "Raid") == false and not activated)
MSUF_ImportExternal = function() error("Import failed") end
assert(msuf(module, "payload", "Raid") == false and not activated)
MSUF_ImportExternal = function() return true end
assert(msuf(module, "payload", "Raid") == true and activated)

private = { GenericDecode = function() return nil, { setting = "new" } end }
ShadowUF = { db = { profile = { setting = "old" }, SetProfile = function() error("Switch failed") end },
  LoadDefaultLayout = function() end, ProfilesChanged = function() end }
local suf = importer("ShadowedUnitFrames.lua")
assert(suf({}, "payload", "Raid") == false and ShadowUF.db.profile.setting == "old")
ShadowUF.db.SetProfile = function() end
assert(suf({}, "payload", "Raid") == true and ShadowUF.db.profile.setting == "new")
ShadowUF.ProfilesChanged = function() error("Apply failed") end
assert(suf({}, "payload", "Raid") == false)

EditModeManagerFrame = { Show = function() end, ImportLayout = function() error("Import failed") end,
  CloseButton = { Click = function() end } }
C_EditMode = { ConvertStringToLayoutInfo = function() return {} end }
StaticPopup1Button2Text = { GetText = function() return "" end }
areGlobalLayoutsFull = function() return false end
removeProfile = function() return false end
local edit = importer("EditMode.lua")
local editModule = { getProfileKeys = function() return {} end, setProfile = function() end }
assert(edit(editModule, "payload", "Raid") == false)
EditModeManagerFrame.ImportLayout = function() return false end
assert(edit(editModule, "payload", "Raid") == false)
editModule.getProfileKeys = function() return { Raid = true } end
assert(edit(editModule, "payload", "Raid") == false, "Failed Edit Mode replacement marked successful")
print("Complex import failure paths passed for ElvUI, WeakAuras, MSUF, SUF and Edit Mode.")
