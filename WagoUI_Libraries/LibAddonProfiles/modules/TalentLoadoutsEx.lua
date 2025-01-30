local loadingAddonName, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Talent Loadouts Ex",
  wagoId = "Qb6mxnNP",
  oldestSupported = "3.4.1",
  addonNames = { "TalentLoadoutsEx" },
  icon = C_AddOns.GetAddOnMetadata("TalentLoadoutsEx", "IconTexture"),
  slash = "/run ToggleTalentFrame()",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    return TalentLoadoutsEx and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    --has nothing, it's the talent frame
  end,
  closeConfig = function(self)
  end,
  isDuplicate = function(self, profileKey)
    return false
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileData and profileData.TalentLoadoutsEx then
      return profileData.TalentLoadoutsEx --return the data here as we use it in import
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString or not profileKey then return end
    if type(profileKey) ~= "table" then return end
    local importFilter = profileKey
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
            table.insert(
              TalentLoadoutsExGUI[class][specIdx],
              {
                icon = loadout.icon,
                name = loadoutName
              }
            )
          end
        end
      end
    end
    TLX.Frame.RequestUpdate()
  end,
  exportProfile = function(self, profileKey)
    if type(profileKey) ~= "table" then return end
    local config = profileKey
    if not config then return end
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
    return private:GenericEncode(name or "TLE", data, self.moduleName)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, profileDataA = private:GenericDecode(profileStringA)
    local _, profileDataB = private:GenericDecode(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}

private.modules[m.moduleName] = m
