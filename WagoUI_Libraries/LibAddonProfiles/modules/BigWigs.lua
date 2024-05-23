local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return BigWigs and true or false
end

---@return boolean
local needsInitialization = function()
  return BigWigs3DB and not isLoaded()
end

---@return nil
local openConfig = function()
  SlashCmdList["BigWigs"]()
end

local optionsFrame
---@return nil
local closeConfig = function()
  local function findBWFrame()
    for i = 1, select("#", UIParent:GetChildren()) do
      local childFrame = select(i, UIParent:GetChildren())
      if childFrame and childFrame.obj and childFrame.obj.titletext then
        if childFrame.obj.titletext:GetText("BigWigs") then
          return childFrame
        end
      end
    end
  end
  optionsFrame = optionsFrame or findBWFrame()
  if optionsFrame then
    optionsFrame:Hide()
  end
end

---@return table<string, any>
local getProfileKeys = function()
  return BigWigs3DB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local characterName = UnitName("player").." - "..GetRealmName()
  return BigWigs3DB.profileKeys and BigWigs3DB.profileKeys[characterName]
end

---@param profileKey string
local setProfile = function(profileKey)
  BigWigs.db:SetProfile(profileKey)
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
  if profileKey and profileData and profileData.BigWigs3DB then
    return profileKey
  end
end

---@param profileString string
---@param profileKey string
---@param isDuplicateProfile boolean
local importProfile = function(profileString, profileKey, isDuplicateProfile)
  local _, pData = private:GenericDecode(profileString)
  if not pData then return end
  local bw3db = pData.BigWigs3DB
  local bw3Idb = pData.BigWigsIconDB
  --namespaces
  for namespaceKey, namespace in pairs(bw3db.namespaces) do
    if namespace.profiles then
      for _, profile in pairs(namespace.profiles) do
        BigWigs3DB.namespaces = BigWigs3DB.namespaces or {}
        BigWigs3DB.namespaces[namespaceKey] = BigWigs3DB.namespaces[namespaceKey] or {}
        BigWigs3DB.namespaces[namespaceKey].profiles = BigWigs3DB.namespaces[namespaceKey].profiles or {}
        BigWigs3DB.namespaces[namespaceKey].profiles[profileKey] = profile
      end
    end
  end
  --profileKey
  BigWigs3DB.profileKeys = BigWigs3DB.profileKeys or {}
  BigWigs3DB.profileKeys[UnitName("player").." - "..GetRealmName()] = profileKey
  --profiles
  for _, profile in pairs(bw3db.profiles) do
    BigWigs3DB.profiles = BigWigs3DB.profiles or {}
    BigWigs3DB.profiles[profileKey] = profile
  end
  --icon position
  BigWigsIconDB = bw3Idb
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return nil end
  local data = {
    BigWigs3DB = {
      profiles = {
        [profileKey] = BigWigs3DB.profiles[profileKey]
      },
      profileKeys = {
        [""] = profileKey
      },
      namespaces = {},
    },
    BigWigsIconDB = {
      hide = BigWigsIconDB.hide,
      minimapPos = BigWigsIconDB.minimapPos,
    },
  }
  for namespaceKey, namespace in pairs(BigWigs3DB.namespaces) do
    if namespace.profiles then
      for pKey, p in pairs(namespace.profiles) do
        if pKey == profileKey then
          data.BigWigs3DB.namespaces[namespaceKey] = {
            profiles = {
              [profileKey] = p
            }
          }
        end
      end
    end
  end
  return private:GenericEncode(profileKey, data)
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  local _, profileDataA = private:GenericDecode(profileStringA)
  local _, profileDataB = private:GenericDecode(profileStringB)
  if not profileDataA or not profileDataB then return false end
  return private:DeepCompareAsync(profileDataA, profileDataB)
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "BigWigs",
  slash = "/bigwigs",
  icon = 134337,
  needReloadOnImport = true,
  needsInitialization = needsInitialization,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isLoaded = isLoaded,
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
