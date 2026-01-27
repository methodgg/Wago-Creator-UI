---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local moduleName = "Blizzard Cooldown Manager"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")


local m
local frameWidth = 750
local frameHeight = 600
local scrollBoxWidth = 250
local scrollBoxHeight = frameHeight - 380
local lineHeight = 30
local scrollBoxData = {
  [1] = {},
  [2] = {}
}


local isClassAndSpecTagSameClass = function(tagA, tagB)
  local classA = math.floor(tagA / 10)
  local classB = math.floor(tagB / 10)
  return classA == classB
end


-- the reason we export separately is that CDM profiles swap around values in their tables a lot
-- and areProfileStringsEqual is not reliable because of that
local function updateCooldownManagerData()
  local pack = addon:GetCurrentPackStashed()
  local oldPack = addon.db.creatorUI[addon.db.chosenPack]
  local currentClassAndSpecTag = CooldownViewerUtil.GetCurrentClassAndSpecTag()
  local added = {}
  local removed = {}
  if not pack.cdmData or not pack.cdmData.profileKeys then
    addon.copyHelper:SmartFadeOut(2, L["No profiles to export!"])
    return
  end
  ---@type LibAddonProfilesModule
  local lapModule = LAP:GetModule("Blizzard Cooldown Manager")

  --need to hide the config window to save any unsaved changes
  lapModule:closeConfig()

  local profilesToExportForCurrentClass = {}
  local actualProfilesOfCurrentCharacter = lapModule.getProfileKeys and lapModule:getProfileKeys()

  for classAndSpecTag, profiles in pairs(pack.cdmData.profileKeys) do
    if isClassAndSpecTagSameClass(classAndSpecTag, currentClassAndSpecTag) then
      for _, profile in pairs(profiles) do
        if actualProfilesOfCurrentCharacter[profile.profileKey] then
          tinsert(profilesToExportForCurrentClass, profile)
        end
      end
    end
  end

  --check for removed profiles
  if pack.cdmData.profiles then
    for classAndSpecTag, profiles in pairs(pack.cdmData.profiles) do
      for profileKey, _ in pairs(profiles) do
        if not pack.cdmData.profileKeys[classAndSpecTag] or not pack.cdmData.profileKeys[classAndSpecTag][profileKey] then
          pack.cdmData.profiles[classAndSpecTag][profileKey] = nil
          tinsert(removed, profileKey)
        end
      end
    end
  end

  if not next(profilesToExportForCurrentClass) and #removed == 0 then
    addon.copyHelper:SmartFadeOut(2, L["No Changes detected"])
    return
  end
  local timestamp = GetServerTime()
  for _, profileInfo in pairs(profilesToExportForCurrentClass) do
    ---@type any
    local newExport = lapModule:exportProfile(profileInfo.profileKey)
    ---@type any
    local oldExport = oldPack.cdmData and oldPack.cdmData.profiles and
        oldPack.cdmData.profiles[profileInfo.classAndSpecTag] and
        oldPack.cdmData.profiles[profileInfo.classAndSpecTag][profileInfo.profileKey]
    if not lapModule:areProfileStringsEqual(newExport, oldExport) then
      pack.cdmData.profiles = pack.cdmData.profiles or {}
      pack.cdmData.profiles[profileInfo.classAndSpecTag] = pack.cdmData.profiles[profileInfo.classAndSpecTag] or {}
      pack.cdmData.profiles[profileInfo.classAndSpecTag][profileInfo.profileKey] = newExport

      pack.cdmData.profileKeys[profileInfo.classAndSpecTag][profileInfo.profileKey].metaData = pack.cdmData.profileKeys
          [profileInfo.classAndSpecTag][profileInfo.profileKey].metaData or {}
      pack.cdmData.profileKeys[profileInfo.classAndSpecTag][profileInfo.profileKey].metaData.lastUpdatedAt =
      {
        [profileInfo.profileKey] = timestamp
      }
      tinsert(added, profileInfo.profileKey)
    end
  end

  if #added > 0 or #removed > 0 then
    pack.includedAddons[lapModule.moduleName] = lapModule.wagoId
    pack.updatedAt = timestamp
    addon:OpenReleaseNoteInput(timestamp, {}, {}, {}, {}, added, removed)
  else
    addon.copyHelper:SmartFadeOut(2, L["No Changes detected"])
  end

  -- have to remove CDM from included addons if there are no profiles
  local numCdmProfiles = 0
  if pack.cdmData and pack.cdmData.profiles then
    for _, profileStrings in pairs(pack.cdmData.profiles) do
      for _, _ in pairs(profileStrings) do
        numCdmProfiles = numCdmProfiles + 1
      end
    end
  end
  if numCdmProfiles == 0 then
    pack.includedAddons[lapModule.moduleName] = nil
  end
