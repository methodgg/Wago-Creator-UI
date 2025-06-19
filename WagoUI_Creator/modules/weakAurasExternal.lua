---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local moduleName = "Wago WeakAuras"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

local m
local frameWidth = 750
local frameHeight = 540
local scrollBoxWidth = 250
local scrollBoxHeight = frameHeight - 340
local lineHeight = 30
local openWAButton

---@param weakAuraId string
---@param wagoSlug string | nil
local setWeakAuraIncludedState = function(weakAuraId, wagoSlug)
  local pack = addon:GetCurrentPackStashed()
  pack.wagoWeakAuras = pack.wagoWeakAuras or {}
  pack.wagoWeakAuras[weakAuraId] = wagoSlug
end


local scrollBoxData = {
  [1] = {},
  [2] = {}
}

---@param i number
---@param info table
local function addToData(i, info)
  -- only insert if not already in list
  for _, existingInfo in ipairs(scrollBoxData[i]) do
    if existingInfo.info.id == info.info.id then
      m.removeFromData(i, info)
    end
  end

  local wagoSlug = info.info.url:match("https://wago.io/([^/%s]+)")
  setWeakAuraIncludedState(info.info.id, wagoSlug)

  local data = {
    info = info.info,
  }

  tinsert(scrollBoxData[i], data)
  m.scrollBoxes[i].onSearchBoxTextChanged()
  addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
end

local getWeakAuraDepth, clearWeakAuraCaches, getNumTotalControlledChildren
do
  local depthCache = {}
  local numChildrenCache = {}

  function clearWeakAuraCaches()
    wipe(depthCache)
    wipe(numChildrenCache)
  end

  ---@param data table
  ---@return integer
  local function getDepth(data)
    local parentId = data.parent
    if not parentId then
      return 0
    end
    return 1 + getDepth(WeakAurasSaved.displays[parentId])
  end

  ---@param id string
  ---@return integer
  function getWeakAuraDepth(id)
    if depthCache[id] then
      return depthCache[id]
    end
    local data = WeakAurasSaved.displays[id]
    local depth = getDepth(data)
    depthCache[id] = depth
    return depth
  end

  ---@param data table
  local function getNumControlled(data)
    if not data.controlledChildren then
      return 0
    end
    local num = 0
    for _, childId in ipairs(data.controlledChildren) do
      num = num + 1 + getNumTotalControlledChildren(childId)
    end
    return num
  end

  ---@param id string
  ---@return integer
  function getNumTotalControlledChildren(id)
    if numChildrenCache[id] then
      return numChildrenCache[id]
    end
    local data = WeakAurasSaved.displays[id]
    local numControlled = getNumControlled(data)
    numChildrenCache[id] = numControlled
    return numControlled
  end
end

