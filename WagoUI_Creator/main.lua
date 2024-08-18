---@type string
local addonName = ...
---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

local metaVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")
local versiontext = string.gsub(metaVersion, "%.", "")
addon.version = tonumber(versiontext)
addon.frames = {}
local profileDropdowns = {}
local currentProfileDropdowns = {}

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
  DF:ShowPromptPanel(
    L["Reset?"],
    function()
      WagoUICreatorDB = nil
      handleDBLoad(addon.db, true, addon.dbDefaults)
      DetailsFrameworkPromptSimple:SetHeight(80)
      ReloadUI()
    end,
    function()
      DetailsFrameworkPromptSimple:SetHeight(80)
    end,
    nil,
    nil
  )
  DetailsFrameworkPromptSimple:SetHeight(100)
end

function addon:AddonPrint(...)
  print("|c" .. addon.color .. addonName .. "|r:", tostringall(...))
end

function addon:AddonPrintError(...)
  print("|c" .. addon.color .. addonName .. "|r|cffff9117:|r", tostringall(...))
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

  addon.frames.eventListener:SetScript(
    "OnEvent",
    function(self, event, ...)
      if (event == "PLAYER_ENTERING_WORLD") then
        addon.frames.eventListener:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if addon.db.autoStart or not addon.db.hasLoggedInEver then
          C_Timer.After(
            1,
            function()
              addon.db.hasLoggedInEver = true
              addon:ShowFrame()
            end
          )
        end
        addon:AddDataToStorageAddon()
      elseif (event == "ADDON_LOADED") then
        local loadedAddonName = ...
        if (loadedAddonName == addonName) then
          addon:SetUpDB()
          handleDBLoad(addon.db, nil, addon.dbDefaults)
          addon.frames.eventListener:UnregisterEvent("ADDON_LOADED")
          --have to do this on next frame for some reason
          C_Timer.After(
            0,
            function()
              for _, func in pairs(postDBLoads) do
                func()
              end
            end
          )
        end
      end
    end
  )
end

function addon:DeepCopyAsync(orig)
  local orig_type = type(orig)
  local copy
  coroutine.yield()
  if orig_type == "table" then
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

function addon:AddDataToStorageAddon()
  if not WagoUI_Storage then
    WagoUI_Storage = {}
  end
  for _, pack in pairs(addon:GetAllPacks()) do
    local packName = pack.localName .. " (Local Copy)"
    local data = {
      gameVersion = pack.gameVersion,
      localName = packName,
      profileMetadata = pack.profileMetadata,
      resolutions = pack.resolutions,
      releaseNotes = pack.releaseNotes,
      profileKeys = pack.profileKeys,
      profiles = pack.profiles
    }
    WagoUI_Storage[packName] = data
  end
  if WagoUI and WagoUI.framesCreated then
    WagoUI:SetupWagoData()
    WagoUI:UpdateRegisteredDataConsumers()
  end
end

function addon:GetCurrentPack()
  if not addon.db.chosenPack then
    return
  end
  return addon.db.creatorUI[addon.db.chosenPack]
end

function addon:GetAllPacks()
  return addon.db.creatorUI
end

function addon.CreatePack()
  local newName = addon.GetNewEditBoxText()
  if not newName or string.len(newName) < 5 then
    addon:SetNewPackErrorLabel(L["Name too short"], true)
    return
  end
  if addon.db.creatorUI[newName] then
    addon:SetNewPackErrorLabel(L["Name already exists"], true)
    return
  end
  addon:ResetNewPackErrorLabel()
  local newPack = {
    localName = newName,
    profileKeys = {},
    profiles = {},
    profileMetadata = {},
    releaseNotes = {},
    resolutions = {
      enabled = {}
    }
  }
  for _, resolution in ipairs(addon.resolutions.entries) do
    newPack.profileKeys[resolution.value] = {}
    newPack.profiles[resolution.value] = {}
    newPack.profileMetadata[resolution.value] = {}
    newPack.resolutions.enabled[resolution.value] = resolution.defaultEnabled
  end
  newPack.resolutions.chosen = addon.resolutions.defaultValue
  addon.db.creatorUI[newName] = newPack
  addon.db.chosenPack = newName

  addon.UpdatePackSelectedUI()
