local loadingAddonName, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return TalentLoadoutsEx and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  --has nothing, it's the talent frame
end

---@return nil
local closeConfig = function()

end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return false
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if profileData and profileData.TalentLoadoutsEx then
    return profileData.TalentLoadoutsEx --return the data here as we use it in import
  end
end

---@param profileString string
---@param importFilter table
local importProfile = function(profileString, importFilter)
  local pKey, data = private:GenericDecode(profileString)
  if not data or not pKey then return end
  --have to sanitize loadout names, user might have duplicates
  --get all user loadout names
  local allLoadoutNames = {}
  for _, specs in pairs(TalentLoadoutsEx) do
    for _, loadouts in pairs(specs) do
      for loadoutName, _ in pairs(loadouts) do
        allLoadoutNames[loadoutName] = true
      end
    end
  end
  --add the new loadouts but check every loadoutname
  --and change if the name already exists for the user
  local adjustedLoadoutIdx = 1
  for class, specs in pairs(data.TalentLoadoutsEx) do
    for specIdx, loadouts in pairs(specs) do
      if importFilter[class][specIdx] then
        for loadoutName, loadoutCode in pairs(loadouts) do
          if allLoadoutNames[loadoutName] then
            loadoutName = string.sub(string.sub(pKey, 1, 1)..adjustedLoadoutIdx.." "..loadoutName, 1, 12)
            adjustedLoadoutIdx = adjustedLoadoutIdx + 1
          end
          TalentLoadoutsEx[class] = TalentLoadoutsEx[class] or {}
          TalentLoadoutsEx[class][specIdx] = TalentLoadoutsEx[class][specIdx] or {}
          TalentLoadoutsEx[class][specIdx][loadoutName] = loadoutCode
        end
      end
    end
  end
  adjustedLoadoutIdx = 1
  for class, specs in pairs(data.TalentLoadoutsExGUI) do
    for specIdx, loadouts in pairs(specs) do
      if importFilter[class][specIdx] then
        for loadoutIdx, loadout in pairs(loadouts) do
          TalentLoadoutsExGUI[class] = TalentLoadoutsExGUI[class] or {}
          TalentLoadoutsExGUI[class][specIdx] = TalentLoadoutsExGUI[class][specIdx] or {}
          local loadoutName = loadout.name
          if allLoadoutNames[loadoutName] then
            loadoutName = string.sub(string.sub(pKey, 1, 1)..adjustedLoadoutIdx.." "..loadoutName, 1, 12)
            adjustedLoadoutIdx = adjustedLoadoutIdx + 1
          end
          table.insert(TalentLoadoutsExGUI[class][specIdx], {
            icon = loadout.icon,
            name = loadoutName,
          })
        end
      end
    end
  end
  TLX.Frame.RequestUpdate()
end

---@param config table | nil
---@return string | nil
local exportProfile = function(config)
  if not config then return nil end
  local data = {
    TalentLoadoutsEx = {},
    TalentLoadoutsExGUI = {}
  }
  for className, specs in pairs(TalentLoadoutsEx) do
    for specIdx, specString in pairs(specs) do
      if config[className][specIdx] then
        data.TalentLoadoutsEx[className] = data.TalentLoadoutsEx[className] or {}
        data.TalentLoadoutsEx[className][specIdx] = specString
      end
    end
  end
  for className, specs in pairs(TalentLoadoutsExGUI) do
    for specIdx, specInfo in pairs(specs) do
      if config[className][specIdx] then
        data.TalentLoadoutsExGUI[className] = data.TalentLoadoutsExGUI[className] or {}
        data.TalentLoadoutsExGUI[className][specIdx] = specInfo
      end
    end
  end
  local name = UnitName("player")
  return private:GenericEncode(name or "TLE", data)
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
  moduleName = "Talent Loadout Ex",
  icon = 134063,
  slash = "/run ToggleTalentFrame()",
  needReloadOnImport = false, --optional
  needsInitialization = needsInitialization,
  needProfileKey = false,     --optional
  preventRename = true,
  isLoaded = isLoaded,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
