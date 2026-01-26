if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
  return
end

local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function getLayoutByName(layoutName)
  local layoutManager = CooldownViewerSettings:GetLayoutManager()
  local _, layouts = layoutManager:EnumerateLayouts()
  for _, layout in pairs(layouts) do
    if layout.layoutName == layoutName then
      return layout
    end
  end
end

local function getLayoutIndexByName(layoutName)
  local layoutManager = CooldownViewerSettings:GetLayoutManager()
  local _, layouts = layoutManager:EnumerateLayouts()
  for layoutID, layout in pairs(layouts) do
    if layout.layoutName == layoutName then
      return layoutID
    end
  end
end

local removeProfile = function(profileKey)
  local layoutIndex = getLayoutIndexByName(profileKey)
  if layoutIndex then
    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    layoutManager:RemoveLayout(layoutIndex)
  end
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Blizzard Cooldown Manager",
  wagoId = "baseline",
  icon = 135724,
  slash = "/editmode",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    return true
  end,
  isUpdated = function(self)
    return true
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    CooldownViewerSettings:Show()
  end,
  closeConfig = function(self)
    CooldownViewerSettings:Hide()
  end,
  getProfileKeys = function(self)
    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    local _, layouts = layoutManager:EnumerateLayouts()
    local profileKeys = {}
    for _, layout in pairs(layouts) do
      profileKeys[layout.layoutName] = {
        profileKey = layout.layoutName,
        classAndSpecTag = tonumber(layout.classAndSpecTag),
      }
    end
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    local _, layouts = layoutManager:EnumerateLayouts()
    local activeLayoutID = layoutManager:GetActiveLayoutID()
    for layoutID, layout in pairs(layouts) do
      if activeLayoutID == layoutID then
        return layout.layoutName
      end
    end
    return ""
  end,
  getProfileAssignments = function(self)
    --stored character specific
    return nil
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return getLayoutByName(profileKey) ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then
      return
    end
    if not self:getProfileKeys()[profileKey] then
      return
    end
    local index
    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    local _, layouts = layoutManager:EnumerateLayouts()
    for i, layout in pairs(layouts) do
      if layout.layoutName == profileKey then
        index = i
        break
      end
    end
    if index then
      layoutManager:SetActiveLayoutByID(index)
    end
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end

    local profileKeys = self:getProfileKeys()
    if profileKeys[profileKey] then
      removeProfile(profileKey) --need to remove old profile with same name first for updating to work and not be confusing
    end
    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    if layoutManager:AreLayoutsFullyMaxed() then
      -- if people complain find a better solution
      -- users are warned in the UI
      removeProfile(self:getCurrentProfileKey())
    end

    local layoutIDs = layoutManager:CreateLayoutsFromSerializedData(profileString)
    layoutManager:SetActiveLayoutByID(layoutIDs[1])

    --check if spec matches, remove otherwise
    local tag = CooldownViewerUtil.GetCurrentClassAndSpecTag()
    local _, layouts = layoutManager:EnumerateLayouts()
    for i, layout in pairs(layouts) do
      if layout.layoutID == layoutIDs[1] then
        local layoutTag = tonumber(layout.classAndSpecTag);
        local playerTag = tonumber(tag);
        if math.abs(layoutTag - playerTag) > 5 then
          removeProfile(profileKey)
          print("Imported layout's class does not match current specialization. Layout has been removed.")
        end
        break
      end
    end
    -- ignore taint warning
    if StaticPopup1Button2Text:GetText() == "Ignore" then
      StaticPopup1Button2:Click()
    end
    layoutManager:SaveLayouts()
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local layout = getLayoutByName(profileKey)
    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    local serializer = layoutManager:GetSerializer()

    return serializer:SerializeLayouts(layout.layoutID)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA = private:BlizzardDecodeB64CBOR(profileStringA:sub(3), true)
    local profileDataB = private:BlizzardDecodeB64CBOR(profileStringB:sub(3), true)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB, nil)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return CooldownViewerSettings
      end,
      functionNames = { "SaveCurrentLayout", "SetActiveLayoutByID" }
    }
  }
}

private.modules[m.moduleName] = m
