local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

local b_rshift = bit.rshift
local b_and = bit.band
local byte = string.byte

-- Plain hexadecimal encoding/decoding functions
local function HexEncode(s, title)
  local hex = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" }
  local t = { string.format("[=== %s profile ===]", title or "") }
  local j = 0
  for i = 1, #s do
    if j <= 0 then
      t[#t + 1], j = "\n", 32
    end
    j = j - 1
    --
    local b = byte(s, i)
    t[#t + 1] = hex[b_and(b, 15) + 1]
    t[#t + 1] = hex[b_and(b_rshift(b, 4), 15) + 1]
  end
  t[#t + 1] = "\n"
  t[#t + 1] = t[1]
  return table.concat(t)
end

-- Serialize current profile table into a string variable
-- Hex:  true/Encode in plain hexadecimal   false/Encode to be transmited by addon comm channel
local function grid2SerializeProfile(profileKey, Hex, exportCustomLayouts)
  --Grid2Options\modules\general\GridExportImport.lua
  --had to extend this so be able to export by profile key
  local Serializer = LibStub:GetLibrary("AceSerializer-3.0Async")
  local Compresor = LibStub:GetLibrary("LibCompress")
  local profile = Grid2.db.profiles[profileKey] --Grid2.db.profile
  local config = { ["Grid2"] = profile }
  for name, module in Grid2:IterateModules() do
    local data = Grid2.db:GetNamespace(name, true)
    if data then
      config[name] = data.profiles[profileKey]
    end
  end
  coroutine.yield()
  config["@Grid2Options"] = Grid2Options.db.profiles[profileKey]
  if exportCustomLayouts then -- Special ugly case for Custom Layouts
    local data = Grid2.db:GetNamespace('Grid2Layout', true)
    if data then
      config["@Grid2Layout"] = data.global
    end
  end
  coroutine.yield()
  local result = Compresor:CompressHuffman(Serializer:Serialize(config))
  coroutine.yield()
  if Hex then
    result = HexEncode(result, profileKey)
  else
    result = Compresor:GetAddonEncodeTable():Encode(result)
  end
  coroutine.yield()
  return result
end

local function HexDecode(s)
  -- remove header,footer and any non hex character
  s = s:gsub("%[.-%]", ""):gsub("[^0123456789ABCDEF]", "")
  if (#s == 0) or (#s % 2 ~= 0) then return false, "Invalid Hex string" end
  -- lets go decoding
  local b_lshift = bit.lshift
  local byte = string.byte
  local char = string.char
  local t = {}
  local bl, bh
  local i = 1
  repeat
    bl = byte(s, i)
    bl = bl >= 65 and bl - 55 or bl - 48
    i = i + 1
    bh = byte(s, i)
    bh = bh >= 65 and bh - 55 or bh - 48
    i = i + 1
    t[#t + 1] = char(b_lshift(bh, 4) + bl)
  until i >= #s
  return table.concat(t)
end

-- Its not a deep copy, only root keys are duplicated
local function MoveTableKeys(src, dst)
  if src and dst then
    for k, v in pairs(src) do
      dst[k] = v
    end
  end
end

-- Deserialize a profile string into a table:
-- Hex:  true/String is encoded in plain hexadecimal   false/String is encoded to be transmited through chat channels
local function UnserializeProfile(data, Hex)
  local Compresor = LibStub:GetLibrary("LibCompress")
  local err
  if Hex then
    data, err = HexDecode(data)
  else
    data, err = Compresor:GetAddonEncodeTable():Decode(data), "Error decoding profile"
  end
  if data then
    data, err = Compresor:DecompressHuffman(data)
    if data then
      return LibStub:GetLibrary("AceSerializer-3.0"):Deserialize(data)
    end
  end
  return false, nil
end

---@return boolean
local isLoaded = function()
  return Grid2 and true or false
end

---@return nil
local openConfig = function()
  SlashCmdList["ACECONSOLE_GRID2"]()
end

---@return nil
local closeConfig = function()
  LibStub("AceConfigDialog-3.0"):Close("Grid2")
end

---@return table<string, any>
local getProfileKeys = function()
  return Grid2DB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local characterName = UnitName("player").." - "..GetRealmName()
  return Grid2DB.profileKeys and Grid2DB.profileKeys[characterName]
end

---@param profileKey string
local setProfile = function(profileKey)
  Grid2.db:SetProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return getProfileKeys()[profileKey]
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  local pKey = profileString:match("%[=== (%w-) profile ===%]")
  return pKey
end

---@param profileString string
---@param profileKey string
---@param isDuplicateProfile boolean
local importProfile = function(profileString, profileKey, isDuplicateProfile)
  local success, data
  success, data = UnserializeProfile(profileString, true)
  if not success or not data then return end
  --dirty hack to initialize Grid2Options
  if not Grid2Options then
    openConfig()
    closeConfig()
  end
  if data["@Grid2Layout"] then -- Special ugly case for Custom Layouts
    local db = Grid2.db:GetNamespace("Grid2Layout", true)
    if db then
      local customLayouts = data["@Grid2Layout"].customLayouts
      if customLayouts then
        if not db.global.customLayouts then db.global.customLayouts = {} end
        MoveTableKeys(customLayouts, db.global.customLayouts)
        Grid2Layout:AddCustomLayouts()
      end
    end
  end
  local prev_Hook = Grid2.ProfileChanged
  Grid2.ProfileChanged = function(self)
    self.ProfileChanged = prev_Hook
    for key, section in pairs(data) do
      local db
      if key == "Grid2" then
        db = self.db
      elseif key == "@Grid2Options" then
        db = Grid2Options.db
      else
        db = self:GetModule(key, true) and self.db:GetNamespace(key, true)
      end
      if db then
        MoveTableKeys(section, db.profile)
      end
    end
    self:ProfileChanged()
    Grid2Options:NotifyChange()
  end
  Grid2.db:SetProfile(profileKey)
  Grid2Options:AddNewCustomLayoutsOptions()
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not C_AddOns.IsAddOnLoaded("Grid2Options") then
    openConfig()
    closeConfig()
  end
  coroutine.yield()
  return grid2SerializeProfile(profileKey, true, true)
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  local _, profileDataA = UnserializeProfile(profileStringA, true)
  local _, profileDataB = UnserializeProfile(profileStringB, true)
  if not profileDataA or not profileDataB then return false end
  return private:DeepCompareAsync(profileDataA, profileDataB)
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Grid2",
  icon = [[Interface\AddOns\Grid2\media\iconsmall]],
  slash = "/grid2",
  needReloadOnImport = true,
  needProfileKey = false,
  isLoaded = isLoaded,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  getProfileKeys = getProfileKeys,
  getCurrentProfileKey = getCurrentProfileKey,
  setProfile = setProfile,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
