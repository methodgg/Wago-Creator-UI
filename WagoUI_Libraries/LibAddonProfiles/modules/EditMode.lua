local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

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

---@return boolean
local isLoaded = function()
  return true
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["EDITMODE"]()
end

---@return nil
local closeConfig = function()
  EditModeManagerFrame.onCloseCallback()
end


---@return table<string, any>
local getProfileKeys = function()
  local profileKeys = {}
  for _, layout in pairs(EditModeManagerFrame:GetLayouts()) do
    profileKeys[layout.layoutName] = true
  end
  return profileKeys
end

---@return string
local getCurrentProfileKey = function()
  return EditModeManagerFrame:GetActiveLayoutInfo().layoutName
end

---@param profileKey string
local setProfile = function(profileKey)
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
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return getLayoutByName(profileKey) ~= nil
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
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
end

local removeProfile = function(profileKey)
  local layoutIndex = getLayoutIndexByName(profileKey)
  if layoutIndex then
    EditModeManagerFrame:DeleteLayout(layoutIndex)
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey)
  EditModeManagerFrame:Show()
  removeProfile(profileKey) --need to remove old profile with same name first for updating to work and not be confusing
  local newLayoutInfo = C_EditMode.ConvertStringToLayoutInfo(profileString);
  EditModeManagerFrame:ImportLayout(newLayoutInfo, 1, profileKey)
  EditModeManagerFrame.CloseButton:Click()
  -- ignore taint warning
  if StaticPopup1Button2Text:GetText() == "Ignore" then
    StaticPopup1Button2:Click()
  end
  setProfile(profileKey)
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return nil end
  local layout = getLayoutByName(profileKey)
  return C_EditMode.ConvertLayoutInfoToString(layout)
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  return profileStringA == profileStringB
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "EditMode",
  icon = 135724,
  slash = "/editmode",
  needReloadOnImport = true,
  needsInitialization = needsInitialization,
  needProfileKey = true,
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
