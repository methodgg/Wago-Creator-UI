---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local LAP = LibStub("LibAddonProfiles")

local function getGameFlavorString()
  local gameVersion = select(4, GetBuildInfo())
  if gameVersion >= 110000 then return "retail" end
  if gameVersion >= 40400 then return "cata" end
  if gameVersion >= 11503 then return "classic" end
end

function addon:ExportAllProfiles()
  -- set current toc version
  local gameVersion = select(4, GetBuildInfo())
  local currentUIPack = addon:GetCurrentPack()

  if not currentUIPack then
    addon:AddonPrintError("No pack selected")
    return
  end
  currentUIPack.gameVersion = gameVersion
  currentUIPack.gameFlavor = getGameFlavorString()
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
    if lapModule:isLoaded() or lapModule:needsInitialization() then
      local hasAtleastOneExport = false
      for resolution, enabled in pairs(enabledResolutions) do
        local profileKey = currentUIPack.profileKeys[resolution][module.name]
        local profiles = lapModule.getProfileKeys and lapModule:getProfileKeys()
        local profileExists = profiles and profiles[profileKey]
        -- exception for modules with groups
        if not profiles then profileExists = true end
        if enabled and profileKey and profileExists then
          hasAtleastOneExport = true
        end
      end
      if hasAtleastOneExport then
        countOperations = countOperations + 1
        if lapModule:needsInitialization() then
          lapModule:openConfig()
          C_Timer.After(0, function()
            lapModule:closeConfig()
          end)
        end
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
  addon.SetLockoutFrameShowState(true)
  addon:Async(function()
    local updates = {}
    local removals = {}
    for _, module in pairs(addon.moduleConfigs) do
      ---@type LibAddonProfilesModule
      local lapModule = module.lapModule
      if module.isLoaded() then
        local didExportAtleastOne = false
        for resolution, enabled in pairs(enabledResolutions) do
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
              if updated then
                updates[module.name] = changedEntries or true
                removals[module.name] = removedEntries --currently only for group modules
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
    for _ in pairs(updates) do
      numUpdates = numUpdates + 1
    end
    if numUpdates > 0 then
      addon.copyHelper:SmartHide()
      addon:OpenReleaseNoteInput(timestamp, updates, removals)
    else
      addon.copyHelper:SmartFadeOut(2, L["No Changes detected"])
      addon.SetLockoutFrameShowState(false)
    end
    addon:AddDataToDataAddon()
  end, "ExportAllProfiles")
end
