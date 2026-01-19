local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local optionsFrame

---@type LibAddonProfilesModule
local m = {
  moduleName = "MinimapStats",
  wagoId = "qGYM7vGg",
  oldestSupported = "6.3",
  addonNames = { "MinimapStats" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("MinimapStats", "IconTexture"),
  slash = "/ms",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("MinimapStats")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    MSG:CreateGUI()
  end,
  closeConfig = function(self)
    local titleToFind = C_AddOns.GetAddOnMetadata("MinimapStats", "Title")
    local function findOptionsFrame()
      for i = 1, select("#", UIParent:GetChildren()) do
        local childFrame = select(i, UIParent:GetChildren())
        if childFrame and childFrame.obj and childFrame.obj.titletext then
          if childFrame.obj.titletext:GetText() == titleToFind then
            return childFrame
          end
        end
      end
    end
    optionsFrame = optionsFrame or findOptionsFrame()
    if optionsFrame then
      optionsFrame:Hide()
    end
  end,
  getProfileKeys = function(self)
    return {
      ["Global"] = true
    }
  end,
  getCurrentProfileKey = function(self)
    return "Global"
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  setProfile = function(self, profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if profileData and profileData.InstanceDifficulty and profileData.Location then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      MSG:ImportSavedVariables(profileString)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    local export
    xpcall(function()
      export = MSG:ExportSavedVariables()
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, _, profileDataA = private:GenericDecode(profileStringA:sub(4))
    local _, _, profileDataB = private:GenericDecode(profileStringB:sub(4))
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
