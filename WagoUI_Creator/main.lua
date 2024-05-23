---@diagnostic disable: undefined-field
local addonName, addon = ...
local L = addon.L
local DF = _G["DetailsFramework"]

local metaVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")
local versiontext = string.gsub(metaVersion, "%.", "")
addon.version = tonumber(versiontext)
addon.frames = {}
local profileDropdowns = {}
local currentProfileDropdowns = {}

local dbDefaults = {
  anchorTo = "CENTER",
  anchorFrom = "CENTER",
  xoffset = 0,
  yoffset = 0,
  config = {},
  creatorUI = {
    name = "",
    profileKeys = {
      ["1080"] = {},
      ["1440"] = {},
    },
    profiles = {
      ["1080"] = {},
      ["1440"] = {},
    },
    profileMetadata = {
      ["1080"] = {},
      ["1440"] = {},
    },
    releaseNotes = {},
    resolutions = {
      chosen = "1080",
      enabled = {
        ["1080"] = true,
        ["1440"] = false,
      },
    }
  },
}

local function handleDBLoad(database, force, defaults)
  for k, v in pairs(defaults) do
    -- migrate from faulty values
    if (force or (type(database[k]) ~= "boolean" and not database[k])) then
      database[k] = v
    end
    if type(v) == "table" then
      handleDBLoad(database[k], force, v)
    end
  end
end

function addon:ResetOptions()
  DF:ShowPromptPanel(L["Reset?"]
    , function()
      WagoUICreatorDB = nil
      handleDBLoad(addon.db, true, dbDefaults)
      DetailsFrameworkPromptSimple:SetHeight(80)
      ReloadUI()
    end,
    function()
      DetailsFrameworkPromptSimple:SetHeight(80)
    end,
    nil,
    nil)
  DetailsFrameworkPromptSimple:SetHeight(100)
end

function addon:AddonPrint(...)
  print("|c"..addon.color..addonName.."|r:", tostringall(...))
end

function addon:AddonPrintError(...)
  print("|c"..addon.color..addonName.."|r|cffff9117:|r", tostringall(...))
end

function addon:ShowFrame()
  if not addon.framesCreated then
    addon:CreateFrames()
    addon.framesCreated = true
    addon.frames.mainFrame:Show()
  else
    addon.frames.mainFrame:Show()
    addon:RefreshAllProfileDropdowns()
  end
end

function addon:HideFrame()
  addon.frames.mainFrame:Hide()
end

function addon:ToggleFrame()
  if (addon.frames and addon.frames.mainFrame and addon.frames.mainFrame:IsShown()) then
    addon:HideFrame()
  else
    addon:ShowFrame()
  end
end

do
  addon.frames.eventListener = CreateFrame("Frame")
  addon.frames.eventListener:RegisterEvent("PLAYER_ENTERING_WORLD")
  addon.frames.eventListener:RegisterEvent("ADDON_LOADED")

  local postDBLoads = {}
  function addon:RegisterPostDBLoad(func)
    table.insert(postDBLoads, func)
  end

  addon.frames.eventListener:SetScript("OnEvent", function(self, event, ...)
    if (event == "PLAYER_ENTERING_WORLD") then
      addon.frames.eventListener:UnregisterEvent("PLAYER_ENTERING_WORLD")
      if WagoUICreatorDB.autoStart then
        addon:ShowFrame()
      end
      if WagoUICreatorDB.testMode then
        addon:AddDataToDataAddon()
      end
    elseif (event == "ADDON_LOADED") then
      local loadedAddonName = ...
      if (loadedAddonName == addonName) then
        addon:SetUpDB()
        handleDBLoad(addon.db, nil, dbDefaults)
        addon.frames.eventListener:UnregisterEvent("ADDON_LOADED")
        --have to do this on next frame for some reason
        C_Timer.After(0, function()
          for _, func in pairs(postDBLoads) do
            func()
          end
        end)
      end
    end
  end)
end

