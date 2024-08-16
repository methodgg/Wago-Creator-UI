---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local moduleName = "WeakAuras"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

local m
local frameWidth = 750
local frameHeight = 540
local scrollBoxWidth = 250
local scrollBoxHeight = frameHeight - 165
local lineHeight = 30

local getChosenResolution = function()
  return addon:GetCurrentPack().resolutions.chosen
end

local setWeakAuraExportState = function(resolution, id, value)
  addon:GetCurrentPack().profileKeys[resolution][moduleName][id] = value
end

local getWeakAuraExportState = function(resolution, id)
  addon:GetCurrentPack().profileKeys[resolution][moduleName] = addon:GetCurrentPack().profileKeys[resolution]
      [moduleName] or {}
  return addon:GetCurrentPack().profileKeys[resolution][moduleName][id]
end

local scrollBoxData = {
  [1] = {},
  [2] = {},
}

local function addToData(i, info)
  -- only insert if not already in list
  for _, existingInfo in ipairs(scrollBoxData[i]) do
    if existingInfo.id == info.id then
      return
    end
  end
  tinsert(scrollBoxData[i], info)
  setWeakAuraExportState(getChosenResolution(), info.id, true)
  m.scrollBoxes[i].onSearchBoxTextChanged()
end

local function copyExportString(id)
  addon:Async(function()
    addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 50, L["Preparing export string..."])
    if addon.db.exportOptions[moduleName] then
      if lapModule.setExportOptions then
        lapModule:setExportOptions(addon.db.exportOptions[moduleName])
      end
    end
    local exportString = lapModule:exportGroup(id)
    addon.copyHelper:Hide()
    if not exportString then return end
    addon:TextExport(exportString)
  end, "copyWAExportString")
end

