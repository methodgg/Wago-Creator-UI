local _, addon = ...
local L = addon.L
local DF = _G["DetailsFramework"]
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local manageFrame
local frameWidth = 850
local frameHeight = 450

---@type LibAddonProfilesModule
local lapModule = {
  moduleName = "UI Pack Settings",
  icon = 4548874,
  isLoaded = function() return true end,
  needsInitialization = function() return false end,
}

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

local db

local getChosenResolution = function()
  return addon:GetCurrentPack().resolutions.chosen
end

local function setupDB()
  local currentUIPack = addon:GetCurrentPack()
  currentUIPack.wagoSettings = currentUIPack.wagoSettings or {}
  currentUIPack.wagoSettings[getChosenResolution()] = currentUIPack.wagoSettings[getChosenResolution()] or {}
  currentUIPack.wagoSettings[getChosenResolution()].enabledSpecs = currentUIPack.wagoSettings
      [getChosenResolution()].enabledSpecs or {}
  db = currentUIPack.wagoSettings[getChosenResolution()]
  for _, classData in ipairs(specData) do
    if not db.enabledSpecs[classData.dataName] then db.enabledSpecs[classData.dataName] = {} end
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
  hooksecurefunc(addon, "UpdatePackSelectedUI", function()
    manageFrame:Hide()
  end)

  local enabledSpecsLabel = DF:CreateLabel(manageFrame, "Startup", 16, "white")
  enabledSpecsLabel:SetText(
    L["wagoSettingsExplainer"]..
    "\n\n"..L["wagoSettingsSpecs"])
  enabledSpecsLabel:SetPoint("TOPLEFT", manageFrame, "TOPLEFT", 12, -30)

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

  local function updateSwitchAndLabelVisual(icon, label, text, className, value)
    local colorString = RAID_CLASS_COLORS[className].colorStr
    local coloredClassOrSpecName = "|c"..
        ((not value) and "ff777777" or colorString)..text.."|r"
    icon:SetDesaturated(not value)
    label:SetText(coloredClassOrSpecName)
  end

  for idx, classData in ipairs(specData) do
    ---@diagnostic disable-next-line: undefined-field
    local classSwitch = DF:CreateSwitch(manageFrame,
      function(x, y, value)
        updateSwitchAndLabelVisual(classIcons[classData.dataName], classLabels[classData.dataName], classData
          .displayName, classData.dataName, value)
        for specIdx, specId in ipairs(classData.specs) do
          db.enabledSpecs[classData.dataName][specIdx] = value
          specSwitches[specId]:SetValue(value)
          local _, specName = GetSpecializationInfoByID(specId)
          updateSwitchAndLabelVisual(specIcons[specId], specLabels[specId], specName,
            classData.dataName, value)
        end
      end,
      false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
      DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
    classSwitches[classData.dataName] = classSwitch
    classSwitch:SetSize(size, size)
    classSwitch:SetAsCheckBox()
    local yOffset = -110 + (math.floor((idx - 1) / classesPerRow) * -columnHeight)
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
          db.enabledSpecs[classData.dataName][specIdx] = value
          local allSpecsChecked = true
          for sIdx, _ in ipairs(classData.specs) do
            allSpecsChecked = allSpecsChecked and db.enabledSpecs[classData.dataName][sIdx]
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
        classSwitchedValue = classSwitchedValue and db.enabledSpecs[classData.dataName][specIdx]
      end
      classSwitches[classData.dataName]:SetValue(classSwitchedValue)
      updateSwitchAndLabelVisual(classIcons[classData.dataName], classLabels[classData.dataName], classData.displayName,
        classData.dataName,
        classSwitchedValue)

      for specIdx, specId in ipairs(classData.specs) do
        local specSwitchedValue = db.enabledSpecs[classData.dataName][specIdx]
        specSwitches[specId]:SetValue(specSwitchedValue)

        local _, specName = GetSpecializationInfoByID(specId)
        updateSwitchAndLabelVisual(specIcons[specId], specLabels[specId], specName, classData.dataName, specSwitchedValue)
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
          db.enabledSpecs[classData.dataName][specIdx] = allChecked
          specSwitches[specId]:SetValue(allChecked)
        end
      end
      if classSwitches[classData.dataName]:IsEnabled() then
        classSwitches[classData.dataName]:SetValue(allChecked)
      end
    end
  end)

  ---@diagnostic disable-next-line: undefined-field
  local closeButton = DF:CreateButton(manageFrame, nil, 90, 30, nil, nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  closeButton:SetPoint("BOTTOMRIGHT", manageFrame, "BOTTOMRIGHT", -10, 10)
  closeButton:SetText(L["Okay"])
  closeButton.text_overlay:SetFont(closeButton.text_overlay:GetFont(), 16)
  closeButton:SetClickFunction(function()
    manageFrame:Hide()
  end)
end

local function showManageFrame(anchor)
  if not manageFrame then
    createManageFrame()
    manageFrame:ClearAllPoints()
    manageFrame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    manageFrame:SetTitle(lapModule.moduleName)
  end
  setupDB()
  manageFrame:SetAllValuesFromDB()
  manageFrame:Show()
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = lapModule.moduleName,
  lapModule = lapModule,
  dropdownOptions = function() return {} end,
  copyFunc = nil,
  hookRefresh = nil,
  copyButtonTooltipText = nil,
  sortIndex = 0,
  hasGroups = true,
  manageFunc = showManageFrame,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