function addon:DeepCopyAsync(orig)
  local orig_type = type(orig)
  local copy
  coroutine.yield()
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[addon:DeepCopyAsync(orig_key)] = addon:DeepCopyAsync(orig_value)
    end
    setmetatable(copy, addon:DeepCopyAsync(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function addon:ExportAllProfiles()
  -- delesecting a profile key will instantly set both the key and the profile to nil in the db
  -- See: ModuleFunctions:CreateDropdownOptions
  -- so we do not need to worry about removing those unwanted exports here
  -- only export the profiles that the user wants to export
  local timestamp = GetServerTime()
  local enabledResolutions = addon.db.creatorUI.resolutions.enabled
  local countOperations = 0
  for _, module in pairs(addon.moduleConfigs) do
    if module.isLoaded() or module.lapModule.needsInitialization() then
      local hasAtleastOneExport = false
      for resolution, enabled in pairs(enabledResolutions) do
        if enabled and addon.db.creatorUI.profileKeys[resolution][module.name] then
          hasAtleastOneExport = true
        end
      end
      if hasAtleastOneExport then
        countOperations = countOperations + 1
        if module.lapModule.needsInitialization() then
          module.lapModule.openConfig()
          C_Timer.After(0, function()
            module.lapModule.closeConfig()
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
  addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 50, L["Exporting all profiles..."])
  addon:Async(function()
    local updates = {}
    local removals = {}
    for _, module in pairs(addon.moduleConfigs) do
      if module.isLoaded() then
        local didExportAtleastOne = false
        for resolution, enabled in pairs(enabledResolutions) do
          if enabled and addon.db.creatorUI.profileKeys[resolution][module.name] then
            local updated, changedEntries, removedEntries = module.exportFunc(resolution, timestamp)
            if updated then
              updates[module.name] = changedEntries or true
              removals[module.name] = removedEntries --currently only for group modules
            end
            didExportAtleastOne = true
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
    end
    if WagoUICreatorDB.testMode then
      addon:AddDataToDataAddon()
    end
  end, "ExportAllProfiles")
end

function addon:AddDataToDataAddon()
  if not WagoUIData then return end
  local data = {
    name = "Local Test Data",
    profileMetadata = WagoUICreatorDB.creatorUI.profileMetadata,
    resolutions = WagoUICreatorDB.creatorUI.resolutions,
    releaseNotes = WagoUICreatorDB.creatorUI.releaseNotes,
    profileKeys = WagoUICreatorDB.creatorUI.profileKeys,
    profiles = WagoUICreatorDB.creatorUI.profiles,
  }
  WagoUIData.LocalTestData = data
end

--needed if the profile data of the addons changes
function addon:RefreshAllProfileDropdowns()
  for _, dropdown in pairs(profileDropdowns) do
    dropdown:Refresh() --update the dropdown options
    dropdown:Close()
    local dropdownValue = dropdown:GetValue()
    dropdown:Select(dropdownValue)        --selected profile could have been renamed, need to refresh like this
    local values = {}
    for _, v in pairs(dropdown.func()) do --if the selected profile got deleted
      if v.value then values[v.value] = true end
    end
    if not values[dropdownValue] then
      dropdown:NoOptionSelected()
    end
    if dropdown.myIsEnabled then
      dropdown:Enable()
    else
      dropdown:Disable()
    end
  end
  for _, dropdown in pairs(currentProfileDropdowns) do
    if dropdown.info then
      dropdown:Select(dropdown.info.lapModule.getCurrentProfileKey())
    end
  end
end

function addon:CreateFrames()
  addon:RegisterErrorHandledFunctions()
  local panelOptions = {
    DontRightClickClose = true,
    NoTUISpecialFrame = false,
    -- UseScaleBar = true, --disable for now might use it later on
    NoCloseButton = false,
  }
  local addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");
  local frame = DF:CreateSimplePanel(UIParent, addon.ADDON_WIDTH, addon.ADDON_HEIGHT, addonTitle,
    addonName.."Frame",
    panelOptions, WagoUICreatorDB)
  frame:Hide()
  DF:ApplyStandardBackdrop(frame)
  DF:CreateBorder(frame, 1, 0, 0)
  frame:ClearAllPoints()
  frame:SetFrameStrata("HIGH")
  frame:SetFrameLevel(100)
  frame:SetToplevel(true)
  frame:SetPoint(WagoUICreatorDB.anchorTo, UIParent, WagoUICreatorDB.anchorFrom, WagoUICreatorDB.xoffset,
    WagoUICreatorDB.yoffset)
  hooksecurefunc(frame, "StopMovingOrSizing", function()
    local from, _, to, x, y = frame:GetPoint(nil)
    WagoUICreatorDB.anchorFrom, WagoUICreatorDB.anchorTo = from, to
    WagoUICreatorDB.xoffset, WagoUICreatorDB.yoffset = x, y
  end)
  frame.__background:SetAlpha(1)

  frame.Title:SetFont(frame.Title:GetFont(), 16)
  frame.Title:SetPoint("CENTER", frame.TitleBar, "CENTER", 0, 1)

  local versionString = frame.TitleBar:CreateFontString(addonName.."VersionString", "overlay", "GameFontNormalSmall")
  versionString:SetTextColor(.8, .8, .8, 1)
  versionString:SetText("v"..metaVersion)
  versionString:SetPoint("LEFT", frame.TitleBar, "LEFT", 2, 0)

  local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

  local autoStartCheckbox = DF:CreateSwitch(frame,
    function(_, _, value)
      WagoUICreatorDB.autoStart = value
    end,
    false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
  autoStartCheckbox:SetSize(25, 25)
  autoStartCheckbox:SetAsCheckBox()
  autoStartCheckbox:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
  autoStartCheckbox:SetValue(WagoUICreatorDB.autoStart)

  local autoStartLabel = DF:CreateLabel(frame, "Startup", 16, "white")
  autoStartLabel:SetPoint("LEFT", autoStartCheckbox, "RIGHT", 0, 0)

  local testModeCheckbox = DF:CreateSwitch(frame,
    function(_, _, value)
      WagoUICreatorDB.testMode = value
    end,
    false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
  testModeCheckbox:SetSize(25, 25)
  testModeCheckbox:SetAsCheckBox()
  testModeCheckbox:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, -30)
  testModeCheckbox:SetValue(WagoUICreatorDB.testMode)

  local testModeLabel = DF:CreateLabel(frame, "Test Mode", 16, "white")
  testModeLabel:SetPoint("LEFT", testModeCheckbox, "RIGHT", 0, 0)

  local resetButton = DF:CreateButton(frame, nil, 60, 40, "RESET", nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  resetButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -60)
  resetButton.text_overlay:SetFont(resetButton.text_overlay:GetFont(), 16)
  resetButton:SetClickFunction(function() addon:ResetOptions() end)

  local forceErrorButton = DF:CreateButton(frame, nil, 120, 40, "Force Error", nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  forceErrorButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -110)
  forceErrorButton.text_overlay:SetFont(forceErrorButton.text_overlay:GetFont(), 16)
  forceErrorButton:SetClickFunction(addon.TestErrorHandling)

  local testButton = DF:CreateButton(frame, nil, 120, 40, "Test Stuff", nil, nil, nil, nil, nil,
    nil,
    options_dropdown_template)
  testButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -160)
  testButton.text_overlay:SetFont(testButton.text_overlay:GetFont(), 16)
  testButton:SetClickFunction(function()
    addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
  end)

  local frameContent = CreateFrame("Frame", nil, frame)
  frameContent:SetPoint("TOPLEFT", frame.TitleBar, "BOTTOMLEFT", 0, -5)
  frameContent:SetPoint("TOPRIGHT", frame.TitleBar, "BOTTOMRIGHT", 0, -5)
  frameContent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 38)
  frameContent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 38)
  frame.frameContent = frameContent

  addon:CreateFrameContent(frame.frameContent)

  --execute all hooks
  for _, module in pairs(addon.moduleConfigs) do
    if module.hookRefresh then
      module.hookRefresh()
    end
  end

  addon.frames.mainFrame = frame
  addon:CreateCopyHelper()
end
