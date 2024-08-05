local _, addon = ...
local L = addon.L
local moduleName = "ShadowedUnitFrames"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)

local function writeTable(tbl)
  --ShadowedUF_Options\config.lua
  local data = ""
  for key, value in pairs(tbl) do
    local valueType = type(value)
    -- Wrap the key in brackets if it's a number
    if (type(key) == "number") then
      key = string.format("[%s]", key)
      -- Wrap the string with quotes if it has a space in it
    elseif (string.match(key, "[%p%s%c]") or string.match(key, "^[0-9]+$")) then
      key = string.format("['%s']", string.gsub(key, "'", "\\'"))
    end
    -- foo = {bar = 5}
    if (valueType == "table") then
      data = string.format("%s%s=%s", data, key, writeTable(value))
      -- foo = true / foo = 5
    elseif (valueType == "number" or valueType == "boolean") then
      data = string.format("%s%s=%s", data, key, tostring(value))
      -- foo = "bar"
    else
      value = tostring(value)
      if value and string.match(value, "[\n]") then
        local token = ""
        while string.find(value, "%["..token.."%[") or string.find(value, "%]"..token.."%]") do
          token = token.."="
        end
        value = string.format("[%s[%s]%s]", token, value, token)
      else
        value = string.format("%q", value)
      end
      data = string.format("%s%s=%s", data, key, value)
    end
    coroutine.yield()
  end
  return "{"..data.."}"
end

local copyFuncOverride = function(...)
  local clickSource, index = ...
  local profileKey = WagoUICreatorDB.profileKeys[moduleName][index]
  if not profileKey then return end
  local choices = {
    {
      text = "Installer",
      on_click = function()
        addon:Async(function()
          addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 50, L["Preparing export string..."])
          WagoUICreatorDB.profiles[moduleName][index] = lapModule.exportProfile(profileKey)
          addon.copyHelper:Hide()
          addon:TextExport(WagoUICreatorDB.profiles[moduleName][index])
        end, "sufChoice1OnClick")
      end,
      tooltipText = "Copy a string that can be used by UI Installers based on UIManager",
    },
    {
      text = "SUF String",
      on_click = function()
        addon:Async(function()
          addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 50, L["Preparing export string..."])
          WagoUICreatorDB.profiles[moduleName][index] = lapModule.exportProfile(profileKey)
          local sufExport = writeTable(ShadowedUFDB.profiles[profileKey])
          addon.copyHelper:Hide()
          addon:TextExport(sufExport)
        end, "sufChoice2OnClick")
      end,
      tooltipText = "Copy a normal SUF import string",
    },
  }
  addon:ShowChoiceFrame(choices, "Choose profile style", nil, nil, "BOTTOM", clickSource, "BOTTOM")
end

local function dropdownOptions(index)
  local res = {}
  if not ShadowedUFDB then return res end
  local profileKeys = lapModule.getProfileKeys()
  local currentProfileKey = lapModule.getCurrentProfileKey()
  return addon.ModuleFunctions:CreateDropdownOptions(moduleName, index, res, profileKeys, currentProfileKey)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = copyFuncOverride,
  copyButtonTooltipText = nil,
  sortIndex = 10,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