end

---@param classAndSpecTag number class and spec tag like "121" for Havoc DH (12 = DH, 1 = Havoc)
local getSpecIconFromClassAndSpecTag = function(classAndSpecTag)
  local classID = math.floor(classAndSpecTag / 10);
  local specIndex = classAndSpecTag % 10;
  local isInspect, isPet, inspectTarget, gender, groupIndex = false, false, nil, nil, nil;
  local icon = select(4,
    ---@diagnostic disable-next-line: redundant-parameter
    C_SpecializationInfo.GetSpecializationInfo(specIndex, isInspect, isPet, inspectTarget, gender, groupIndex, classID));
  return icon or 134400 --questionmark icon fallback
end

---@param s string the string to wrap
---@param classAndSpecTag number class and spec tag like 121 for Havoc DH (12 = DH, 1 = Havoc)
local function wrapStringInClassColor(s, classAndSpecTag)
  local classID = math.floor(classAndSpecTag / 10);
  local classInfo = C_CreatureInfo.GetClassInfo(classID) or "Adventurer"
  if classInfo.className ~= "Adventurer" then
    local _, _, _, classHexString = GetClassColor(classInfo.classFile)
    return "|c"..classHexString..s.."|r"
  end
  return s
end

local setProfileIncludedState = function(info, shouldInclude)
  local pack = addon:GetCurrentPackStashed()
  pack.cdmData = pack.cdmData or {}
  pack.cdmData.profileKeys = pack.cdmData.profileKeys or {}
  pack.cdmData.profileKeys[info.classAndSpecTag] = pack.cdmData.profileKeys[info.classAndSpecTag] or {}
  pack.cdmData.profileKeys[info.classAndSpecTag][info.profileKey] = shouldInclude and info or nil
end

local function addToData(i, info)
  local alreadyIncluded = false
  for k, v in pairs(scrollBoxData[i]) do
    if v.classAndSpecTag == info.classAndSpecTag and v.profileKey == info.profileKey then
      alreadyIncluded = true
    end
  end
  if not alreadyIncluded then
    tinsert(scrollBoxData[i], info)
  end
  setProfileIncludedState(info, true)
  m.scrollBoxes[i].onSearchBoxTextChanged()
  addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
end

local function removeFromData(i, info)
  for idx, existingInfo in ipairs(scrollBoxData[i]) do
    if existingInfo.profileKey == info.profileKey and existingInfo.classAndSpecTag == info.classAndSpecTag then
      tremove(scrollBoxData[i], idx)
      setProfileIncludedState(info, false)
      m.scrollBoxes[i].onSearchBoxTextChanged()
      addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
      return
    end
  end
end