end

function addon.DeleteCurrentPack()
  if not addon.db.chosenPack then
    return
  end
  addon.db.creatorUI[addon.db.chosenPack] = nil
  if WagoUI_Storage and WagoUI then
    WagoUI_Storage[addon.db.chosenPack .. " (Local Copy)"] = nil
    WagoUI:SetupWagoData()
    WagoUI:UpdateRegisteredDataConsumers()
  end
  addon.db.chosenPack = nil
  addon.UpdatePackSelectedUI()
end

function addon:RefreshDropdown(dropdown)
  dropdown:Refresh()
  dropdown:Close()
  local dropdownValue = dropdown:GetValue()
  dropdown:Select(dropdownValue)
  local values = {}
  for _, v in pairs(dropdown.func()) do
    if v.value then
      values[v.value] = true
    end
  end
  if not values[dropdownValue] then
    dropdown:NoOptionSelected()
  end
end

--needed if the profile data of the addons changes
function addon:RefreshAllProfileDropdowns()
  for _, dropdown in pairs(profileDropdowns) do
    dropdown:Refresh() --update the dropdown options
    dropdown:Close()
    local dropdownValue = dropdown:GetValue()
    dropdown:Select(dropdownValue) --selected profile could have been renamed, need to refresh like this
    local values = {}
    for _, v in pairs(dropdown.func()) do --if the selected profile got deleted
      if v.value then
        values[v.value] = true
      end
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
      local lapProfileKey = dropdown.info.lapModule:getCurrentProfileKey()
      dropdown:Select(dropdown.info.lapModule:getCurrentProfileKey())
    end
  end
  addon.RefreshContentScrollBox()
end

function addon:ResetFramePosition()
  local defaults = addon.dbDefaults
  addon.db.anchorTo = defaults.anchorTo
  addon.db.anchorFrom = defaults.anchorFrom
  addon.db.xoffset = defaults.xoffset
  addon.db.yoffset = defaults.yoffset
  if addon.frames.mainFrame then
    addon.frames.mainFrame:ClearAllPoints()
    addon.frames.mainFrame:SetPoint(
      defaults.anchorTo,
      UIParent,
      defaults.anchorFrom,
      defaults.xoffset,
      defaults.yoffset
    )
  end
end