local function createGroupScrollBox(frame, buttonConfig, scrollBoxIndex)
  local filteredData = {}

  local function updateFilteredData(searchString, data)
    wipe(filteredData)
    local initialData = scrollBoxData[scrollBoxIndex]
    if searchString and searchString ~= "" then
      for _, display in pairs(initialData) do
        if display.id:lower():find(searchString) then
          table.insert(filteredData, display)
        end
      end
    else
      -- for _, display in pairs(initialData) do
      --   table.insert(filteredData, display)
      -- end
    end
    --sort top level groups to the top
    table.sort(filteredData, function(a, b)
      local aIdx = a.parent and 0 or 1
      local bIdx = b.parent and 0 or 1
      if aIdx == bIdx then
        return a.id < b.id
      end
      return (aIdx > bIdx)
    end)
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
        line.nameLabel:SetText(info.id)
        local iconSource = info.groupIcon or info.displayIcon or 134400
        iconSource = tonumber(iconSource) or 134400
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
    icon:HookScript("OnLeave", function(self)
      if line:IsMouseOver() then return end
      for _, btn in ipairs(line.buttons) do
        btn:Hide()
      end
    end)
    ---@diagnostic disable-next-line: inject-field
    line.icon = icon

    local nameLabel = DF:CreateLabel(line, "", 12, "white")
    nameLabel:SetWordWrap(true)
    nameLabel:SetWidth(scrollBoxWidth - 80)
    nameLabel:SetPoint("left", icon, "right", 2, 0)
    line:SetScript("OnEnter", function(self)
      line:SetBackdropColor(unpack({ .8, .8, .8, 0.5 }))
    end)
    line:SetScript("OnLeave", function(self)
      line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }))
    end)
    ---@diagnostic disable-next-line: inject-field
    line.nameLabel = nameLabel

    ---@diagnostic disable-next-line: inject-field
    line.buttons = {}
    for idx, buttonData in ipairs(buttonConfig) do
      local button = DF:CreateButton(line, nil, lineHeight, lineHeight, "", nil, nil, buttonData.icon)
      button:SetTooltip(buttonData.tooltip)
      button:SetPushedTexture(buttonData.icon)
      button:SetPoint("right", line, "right", -(idx - 1) * lineHeight, 0)
      button:SetScript("OnClick", function(self)
        buttonData.onClick(line.info)
      end)
      button:HookScript("OnLeave", function(self)
        if line:IsMouseOver() then return end
        for _, btn in ipairs(line.buttons) do
          btn:Hide()
        end
      end)
      button:Hide()
      line.buttons[idx] = button
    end

    line:HookScript("OnEnter", function(self)
      for _, button in ipairs(line.buttons) do
        button:Show()
      end
    end)
    line:HookScript("OnLeave", function(self)
      if line:IsMouseOver() then return end
      for _, button in ipairs(line.buttons) do
        button:Hide()
      end
    end)

    line:SetMovable(true)
    line:RegisterForDrag("LeftButton")
    line:SetScript("OnDragStart", function(self)
      self:SetScript("OnUpdate", function(self)
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
      end)
      self:StartMoving()
    end)
    line:SetScript("OnDragStop", function(self)
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
            m.removeFromData(scrollBoxIndex, info)
          end
        else
          m.removeFromData(scrollBoxIndex, line.info)
        end
      end
    end)

    return line
  end

  local groupsScrollBox = DF:CreateScrollBox(frame, nil, scrollBoxUpdate, {},
    scrollBoxWidth, scrollBoxHeight, 0, lineHeight, createScrollLine, true)
  DF:ReskinSlider(groupsScrollBox)
  groupsScrollBox.ScrollBar.ScrollUpButton.Highlight:ClearAllPoints(false);
  groupsScrollBox.ScrollBar.ScrollDownButton.Highlight:ClearAllPoints(false);

  groupsScrollBox.ShowHighlight = function()
    groupsScrollBox:SetBackdropColor(.8, .8, .8, 0.5)
    groupsScrollBox:SetBackdropBorderColor(1, 1, 1, 1)
  end
  local red, green, blue, alpha = DF:GetDefaultBackdropColor()
  groupsScrollBox.HideHighlight = function()
    groupsScrollBox:SetBackdropColor(red, green, blue, alpha)
    groupsScrollBox:SetBackdropBorderColor(0, 0, 0, 1)
  end
  local instruction = (scrollBoxIndex == 1) and L["Search for your\nWeakAuras"] or L["Drag and drop\nto add WeakAuras"]
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
    groupsScrollBox:SetData(filtered)           --fix scroll height reflecting the data
    groupsScrollBox:OnVerticalScroll(0)         --scroll to the top
    groupsScrollBox:Refresh()                   --update the data displayed
    if widget then widget.widget:SetFocus() end --regain focus
  end
  groupsScrollBox.onSearchBoxTextChanged = onSearchBoxTextChanged

  local searchBox = LWF:CreateTextEntry(groupsScrollBox, scrollBoxWidth, 20, function() end)
  searchBox:SetPoint("bottomleft", groupsScrollBox, "topleft", 0, 2)
  groupsScrollBox.searchBox = searchBox

  searchBox:SetHook("OnChar", onSearchBoxTextChanged)
  searchBox:SetHook("OnTextChanged", onSearchBoxTextChanged)
  local searchLabel = DF:CreateLabel(groupsScrollBox, L["Search:"], DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
  searchLabel:SetPoint("bottomleft", searchBox, "topleft", 0, 2)

  return groupsScrollBox
end

local function createManageFrame(w, h)
  ---@diagnostic disable-next-line: undefined-field
  local panelOptions = {
    DontRightClickClose = true,
  }
  m = DF:CreateSimplePanel(UIParent, w, h, "", nil, panelOptions)
  ---@diagnostic disable-next-line: undefined-field
  DF:ApplyStandardBackdrop(m)
  DF:CreateBorder(m)
  m:ClearAllPoints()
  m:SetFrameStrata("FULLSCREEN")
  m:SetFrameLevel(100)
  m.__background:SetAlpha(1)
  m:SetMouseClickEnabled(true)
  m:SetTitle(L["WeakAuras Export Settings"])
  m:Hide()
  m.buttons = {}
  m.StartMoving = function() end

  m.scrollBoxes = {}

  local function removeFromData(i, info)
    for idx, lineInfo in ipairs(scrollBoxData[i]) do
      if lineInfo.id == info.id then
        tremove(scrollBoxData[i], idx)
        setWeakAuraExportState(getChosenResolution(), info.id, nil)
        break
      end
    end
    m.scrollBoxes[i].onSearchBoxTextChanged()
  end
  m.removeFromData = removeFromData

  local buttonConfigs = {
    [1] = {
      [1] = {
        icon = 450908,
        onClick = function(info)
          addToData(2, info)
        end,
        tooltip = "Add to export list",
      },
    },
    [2] = {
      [1] = {
        icon = 4200126,
        onClick = function(info)
          removeFromData(2, info)
        end,
        tooltip = "Remove from export list",
      },
      [2] = {
        icon = 134327,
        onClick = function(info)
          copyExportString(info.id)
        end,
        tooltip = "Copy export string directly to clipboard",
      },
    },
  }

  for idx, buttonConfig in ipairs(buttonConfigs) do
    local scrollBox = createGroupScrollBox(m, buttonConfig, idx)
    scrollBox:SetPoint("TOPLEFT", m, "TOPLEFT", 60 + ((idx - 1) * (scrollBoxWidth + 110)), -95)
    m.scrollBoxes[idx] = scrollBox
    local labelText = idx == 1 and "WeakAuras" or idx == 2 and L["Marked for Export"]
    local label = DF:CreateLabel(scrollBox, labelText, 20, "white")
    label:SetPoint("BOTTOM", scrollBox, "TOP", 0, 40)
  end

  local purgeWagoCheckbox = LWF:CreateCheckbox(m, 25,
    function(_, _, value)
      WagoUICreatorDB.exportOptions[moduleName].purgeWago = value
      lapModule:setExportOptions(WagoUICreatorDB.exportOptions[moduleName])
    end,
    WagoUICreatorDB.exportOptions[moduleName])
  purgeWagoCheckbox:SetPoint("BOTTOMLEFT", m, "BOTTOMLEFT", 60, 20)

  local purgeWagoLabel = DF:CreateLabel(m, "Startup", 16, "white")
  purgeWagoLabel:SetPoint("LEFT", purgeWagoCheckbox, "RIGHT", 10, 0)
  purgeWagoLabel:SetText(L["Purge Wago IDs for exports"])

  local okayButton = LWF:CreateButton(m, 200, 40, L["Okay"], 16)
  okayButton:SetClickFunction(function()
    m:Hide()
  end)
  okayButton:SetScript("OnEnter", function(self)
    okayButton.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  okayButton:SetScript("OnLeave", function(self)
    okayButton.button:SetBackdropBorderColor(1, 1, 1, 0)
  end)
  okayButton:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -60, 20)

  return m
end

local function showManageFrame(anchor)
  if not m then m = createManageFrame(frameWidth, frameHeight) end
  wipe(scrollBoxData[1])
  wipe(scrollBoxData[2])
  for id, display in pairs(WeakAurasSaved.displays) do
    table.insert(scrollBoxData[1], display)
    --populate second list
    if getWeakAuraExportState(getChosenResolution(), id) then
      table.insert(scrollBoxData[2], display)
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

local onSuccessfulTestOverride = function(_, weakAuraTable)
  WeakAuras.Import(weakAuraTable)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  copyFunc = nil,
  copyButtonTooltipText = nil,
  sortIndex = 11,
  hasGroups = true,
  manageFunc = showManageFrame,
  onSuccessfulTestOverride = onSuccessfulTestOverride,
}

addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