local function createGroupScrollBox(frame, buttonConfig, scrollBoxIndex)
  local filteredData = {}

  local function updateFilteredData(searchString, data)
    wipe(filteredData)
    local initialData = scrollBoxData[scrollBoxIndex]
    if searchString then
      if searchString ~= "" then
        for _, display in pairs(initialData) do
          if display.profileKey:lower():find(searchString) then
            table.insert(filteredData, display)
          end
        end
      else
        --add all
        for _, display in pairs(initialData) do
          table.insert(filteredData, display)
        end
      end
    else
      if scrollBoxIndex == 2 then
        for _, display in pairs(initialData) do
          table.insert(filteredData, display)
        end
      end
    end
    return filteredData
  end

  local function scrollBoxUpdate(self, data, offset, totalLines)
    if self.instructionLabel then
      if #filteredData == 0 then
        self.instructionLabel:Show()
      else
        self.instructionLabel:Hide()
      end
    end
    for i = 1, totalLines do
      local index = i + offset
      local info = filteredData[index]
      if (info) then
        local line = self:GetLine(i)
        line.nameLabel:SetText(info.coloredName)

        local iconSource = info.icon or 135724
        line.icon:SetTexture(iconSource)
        line.icon:SetPushedTexture(iconSource)
        line.info = info
        for _, btn in ipairs(line.buttons) do
          btn:Hide()
        end
      end
    end
  end

  local function createScrollLine(self, index)
    local line = CreateFrame("Button", nil, self)
    local function setLinePoints()
      line:ClearAllPoints()
      PixelUtil.SetPoint(line, "TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight + 1)) - 1)
    end
    setLinePoints()
    line:SetSize(scrollBoxWidth - 2, self.LineHeight)
    if not line.SetBackdrop then
      Mixin(line, BackdropTemplateMixin)
    end
    line:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true })
    line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }))

    local icon = DF:CreateButton(line, nil, lineHeight, lineHeight, "", nil, nil, 134400, nil, nil, nil, nil)
    icon:SetPoint("left", line, "left", 0, 0)
    icon:ClearHighlightTexture()
    icon:HookScript(
      "OnLeave",
      function(self)
        if line:IsMouseOver() then
          return
        end
        for _, btn in ipairs(line.buttons) do
          btn:Hide()
        end
      end
    )
    ---@diagnostic disable-next-line: inject-field
    line.icon = icon

    local nameLabel = DF:CreateLabel(line, "", 12, "white")
    nameLabel:SetWordWrap(true)
    nameLabel:SetWidth(scrollBoxWidth - 80)
    nameLabel:SetPoint("left", icon, "right", 2, 0)
    line:SetScript(
      "OnEnter",
      function(self)
        line:SetBackdropColor(unpack({ .8, .8, .8, 0.5 }))
      end
    )
    line:SetScript(
      "OnLeave",
      function(self)
        line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }))
      end
    )
    ---@diagnostic disable-next-line: inject-field
    line.nameLabel = nameLabel

    ---@diagnostic disable-next-line: inject-field
    line.buttons = {}
    for idx, buttonData in ipairs(buttonConfig) do
      local button = DF:CreateButton(line, nil, lineHeight, lineHeight, "", nil, nil, buttonData.icon)
      button:SetTooltip(buttonData.tooltip)
      button:SetPushedTexture(buttonData.icon)
      button:SetPoint("right", line, "right", -(idx - 1) * lineHeight, 0)
      button:SetScript(
        "OnClick",
        function(self)
          buttonData.onClick(line.info)
        end
      )
      button:HookScript(
        "OnLeave",
        function(self)
          if line:IsMouseOver() then
            return
          end
          for _, btn in ipairs(line.buttons) do
            btn:Hide()
          end
        end
      )
      button:Hide()
      line.buttons[idx] = button
    end

    line:HookScript(
      "OnEnter",
      function(self)
        for _, button in ipairs(line.buttons) do
          button:Show()
        end
      end
    )
    line:HookScript(
      "OnLeave",
      function(self)
        if line:IsMouseOver() then
          return
        end
        for _, button in ipairs(line.buttons) do
          button:Hide()
        end
      end
    )

    line:SetMovable(true)
    line:RegisterForDrag("LeftButton")
    line:SetScript(
      "OnDragStart",
      function(self)
        self:SetScript(
          "OnUpdate",
          function(self)
            local dropRegionIndex = 1
            for i = 2, #m.scrollBoxes do
              if m.scrollBoxes[i]:IsMouseOver() then
                dropRegionIndex = i
              end
            end
            for i = 2, #m.scrollBoxes do
              if i == dropRegionIndex then
                m.scrollBoxes[i].ShowHighlight()
              else
                m.scrollBoxes[i].HideHighlight()
              end
            end
          end
        )
        self:StartMoving()
      end
    )
    line:SetScript(
      "OnDragStop",
      function(self)
        self:SetScript("OnUpdate", nil)
        self:StopMovingOrSizing()
        setLinePoints()
        local dropRegionIndex = 1
        for i = 2, #m.scrollBoxes do
          m.scrollBoxes[i].HideHighlight()
          if m.scrollBoxes[i]:IsMouseOver() then
            dropRegionIndex = i
            break
          end
        end
        if dropRegionIndex ~= scrollBoxIndex then
          if dropRegionIndex > 1 then
            local info = line.info
            addToData(dropRegionIndex, info)
            if scrollBoxIndex > 1 then
              removeFromData(scrollBoxIndex, info)
            end
          else
            removeFromData(scrollBoxIndex, line.info)
          end
        end
      end
    )

    return line
  end

  local groupsScrollBox =
      DF:CreateScrollBox(
        frame,
        nil,
        scrollBoxUpdate,
        {},
        scrollBoxWidth,
        scrollBoxHeight,
        0,
        lineHeight,
        createScrollLine,
        true
      )
  DF:ReskinSlider(groupsScrollBox)
  groupsScrollBox.ScrollBar.ScrollUpButton.Highlight:ClearAllPoints(false)
  groupsScrollBox.ScrollBar.ScrollDownButton.Highlight:ClearAllPoints(false)

  groupsScrollBox.ShowHighlight = function()
    groupsScrollBox:SetBackdropColor(.8, .8, .8, 0.5)
    groupsScrollBox:SetBackdropBorderColor(1, 1, 1, 1)
  end
  local red, green, blue, alpha = DF:GetDefaultBackdropColor()
  groupsScrollBox.HideHighlight = function()
    groupsScrollBox:SetBackdropColor(red, green, blue, alpha)
    groupsScrollBox:SetBackdropBorderColor(0, 0, 0, 1)
  end
  local instruction = (scrollBoxIndex == 1) and L["Type to search for\nyour Profiles"] or L["Add Profiles\nto Export"]
  local instructionLabel = DF:CreateLabel(groupsScrollBox, instruction, 20, "grey")
  instructionLabel:SetTextColor(0.5, 0.5, 0.5, 1)
  instructionLabel:SetJustifyH("CENTER")
  instructionLabel:SetPoint("CENTER", groupsScrollBox, "CENTER", 0, 0)
  groupsScrollBox.instructionLabel = instructionLabel

  local function onSearchBoxTextChanged(...)
    local editBox, _, widget, searchString = ...
    local text = groupsScrollBox.searchBox:GetText()
    searchString = searchString or text:lower()
    local filtered = updateFilteredData(searchString, groupsScrollBox.data)
    if widget then
      if widget.previousNumData and widget.previousNumData == #filtered then
        return
      end
      widget.previousNumData = #filtered
    end
    -- it still breaks in some cases, but this is the best I can do for now
    groupsScrollBox:SetData(filtered)   --fix scroll height reflecting the data
    groupsScrollBox:OnVerticalScroll(0) --scroll to the top
    groupsScrollBox:Refresh()           --update the data displayed
    if widget then
      widget.widget:SetFocus()
    end --regain focus
  end
  groupsScrollBox.onSearchBoxTextChanged = onSearchBoxTextChanged

  local searchBox =
      LWF:CreateTextEntry(
        groupsScrollBox,
        scrollBoxWidth,
        30,
        function()
        end,
        16
      )
  searchBox:SetPoint("BOTTOMLEFT", groupsScrollBox, "TOPLEFT", 0, 2)
  groupsScrollBox.searchBox = searchBox

  searchBox:SetHook("OnChar", onSearchBoxTextChanged)
  searchBox:SetHook("OnTextChanged", onSearchBoxTextChanged)
  local searchLabel = DF:CreateLabel(groupsScrollBox, L["Search:"], DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
  searchLabel:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", 0, 2)

  return groupsScrollBox
end

local function createManageFrame(w, h)
  local panelOptions = {
    DontRightClickClose = true,
    NoTUISpecialFrame = false
  }
  m = DF:CreateSimplePanel(UIParent, w, h, "", nil, panelOptions)
  LWF:ScaleFrameByUIParentScale(m, 0.5333333333333)
  DF:ApplyStandardBackdrop(m)
  DF:CreateBorder(m)
  m:ClearAllPoints()
  m:SetFrameStrata("FULLSCREEN")
  m:SetFrameLevel(100)
  m.__background:SetAlpha(1)
  m:SetMouseClickEnabled(true)
  m:SetTitle(L["Blizzard Cooldown Manager"])
  m:Hide()
  m.buttons = {}
  m.StartMoving = function()
  end

  local explainerLabel = DF:CreateLabel(m, L["CDM_PROFILES_EXPLAINER"], 18, "white")
  explainerLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 5, -40)
  explainerLabel:SetPoint("TOPRIGHT", m, "TOPRIGHT", -5, -40)

  local exportWarningLabel = DF:CreateLabel(m, L["CDM_EXPORT_WARNING"], 18, "red")
  exportWarningLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 5, -110)
  exportWarningLabel:SetPoint("TOPRIGHT", m, "TOPRIGHT", -5, -110)

  m:HookScript(
    "OnShow",
    function()
      LWF:ToggleLockoutFrame(true, addon.frames, addon.frames.mainFrame)
    end
  )

  m:HookScript(
    "OnHide",
    function()
      LWF:ToggleLockoutFrame(false, addon.frames, addon.frames.mainFrame)
    end
  )

  local buttonConfigs = {
    [1] = {
      [1] = {
        icon = [[Interface\AddOns\WagoUI_Creator\media\misc_arrowright]],
        onClick = function(info)
          addToData(2, info)
        end,
        tooltip = L["Mark as included"]
      }
    },
    [2] = {
      [1] = {
        icon = [[Interface\AddOns\WagoUI_Creator\media\misc_rnrredxbutton]],
        onClick = function(info)
          removeFromData(2, info)
        end,
        tooltip = L["Remove"]
      },
    }
  }
  m.scrollBoxes = {}
  for idx, buttonConfig in ipairs(buttonConfigs) do
    local scrollBox = createGroupScrollBox(m, buttonConfig, idx)
    scrollBox:SetPoint("TOPLEFT", m, "TOPLEFT", 60 + ((idx - 1) * (scrollBoxWidth + 110)), -290)
    m.scrollBoxes[idx] = scrollBox
    local labelText = idx == 1 and L["Your Profiles"] or idx == 2 and L["Exported Profiles"]
    local label = DF:CreateLabel(scrollBox, labelText, 20, "white")
    label:SetPoint("BOTTOM", scrollBox, "TOP", 0, 55)
  end

  local okayButton = LWF:CreateButton(m, 200, 40, L["Cancel"], 16)
  okayButton:SetClickFunction(
    function()
      m:Hide()
    end
  )
  okayButton:SetPoint("BOTTOM", m, "BOTTOM", -120, 20)

  local exportButton = LWF:CreateButton(m, 200, 40, L["Export"], 16)
  exportButton:SetClickFunction(
    function()
      addon:Async(
        function()
          updateCooldownManagerData()
        end, "updateCooldownManagerData")
      m:Hide()
    end
  )
  exportButton:SetPoint("BOTTOM", m, "BOTTOM", 120, 20)

  return m
