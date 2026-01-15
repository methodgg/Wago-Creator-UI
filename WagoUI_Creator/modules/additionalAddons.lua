---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local moduleName = "Additional Addons"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")


local m
local frameWidth = 750
local frameHeight = 600
local scrollBoxWidth = 250
local scrollBoxHeight = frameHeight - 340
local lineHeight = 30
local scrollBoxData = {
  [1] = {},
  [2] = {}
}

local setAddonIncludedState = function(wagoId, value)
  local pack = addon:GetCurrentPackStashed()
  pack.additionalAddons = pack.additionalAddons or {}
  if value then
    pack.additionalAddons[wagoId] = value
  else
    pack.additionalAddons[wagoId] = nil
  end
end

local function addToData(i, info)
  -- only insert if not already in list
  for _, existingInfo in ipairs(scrollBoxData[i]) do
    if existingInfo.id == info.id then
      return
    end
  end
  tinsert(scrollBoxData[i], info)
  setAddonIncludedState(info.wagoId, info.id)
  m.scrollBoxes[i].onSearchBoxTextChanged()
  addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
end

local function removeFromData(i, info)
  for idx, existingInfo in ipairs(scrollBoxData[i]) do
    if existingInfo.id == info.id then
      tremove(scrollBoxData[i], idx)
      setAddonIncludedState(info.wagoId, nil)
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
    if searchString and searchString ~= "" then
      for _, display in pairs(initialData) do
        if display.id:lower():find(searchString) then
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
        line.nameLabel:SetText(info.id)

        local iconSource = info.icon
        iconSource = tonumber(iconSource) or iconSource
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
  local instruction = (scrollBoxIndex == 1) and L["Type to search for\nyour AddOns"] or L["Mark Addons as\nIncluded"]
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
  m:SetTitle(L["Additional Addons"])
  m:Hide()
  m.buttons = {}
  m.StartMoving = function()
  end

  local explainerLabel = DF:CreateLabel(m, L["ADDITIONAL_ADDONS_EXPLAINER"], 18, "white")
  explainerLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 5, -40)
  explainerLabel:SetPoint("TOPRIGHT", m, "TOPRIGHT", -5, -40)

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
    scrollBox:SetPoint("TOPLEFT", m, "TOPLEFT", 60 + ((idx - 1) * (scrollBoxWidth + 110)), -260)
    m.scrollBoxes[idx] = scrollBox
    local labelText = idx == 1 and L["Your Addons"] or idx == 2 and L["Included Addons"]
    local label = DF:CreateLabel(scrollBox, labelText, 20, "white")
    label:SetPoint("BOTTOM", scrollBox, "TOP", 0, 55)
  end

  local okayButton = LWF:CreateButton(m, 200, 40, L["Okay"], 16)
  okayButton:SetClickFunction(
    function()
      m:Hide()
    end
  )
  okayButton:SetPoint("BOTTOM", m, "BOTTOM", 0, 20)

  return m
end

local function showManageFrame(anchor)
  if not m then
    m = createManageFrame(frameWidth, frameHeight)
  end
  wipe(scrollBoxData[1])
  wipe(scrollBoxData[2])
  local blacklist = { --wago addons
    ["mKOv7Q6x"] = true,
    ["O67jdaN3"] = true,
    ["qv63o6bQ"] = true,
  }
  for _, module in pairs(LAP:GetAllModules()) do
    if module.wagoId and module.wagoId ~= "none" and module.wagoId ~= "baseline" then
      blacklist[module.wagoId] = true
    end
  end
  for addonIndex = 1, C_AddOns.GetNumAddOns() do
    local wagoId = C_AddOns.GetAddOnMetadata(addonIndex, "X-Wago-ID")
    if wagoId and not blacklist[wagoId] then
      local entry = {
        id = C_AddOns.GetAddOnInfo(addonIndex),
        wagoId = wagoId,
        icon = C_AddOns.GetAddOnMetadata(addonIndex, "IconTexture") or 134400
      }
      tinsert(scrollBoxData[1], entry)
    end
  end
  local pack = addon:GetCurrentPackStashed()
  if pack.additionalAddons then
    for wagoId, addonName in pairs(pack.additionalAddons) do
      ---@type string | number
      local icon = 134400
      for addonIndex = 1, C_AddOns.GetNumAddOns() do
        local id = C_AddOns.GetAddOnMetadata(addonIndex, "X-Wago-ID")
        if id == wagoId then
          icon = C_AddOns.GetAddOnMetadata(addonIndex, "IconTexture") or 134400
          break
        end
      end
      local entry = {
        id = addonName,
        wagoId = wagoId,
        icon = icon
      }
      tinsert(scrollBoxData[2], entry)
    end
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