local function createGroupScrollBox(frame, buttonConfig, scrollBoxIndex)
  local filteredData = {}

  local function updateFilteredData(searchString, data)
    wipe(filteredData)
    local initialData = scrollBoxData[scrollBoxIndex]
    if searchString and searchString ~= "" then
      for _, entry in pairs(initialData) do
        if entry.info.id:lower():find(searchString) then
          table.insert(filteredData, entry)
        end
      end
    else
      if scrollBoxIndex == 2 then
        for _, entry in pairs(initialData) do
          table.insert(filteredData, entry)
        end
      end
    end
    --sort by depth and id
    --TODO: might just do full tree structure anyway
    --      use sort and then indent children
    --      clicks on parents expand/collapse children
    --      still show a plus sign or whatever for parents with children
    table.sort(
      filteredData,
      function(a, b)
        local aDepth = getWeakAuraDepth(a.info.id)
        local bDepth = getWeakAuraDepth(b.info.id)
        local aChildren = getNumTotalControlledChildren(a.info.id)
        local bChildren = getNumTotalControlledChildren(b.info.id)
        if aDepth ~= bDepth then
          return aDepth < bDepth
        end
        if aChildren ~= bChildren then
          return aChildren > bChildren
        end
        return (a.info.id < b.info.id)
      end
    )
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
        local name = info.info.id
        line.nameLabel:SetText(name)
        if info.info.iconSource == -1 then
          -- TODO
          -- we dont have an icon, would need to recreate the logic of WeakAuras to get it via spellCache
          -- maybe we are not doing this one...
        end
        local iconSource = info.info.groupIcon or info.info.displayIcon or 134400
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
      button:HookScript("OnEnter", function(self)
        local additionalText = buttonData.type == "urlCopy" and "\n\n"..line.info.info.url or ""
        button:SetTooltip(buttonData.tooltip..additionalText)
      end)
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
              m.removeFromData(scrollBoxIndex, info)
            end
          else
            m.removeFromData(scrollBoxIndex, line.info)
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
  local instruction = (scrollBoxIndex == 1) and L["Type to search for\nyour WeakAuras"] or L["Add WeakAuras\nto Export"]
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
  ---@diagnostic disable-next-line: undefined-field
  DF:ApplyStandardBackdrop(m)
  DF:CreateBorder(m)
  m:ClearAllPoints()
  m:SetFrameStrata("FULLSCREEN")
  m:SetFrameLevel(100)
  m.__background:SetAlpha(1)
  m:SetMouseClickEnabled(true)
  m:SetTitle(L["Wago WeakAuras Export Settings"])
  m:Hide()
  m.buttons = {}
  m.StartMoving = function()
  end

  local explainerLabel = DF:CreateLabel(m, L["EXTERNAL_WEAKAURAS_EXPLAINER"], 18, "white")
  explainerLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 5, -40)
  explainerLabel:SetPoint("TOPRIGHT", m, "TOPRIGHT", -5, -40)

  m:HookScript(
    "OnShow",
    function()
      LWF:ToggleLockoutFrame(true, addon.frames, addon.frames.mainFrame)
      m.scrollBoxes[1].searchBox.editbox:SetFocus()
    end
  )

  m:HookScript(
    "OnHide",
    function()
      LWF:ToggleLockoutFrame(false, addon.frames, addon.frames.mainFrame)
      LWF:EndSplitView(WeakAurasOptions, addon.ResetFramePosition)
    end
  )

  m.scrollBoxes = {}

  local function removeFromData(i, info)
    for idx, lineInfo in ipairs(scrollBoxData[i]) do
      if lineInfo.info.id == info.info.id then
        tremove(scrollBoxData[i], idx)
        setWeakAuraIncludedState(info.info.id, nil)
        break
      end
    end
    m.scrollBoxes[i].onSearchBoxTextChanged()
    addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
  end
  m.removeFromData = removeFromData

  local buttonConfigs = {
    [1] = {
      [1] = {
        icon = 450908,
        onClick = function(info)
          addToData(2, info)
        end,
        tooltip = L["Add to export list"]
      },
      [2] = {
        icon = 134327,
        onClick = function(info)
          addon:TextExport(info.info.url)
        end,
        tooltip = L["Copy Wago Url"],
        type = "urlCopy"
      }
    },
    [2] = {
      [1] = {
        icon = 4200126,
        onClick = function(info)
          removeFromData(2, info)
        end,
        tooltip = L["Remove from export list"]
      },
      [2] = {
        icon = 134327,
        onClick = function(info)
          addon:TextExport(info.info.url)
        end,
        tooltip = L["Copy Wago Url"],
        type = "urlCopy"
      }
    }
  }

  for idx, buttonConfig in ipairs(buttonConfigs) do
    local scrollBox = createGroupScrollBox(m, buttonConfig, idx)
    scrollBox:SetPoint("TOPLEFT", m, "TOPLEFT", 60 + ((idx - 1) * (scrollBoxWidth + 110)), -260)
    m.scrollBoxes[idx] = scrollBox
    local labelText = idx == 1 and L["Your WeakAuras"] or idx == 2 and L["Included Wago WeakAuras"]
    local label = DF:CreateLabel(scrollBox, labelText, 20, "white")
    label:SetPoint("BOTTOM", scrollBox, "TOP", 0, 55)
  end

  local okayButton = LWF:CreateButton(m, 200, 40, L["Okay"], 16)
  okayButton:SetClickFunction(
    function()
      m:Hide()
    end
  )
  okayButton:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -60, 20)

  openWAButton = LWF:CreateButton(m, 200, 40, L["Toggle WA Options"], 16)
  openWAButton:SetClickFunction(
    function()
      if not WeakAurasOptions or not WeakAurasOptions:IsShown() then
        local lap = LAP:GetModule(moduleName)
        if not WeakAurasOptions then
          lap:openConfig()
        end
        if not WeakAurasOptions:IsShown() then
          WeakAurasOptions:Show()
        end
        LWF:StartSplitView(addon.frames.mainFrame, WeakAurasOptions, true, 20)
      else
        LWF:EndSplitView(WeakAurasOptions, addon.ResetFramePosition)
      end
    end
  )
  openWAButton:SetPoint("BOTTOMLEFT", m, "BOTTOMLEFT", 60, 20)

  return m
end

local function showManageFrame(anchor)
  if not m then
    m = createManageFrame(frameWidth, frameHeight)
  end
  wipe(scrollBoxData[1])
  wipe(scrollBoxData[2])
  clearWeakAuraCaches()
  for id, display in pairs(WeakAurasSaved.displays) do
    if display.wagoID and display.url and string.find(display.url, "wago.io") then
      table.insert(scrollBoxData[1], { info = display })
    end
  end
  local pack = addon:GetCurrentPackStashed()
  if pack.wagoWeakAuras then
    for weakAuraId, wagoSlug in pairs(pack.wagoWeakAuras) do
      local display = WeakAurasSaved.displays[weakAuraId]
      if display then
        local entry = {
          info = display,
        }
        table.insert(scrollBoxData[2], entry)
      else
        -- remove entry if the WA is no longer installed for the creator
        pack.wagoWeakAuras[weakAuraId] = nil
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

local onSuccessfulTestOverride = function(_, weakAuraTable)
  WeakAuras.Import(weakAuraTable)
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  hasGroups = true,
  manageFunc = showManageFrame,
  onSuccessfulTestOverride = onSuccessfulTestOverride
}

addon.ModuleFunctions.specialModules[moduleName] = moduleConfig