end

local function showManageFrame(anchor)
  if not m then
    m = createManageFrame(frameWidth, frameHeight)
  end
  wipe(scrollBoxData[1])
  wipe(scrollBoxData[2])

  -- fill with current characters cdm profiles
  for profileKey, profileData in pairs(lapModule:getProfileKeys()) do
    local info = {
      profileKey = profileKey,
      icon = getSpecIconFromClassAndSpecTag(profileData.classAndSpecTag),
      coloredName = wrapStringInClassColor(profileKey, profileData.classAndSpecTag),
      classAndSpecTag = profileData.classAndSpecTag,
    }
    tinsert(scrollBoxData[1], info)
  end

  -- fill profiles to export from pack data
  local pack = addon:GetCurrentPackStashed()
  if pack.cdmData and pack.cdmData.profileKeys then
    for _, profiles in pairs(pack.cdmData.profileKeys) do
      for _, info in pairs(profiles) do
        tinsert(scrollBoxData[2], info)
      end
    end
  end

  for i = 1, 2 do
    m.scrollBoxes[i]:SetData(scrollBoxData[i])
    m.scrollBoxes[i]:Refresh()
    m.scrollBoxes[i].onSearchBoxTextChanged(nil, nil, nil, "")
    m.scrollBoxes[i].searchBox.editbox:SetText("")
  end

  m:ClearAllPoints()
  m:SetPoint("CENTER", anchor, "CENTER", 0, 0)
  m:Show()
end

local function dropdownOptions()
  return {}
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  hasGroups = true,
  manageFunc = showManageFrame,
}

addon.ModuleFunctions.specialModules[moduleName] = moduleConfig
