---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local LAP = LibStub("LibAddonProfiles")
local LWF = LibStub("LibWagoFramework")

local function getGameFlavorString()
  local gameVersion = select(4, GetBuildInfo())
  if gameVersion >= 110000 then
    return "retail"
  end
  if gameVersion >= 40400 then
    return "cata"
  end
  if gameVersion >= 11503 then
    return "classic"
  end
end

function addon:ExportAllProfiles()
  -- set current toc version
  local gameVersion = select(4, GetBuildInfo())
  local currentUIPack = addon:GetCurrentPackStashed()

  if not currentUIPack then
    addon:AddonPrintError("No pack selected")
    return
  end
  currentUIPack.gameVersion = gameVersion
  currentUIPack.gameFlavor = getGameFlavorString()
  currentUIPack.createdBy = UnitName("player").."-"..GetRealmName()
  -- set all export options from db
  for moduleName, options in pairs(addon.db.exportOptions) do
    local lapModule = LAP:GetModule(moduleName)
    if lapModule and lapModule.setExportOptions then
      lapModule:setExportOptions(options)
    end
  end
  -- delesecting a profile key will instantly set both the key and the profile to nil in the db
  -- See: ModuleFunctions:CreateDropdownOptions
  -- so we do not need to worry about removing those unwanted exports here
  -- only export the profiles that the user wants to export
  local timestamp = GetServerTime()
  local enabledResolutions = currentUIPack.resolutions.enabled
  local countOperations = 0
  for _, module in pairs(addon.moduleConfigs) do
    ---@type LibAddonProfilesModule
    local lapModule = module.lapModule
    if lapModule:isLoaded() and lapModule:isUpdated() then
      local hasAtleastOneExport = false
      for resolution, enabled in pairs(enabledResolutions) do
        local profileKey = currentUIPack.profileKeys[resolution][module.name]
        local profiles = lapModule.getProfileKeys and lapModule:getProfileKeys()
        local profileExists = profiles and profiles[profileKey]
        -- exception for modules with groups
        if not profiles then
          profileExists = true
        end
        if enabled and profileKey and profileExists then
          hasAtleastOneExport = true
        end
      end
      if hasAtleastOneExport then
        countOperations = countOperations + 1
      end
    end
  end
  --refresh list
  addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
  if countOperations == 0 then
    addon.copyHelper:SmartFadeOut(2, L["No profiles to export!"])
    return
  end
  addon:StartProgressBar(countOperations)
  addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 50, L["Saving all profiles..."])
  LWF:ToggleLockoutFrame(true, addon.frames, addon.frames.mainFrame)
  addon:Async(
    function()
      local updates = {}
      local removals = {}
      for _, module in pairs(addon.moduleConfigs) do
        ---@type LibAddonProfilesModule
        local lapModule = module.lapModule
        if lapModule:isLoaded() and lapModule:isUpdated() then
          local didExportAtleastOne = false
          for resolution, enabled in pairs(enabledResolutions) do
            updates[resolution] = updates[resolution] or {}
            removals[resolution] = removals[resolution] or {}
            local profileKey = currentUIPack.profileKeys[resolution][module.name]
            if enabled and profileKey then
              --handle invalid profile keys
              local profiles = lapModule.getProfileKeys and lapModule:getProfileKeys()
              local profileExists = profiles and profiles[profileKey]
              -- exception for modules with groups
              if not lapModule.exportGroup and not profileExists then
                currentUIPack.profileKeys[currentUIPack.resolutions.chosen][module.name] = nil
                currentUIPack.profiles[currentUIPack.resolutions.chosen][module.name] = nil
              else
                local updated, changedEntries, removedEntries = module.exportFunc(resolution, timestamp)
                if lapModule.moduleName == "WeakAuras" then
                  currentUIPack.collectedWagoIds = currentUIPack.collectedWagoIds or {}
                  currentUIPack.collectedWagoIds[resolution] = lapModule:getCollectedWagoIds()
                end
                if updated then
                  updates[resolution][module.name] = changedEntries or true
                  removals[resolution][module.name] = removedEntries
                end
                didExportAtleastOne = true
              end
            end
          end
          if didExportAtleastOne then
            addon:UpdateProgressBar()
          end
        end
      end
      addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
      local numUpdates = 0
      for _, data in pairs(updates) do
        for _ in pairs(data) do
          numUpdates = numUpdates + 1
        end
      end
      numUpdates = numUpdates + addon:CountRemovedProfiles(addon.db.chosenPack)
      if numUpdates > 0 then
        addon.copyHelper:SmartHide()
        currentUIPack.updatedAt = timestamp
        addon:OpenReleaseNoteInput(timestamp, updates, removals)
      else
        addon.copyHelper:SmartFadeOut(2, L["No Changes detected"])
        LWF:ToggleLockoutFrame(false, addon.frames, addon.frames.mainFrame)
      end
      addon:UpdateIncludedAddons(currentUIPack)
      addon:AddDataToStorageAddon(numUpdates > 0)
    end,
    "ExportAllProfiles"
  )
end

function addon:UpdateIncludedAddons(pack)
  pack.includedAddons = {}
  for res, addons in pairs(pack.profileKeys) do
    if pack.resolutions.enabled[res] then
      for addonName in pairs(addons) do
        ---@type LibAddonProfilesModule
        local lapModule = LAP:GetModule(addonName)
        local wagoId = lapModule.wagoId
        if wagoId then
          pack.includedAddons[lapModule.moduleName] = wagoId
        end
      end
    end
  end
end

function addon:SetupExportStash()
  -- for every pack in db set up a copy that we mutate on every export
  addon.exportStash = CopyTable(addon.db.creatorUI)
end

function addon:CommitExportStash()
  addon.db.creatorUI = addon.exportStash
end
