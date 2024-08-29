if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
  return
end

local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function getLayoutByName(layoutName)
  local layouts = EditModeManagerFrame:GetLayouts()
  for _, layout in pairs(layouts) do
    if layout.layoutName == layoutName then
      return layout
    end
  end
end

local function getLayoutIndexByName(layoutName)
  local layouts = EditModeManagerFrame:GetLayouts()
  for i, layout in pairs(layouts) do
    if layout.layoutName == layoutName then
      return i
    end
  end
end

local removeProfile = function(profileKey)
  local layoutIndex = getLayoutIndexByName(profileKey)
  if layoutIndex then
    EditModeManagerFrame:DeleteLayout(layoutIndex)
  end
end

local areGlobalLayoutsFull = function()
  local layoutCount = 0
  local layouts = EditModeManagerFrame:GetLayouts()
  for _, layout in pairs(layouts) do
    if layout.layoutType == 1 then
      layoutCount = layoutCount + 1
    end
  end
  return layoutCount >= 5
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Blizzard Edit Mode",
  wagoId = "baseline",
  icon = 135724,
  slash = "/editmode",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
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
    if not SlashCmdList["EDITMODE"] then return end
    SlashCmdList["EDITMODE"]()
  end,
  closeConfig = function(self)
    EditModeManagerFrame.onCloseCallback()
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    for _, layout in pairs(EditModeManagerFrame:GetLayouts()) do
      profileKeys[layout.layoutName] = true
    end
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    return EditModeManagerFrame:GetActiveLayoutInfo().layoutName
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
    for i, layout in pairs(EditModeManagerFrame:GetLayouts()) do
      if layout.layoutName == profileKey then
        index = i
        break
      end
    end
    if index then
      EditModeManagerFrame:SelectLayout(index)
    end
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local t = { strsplit(" ", profileString) }
    for i = 1, 8 do
      local v = t[i]
      if i <= 7 then
        if not tonumber(v) then
          return
        end
      elseif i == 8 then
        if type(v) == "string" then
          return ""
        end
      end
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    EditModeManagerFrame:Show()

    -- there is a hardcap of 5 profiles (+2 presets)
    -- we need to remove one if we are at the limit
    local profileKeys = self:getProfileKeys()
    local profileCount = 0
    for _ in pairs(profileKeys) do
      profileCount = profileCount + 1
    end
    if profileKeys[profileKey] then
      removeProfile(profileKey) --need to remove old profile with same name first for updating to work and not be confusing
    end
    if areGlobalLayoutsFull() then
      -- if people complain find a better solution
      -- users are warned in the UI
      EditModeManagerFrame:SelectLayout(3)
      removeProfile(self:getCurrentProfileKey())
    end

    local newLayoutInfo = C_EditMode.ConvertStringToLayoutInfo(profileString)
    EditModeManagerFrame:ImportLayout(newLayoutInfo, 1, profileKey)
    EditModeManagerFrame.CloseButton:Click()
    -- ignore taint warning
    if StaticPopup1Button2Text:GetText() == "Ignore" then
      StaticPopup1Button2:Click()
    end
    self:setProfile(profileKey)
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local layout = getLayoutByName(profileKey)
    return C_EditMode.ConvertLayoutInfoToString(layout)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    return profileStringA == profileStringB
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return EditModeManagerFrame
      end,
      functionNames = { "SaveLayouts", "Layout", "SelectLayout" }
    }
  }
}

private.modules[m.moduleName] = m
