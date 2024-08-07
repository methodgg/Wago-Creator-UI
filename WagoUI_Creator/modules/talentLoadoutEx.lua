---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local moduleName = "Talent Loadout Ex"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)
local DF = _G["DetailsFramework"]
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local manageFrame
local frameWidth = 850
local frameHeight = 330

local specData = {
  [1] = {
    specs = {
      [1] = 250,
      [2] = 251,
      [3] = 252,
    },
    dataName = "DEATHKNIGHT",
    displayName = "Death Knight"
  },
  [2] = {
    specs = {
      [1] = 577,
      [2] = 581,
    },
    dataName = "DEMONHUNTER",
    displayName = "Demon Hunter"
  },
  [3] = {
    specs = {
      [1] = 102,
      [2] = 103,
      [3] = 104,
      [4] = 105,
    },
    dataName = "DRUID",
    displayName = "Druid"
  },
  [4] = {
    specs = {
      [1] = 1467,
      [2] = 1468,
      [3] = 1473,
    },
    dataName = "EVOKER",
    displayName = "Evoker"
  },
  [5] = {
    specs = {
      [1] = 253,
      [2] = 254,
      [3] = 255,
    },
    dataName = "HUNTER",
    displayName = "Hunter"
  },
  [6] = {
    specs = {
      [1] = 62,
      [2] = 63,
      [3] = 64,
    },
    dataName = "MAGE",
    displayName = "Mage"
  },
  [7] = {
    specs = {
      [1] = 268,
      [2] = 269,
      [3] = 270,
    },
    dataName = "MONK",
    displayName = "Monk"
  },
  [8] = {
    specs = {
      [1] = 65,
      [2] = 66,
      [3] = 70,
    },
    dataName = "PALADIN",
    displayName = "Paladin"
  },
  [9] = {
    specs = {
      [1] = 256,
      [2] = 257,
      [3] = 258,
    },
    dataName = "PRIEST",
    displayName = "Priest"
  },
  [10] = {
    specs = {
      [1] = 259,
      [2] = 260,
      [3] = 261,
    },
    dataName = "ROGUE",
    displayName = "Rogue"
  },
  [11] = {
    specs = {
      [1] = 262,
      [2] = 263,
      [3] = 264,
    },
    dataName = "SHAMAN",
    displayName = "Shaman"
  },
  [12] = {
    specs = {
      [1] = 265,
      [2] = 266,
      [3] = 267,
    },
    dataName = "WARLOCK",
    displayName = "Warlock"
  },
  [13] = {
    specs = {
      [1] = 71,
      [2] = 72,
      [3] = 73,
    },
    dataName = "WARRIOR",
    displayName = "Warrior"
  }
}

--TODO: the copy button doesn't work properly atm, check other TODO in frameContent.lua
--      for now it's not important, the profiles do get exported properly
local db

local getChosenResolution = function()
  return addon:GetCurrentPack().resolutions.chosen
end

local function setDBMode(mode, dbRef)
  if mode == "Copy" then
    if not addon:GetCurrentPack().profileKeys[getChosenResolution()][moduleName] then
      addon:GetCurrentPack().profileKeys[getChosenResolution()][moduleName] = {}
    end
    db = addon:GetCurrentPack().profileKeys[getChosenResolution()][moduleName]
  elseif mode == "Import" then
    db = dbRef
  end
  for _, classData in ipairs(specData) do
    if not db[classData.dataName] then db[classData.dataName] = {} end
  end
end