function addon:CreateFrames()
  addon:RegisterErrorHandledFunctions()
  local panelOptions = {
    DontRightClickClose = true,
    NoTUISpecialFrame = true,
    -- UseScaleBar = true, --disable for now might use it later on
    NoCloseButton = false
  }
  local addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title")
  local frame =
    DF:CreateSimplePanel(
    UIParent,
    addon.ADDON_WIDTH,
    addon.ADDON_HEIGHT,
    addonTitle,
    addonName .. "Frame",
    panelOptions,
    WagoUICreatorDB
  )
  frame:Hide()
  DF:ApplyStandardBackdrop(frame)
  DF:CreateBorder(frame, 1, 0, 0)
  frame:ClearAllPoints()
  frame:SetFrameStrata("HIGH")
  frame:SetFrameLevel(100)
  frame:SetToplevel(true)
  LWF:ScaleFrameByResolution(frame)
  frame:SetPoint(
    WagoUICreatorDB.anchorTo,
    UIParent,
    WagoUICreatorDB.anchorFrom,
    WagoUICreatorDB.xoffset,
    WagoUICreatorDB.yoffset
  )
  hooksecurefunc(
    frame,
    "StopMovingOrSizing",
    function()
      local from, _, to, x, y = frame:GetPoint(nil)
      WagoUICreatorDB.anchorFrom, WagoUICreatorDB.anchorTo = from, to
      WagoUICreatorDB.xoffset, WagoUICreatorDB.yoffset = x, y
    end
  )
  frame.__background:SetAlpha(1)

  frame.Title:SetFont(frame.Title:GetFont(), 16)
  frame.Title:SetPoint("CENTER", frame.TitleBar, "CENTER", 0, 1)

  local versionString = frame.TitleBar:CreateFontString(addonName .. "VersionString", "overlay", "GameFontNormalSmall")
  versionString:SetTextColor(.8, .8, .8, 1)
  versionString:SetText("v" .. metaVersion)
  versionString:SetPoint("LEFT", frame.TitleBar, "LEFT", 2, 0)

  local autoStartCheckbox =
    LWF:CreateCheckbox(
    frame,
    25,
    function(_, _, value)
      WagoUICreatorDB.autoStart = value
    end,
    WagoUICreatorDB.autoStart
  )
  autoStartCheckbox:Hide()
  autoStartCheckbox:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)

  local autoStartLabel = DF:CreateLabel(frame, "Startup", 16, "white")
  autoStartLabel:SetPoint("LEFT", autoStartCheckbox, "RIGHT", 0, 0)
  autoStartLabel:Hide()

  local resetButton = LWF:CreateButton(frame, 60, 40, "RESET", 16)
  resetButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -60)
  resetButton:SetClickFunction(
    function()
      addon:ResetOptions()
    end
  )
  resetButton:Hide()

  local forceErrorButton = LWF:CreateButton(frame, 120, 40, "Force Error", 16)
  forceErrorButton:Hide()
  forceErrorButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -110)
  forceErrorButton:SetClickFunction(addon.TestErrorHandling)

  local testButton = LWF:CreateButton(frame, 120, 40, "Test Stuff", 16)
  testButton:Hide()
  testButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -160)
  testButton:SetClickFunction(
    function()
      addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
    end
  )

  if addon.db.debug then
    autoStartCheckbox:Show()
    autoStartLabel:Show()
    resetButton:Show()
    forceErrorButton:Show()
    testButton:Show()
  end

  local frameContent = CreateFrame("Frame", nil, frame)
  frameContent:SetPoint("TOPLEFT", frame.TitleBar, "BOTTOMLEFT", 0, -5)
  frameContent:SetPoint("TOPRIGHT", frame.TitleBar, "BOTTOMRIGHT", 0, -5)
  frameContent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 38)
  frameContent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 38)
  frame.frameContent = frameContent

  addon:CreateFrameContent(frame.frameContent)

  -- db hooks
  -- We want to instantly update the profile dropdowns when a profile is added or removed and the current profile changes
  -- Therefore we hook the functions that are responsible for these changes
  do
    ---@param lapModule LibAddonProfilesModule
    local function executeRefreshHooks(lapModule)
      if lapModule.refreshHookList then
        for _, hook in pairs(lapModule.refreshHookList) do
          local targetTable = hook.tableFunc()
          for _, functionName in pairs(hook.functionNames) do
            hooksecurefunc(
              targetTable,
              functionName,
              function()
                C_Timer.After(
                  0.1,
                  function()
                    --edge case in editmode where the profilelist is not updated instantly
                    addon:RefreshAllProfileDropdowns()
                  end
                )
              end
            )
          end
        end
      end
    end

    for _, module in pairs(addon.moduleConfigs) do
      ---@type LibAddonProfilesModule
      local lapModule = module.lapModule
      if lapModule:needsInitialization() then
        lapModule:openConfig()
        C_Timer.After(
          0,
          function()
            lapModule:closeConfig()
          end
        )
      end
      if lapModule:isLoaded() then
        executeRefreshHooks(lapModule)
      end
    end
  end

  addon.frames.mainFrame = frame
  addon:CreateCopyHelper()
end