local function createManageFrame()
  ---@diagnostic disable-next-line: undefined-field
  manageFrame = DF:CreateSimplePanel(addon.frames.mainFrame, frameWidth, frameHeight, "")
  ---@diagnostic disable-next-line: undefined-field
  DF:ApplyStandardBackdrop(manageFrame)
  DF:CreateBorder(manageFrame)
  manageFrame:ClearAllPoints()
  manageFrame:SetFrameStrata("FULLSCREEN")
  manageFrame:SetFrameLevel(100)
  manageFrame.__background:SetAlpha(1)
  manageFrame:SetMouseClickEnabled(true)
  manageFrame:Hide()
  manageFrame.buttons = {}
  manageFrame.StartMoving = function() end
  addon.frames.mainFrame:HookScript("OnHide", function()
    manageFrame:Hide()
  end)

  local size = 20
  local classesPerRow = 7
  local rowWidth = 120
  local columnHeight = 140
  local classSwitches = {}
  local specSwitches = {}
  local classLabels = {}
  local specLabels = {}
  local classIcons = {}
  local specIcons = {}

  for idx, classData in ipairs(specData) do
    ---@diagnostic disable-next-line: undefined-field
    local classSwitch = DF:CreateSwitch(manageFrame,
      function(_, _, value)
        for specIdx, specId in ipairs(classData.specs) do
          db[classData.dataName][specIdx] = value
          specSwitches[specId]:SetValue(value)
        end
      end,
      false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
      DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
    classSwitches[classData.dataName] = classSwitch
    classSwitch:SetSize(size, size)
    classSwitch:SetAsCheckBox()
    local yOffset = -30 + (math.floor((idx - 1) / classesPerRow) * -columnHeight)
    local xOffset = 10 + ((idx - 1) % classesPerRow) * rowWidth
    classSwitch:SetPoint("TOPLEFT", manageFrame, "TOPLEFT", xOffset, yOffset)

    local icon = classSwitch:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\ICONS\\ClassIcon_"..classData.dataName)
    icon:SetSize(size, size)
    icon:SetPoint("LEFT", classSwitch.widget, "RIGHT", 0, 0)
    classIcons[classData.dataName] = icon

    local colorString = RAID_CLASS_COLORS[classData.dataName].colorStr
    local coloredClassName = "|c"..colorString..classData.displayName.."|r"
    ---@diagnostic disable-next-line: undefined-field
    local classLabel = DF:CreateLabel(manageFrame, coloredClassName, 10, "white")
    classLabel:SetPoint("LEFT", icon, "RIGHT", 0, 0)
    classLabels[classData.dataName] = classLabel

    for specIdx, specId in ipairs(classData.specs) do
      ---@diagnostic disable-next-line: undefined-field
      local specSwitch = DF:CreateSwitch(manageFrame,
        function(_, _, value)
          db[classData.dataName][specIdx] = value
          local allSpecsChecked = true
          for sIdx, _ in ipairs(classData.specs) do
            allSpecsChecked = allSpecsChecked and db[classData.dataName][sIdx]
          end
          classSwitch:SetValue(allSpecsChecked)
        end,
        false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
      specSwitches[specId] = specSwitch
      specSwitch:SetSize(size, size)
      specSwitch:SetAsCheckBox()
      specSwitch:SetPoint("TOPLEFT", manageFrame, "TOPLEFT", xOffset, (-(specIdx * (size + 1))) - 10 + yOffset)

      local _, specName, _, iconNumber = GetSpecializationInfoByID(specId)
      local specIcon = specSwitch:CreateTexture(nil, "ARTWORK")
      specIcon:SetTexture(iconNumber)
      specIcon:SetSize(size, size)
      specIcon:SetPoint("LEFT", specSwitch.widget, "RIGHT", 0, 0)
      specIcons[specId] = specIcon


      local coloredSpecName = "|c"..colorString..specName.."|r"
      ---@diagnostic disable-next-line: undefined-field
      local specLabel = DF:CreateLabel(manageFrame, coloredSpecName, 10, "white")
      specLabel:SetPoint("LEFT", specIcon, "RIGHT", 0, 0)
      specLabels[specId] = specLabel
    end
  end

  function manageFrame:SetAllValuesFromDB()
    for _, classData in ipairs(specData) do
      local classSwitchedValue = true
      for specIdx, _ in ipairs(classData.specs) do
        classSwitchedValue = classSwitchedValue and db[classData.dataName][specIdx]
      end
      classSwitches[classData.dataName]:SetValue(classSwitchedValue)
      for specIdx, specId in ipairs(classData.specs) do
        specSwitches[specId]:SetValue(db[classData.dataName][specIdx])
      end
    end
  end

  function manageFrame:SetEnabledStates(mode)
    if mode == "Copy" then
      for _, classData in ipairs(specData) do
        classSwitches[classData.dataName]:SetEnabled(true)
        local colorString = RAID_CLASS_COLORS[classData.dataName].colorStr
        local coloredClassName = "|c"..colorString..classData.displayName.."|r"
        classLabels[classData.dataName]:SetText(coloredClassName)
        classIcons[classData.dataName]:SetDesaturated(false)

        for specIdx, specId in ipairs(classData.specs) do
          specSwitches[specId]:SetEnabled(true)
          local _, specName, _, iconNumber = GetSpecializationInfoByID(specId)
          local coloredSpecName = "|c"..colorString..specName.."|r"
          specLabels[specId]:SetText(coloredSpecName)
          specIcons[specId]:SetDesaturated(false)
        end
      end
    elseif mode == "Import" then
      for _, classData in ipairs(specData) do
        local classSwitchedValue = true
        for specIdx, _ in ipairs(classData.specs) do
          classSwitchedValue = classSwitchedValue and db[classData.dataName][specIdx]
        end
        classSwitches[classData.dataName]:SetEnabled(classSwitchedValue)
        local colorString = RAID_CLASS_COLORS[classData.dataName].colorStr
        local coloredClassName = "|c"..
            ((not classSwitchedValue) and "ff777777" or colorString)..classData.displayName.."|r"
        classLabels[classData.dataName]:SetText(coloredClassName)
        classIcons[classData.dataName]:SetDesaturated(not classSwitchedValue)

        for specIdx, specId in ipairs(classData.specs) do
          specSwitches[specId]:SetEnabled(db[classData.dataName][specIdx])
          local _, specName, _, iconNumber = GetSpecializationInfoByID(specId)
          local coloredSpecName = "|c"..
              ((not db[classData.dataName][specIdx]) and "ff777777" or colorString)..specName.."|r"
          specLabels[specId]:SetText(coloredSpecName)
          specIcons[specId]:SetDesaturated(not db[classData.dataName][specIdx])
        end
      end
    end
  end

  ---@diagnostic disable-next-line: undefined-field
  local toggleAllButton = DF:CreateButton(manageFrame, nil, 120, 30, nil, nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  toggleAllButton:SetPoint("BOTTOMLEFT", manageFrame, "BOTTOMLEFT", 10, 10)
  toggleAllButton:SetText(L["Toggle All"])
  toggleAllButton.text_overlay:SetFont(toggleAllButton.text_overlay:GetFont(), 16)
  local allChecked = false
  toggleAllButton:SetClickFunction(function()
    allChecked = not allChecked
    for _, classData in ipairs(specData) do
      for specIdx, specId in ipairs(classData.specs) do
        if specSwitches[specId]:IsEnabled() then
          db[classData.dataName][specIdx] = allChecked
          specSwitches[specId]:SetValue(allChecked)
        end
      end
      if classSwitches[classData.dataName]:IsEnabled() then
        classSwitches[classData.dataName]:SetValue(allChecked)
      end
    end
  end)

  ---@diagnostic disable-next-line: undefined-field
  local importExportButton = DF:CreateButton(manageFrame, nil, 250, 30, nil, nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  importExportButton:SetPoint("BOTTOM", manageFrame, "BOTTOM", 0, 10)
  importExportButton:SetText("Import")
  importExportButton.text_overlay:SetFont(importExportButton.text_overlay:GetFont(), 16)
  importExportButton:SetClickFunction(function()
    manageFrame:Hide()
  end)
  importExportButton:Hide()
  manageFrame.importExportButton = importExportButton


  ---@diagnostic disable-next-line: undefined-field
  local closeButton = DF:CreateButton(manageFrame, nil, 90, 30, nil, nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  closeButton:SetPoint("BOTTOMRIGHT", manageFrame, "BOTTOMRIGHT", -10, 10)
  closeButton:SetText(L["Close"])
  closeButton.text_overlay:SetFont(closeButton.text_overlay:GetFont(), 16)
  closeButton:SetClickFunction(function()
    manageFrame:Hide()
  end)
end

local function showManageFrame(anchor, index, mode, dbRef, importExportCallback)
  setDBMode(mode, dbRef)
  if not manageFrame then createManageFrame() end
  manageFrame:SetAllValuesFromDB()
  manageFrame:SetEnabledStates(mode)
  manageFrame:ClearAllPoints()
  manageFrame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
  manageFrame:SetTitle("Talent Loadout Ex - "..(mode))
  manageFrame.importExportButton:SetText(mode)
  manageFrame.importExportButton:Enable()
  manageFrame.importExportButton:SetClickFunction(function()
    manageFrame:Hide()
    importExportCallback()
  end)
  manageFrame:Show()
end

local function dropdownOptions()
  return {}
end

local onSuccessfulTestOverride = function(profileString, profileKey)
  local importCallback = function()
    addon:Async(function()
      lapModule:importProfile(profileString, profileKey, false)
      manageFrame:Show()
      manageFrame.importExportButton:SetText(L["Done"])
      manageFrame.importExportButton:Disable()
    end, "tleImportOverride")
  end
  showManageFrame(addon.frames.mainFrame, 1, "Import", profileKey, importCallback)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = nil,
  copyButtonTooltipText = string.format(addon.L.noBuiltInProfileTextImport, moduleName),
  sortIndex = 2,
  hasGroups = true,
  manageFunc = showManageFrame,
  onSuccessfulTestOverride = onSuccessfulTestOverride,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
