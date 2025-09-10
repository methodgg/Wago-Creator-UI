---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local L = addon.L

local widths = {
  install = 50,
  addon = 450,
  profile = 100
}

function addon:CreateProfileSelectionList(parent, frameWidth, frameHeight, checkedCallback)
  local header
  local contentScrollbox

  local function createScrollLine(self, index)
    ---@class Line
    ---@diagnostic disable-next-line: assign-type-mismatch
    local line = CreateFrame("Button", nil, self)
    PixelUtil.SetPoint(line, "TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight + 1)) - 1)
    line:SetSize(frameWidth - 30, self.LineHeight)
    ---@diagnostic disable-next-line: undefined-field
    if not line.SetBackdrop then
      Mixin(line, BackdropTemplateMixin)
    end
    ---@diagnostic disable-next-line: undefined-field
    line:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true })
    ---@diagnostic disable-next-line: undefined-field
    line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }))
    DF:Mixin(line, DF.HeaderFunctions)

    local checkBox = LWF:CreateCheckbox(line, 40, nil, true)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(checkBox)
    line.checkBox = checkBox

    local nameLabel = DF:CreateLabel(line, "", 16, "white")
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(nameLabel)
    line.nameLabel = nameLabel

    local textEntry = LWF:CreateTextEntry(parent, 150, 20, function() end)
    textEntry:SetFrameLevel(150)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(textEntry)
    line.textEntry = textEntry

    local notInstalledLabel = DF:CreateLabel(line, "", 12, "white")
    notInstalledLabel:SetPoint("RIGHT", textEntry, "LEFT", -10, 0)
    line.notInstalledLabel = notInstalledLabel

    local importOverrideWarning = DF:CreateButton(line, nil, 30, 30, "", nil, nil,
      "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew", nil, nil, nil, nil
    )
    importOverrideWarning:SetPoint("LEFT", textEntry, "RIGHT", 4, 0)
    line.importOverrideWarning = importOverrideWarning

    ---@diagnostic disable-next-line: undefined-field
    line:AlignWithHeader(header, "LEFT")
    return line
  end

  local function contentScrollboxUpdate(self, data, offset, totalLines)
    for i = 1, totalLines do
      local index = i + offset
      local info = data[index]
      local line = self:GetLine(i)
      line.checkBox:Hide()
      line.nameLabel:SetText("")
      line.notInstalledLabel:SetText("")
      line.textEntry:Hide()
      line.importOverrideWarning:Hide()
      line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }))
      if (info) then
        ---@type LibAddonProfilesModule
        local lap = info.lap
        local loaded = lap:isLoaded()
        local updated = lap:isUpdated()
        local canEnable = LAP:CanEnableAnyAddOn(lap.addonNames)
        info.loaded = loaded
        local updateEnabledState = function()
          if updated and (loaded or canEnable) and info.enabled then
            line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }))
            line.nameLabel:SetTextColor(1, 1, 1, 1)
            if lap.willOverrideProfile then
              line.importOverrideWarning:Show()
              line.importOverrideWarning:SetTooltip(L["PROFILE_OVERWRITE_WARNING1"])
              line.importOverrideWarning:SetClickFunction(
                function()
                end
              )
            else
              line.importOverrideWarning:Hide()
            end
            line.textEntry.editbox:SetTextColor(1, 1, 1, 1)
          else
            line.textEntry.editbox:SetTextColor(0.4, 0.4, 0.4, 1)
            line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }))
            line.nameLabel:SetTextColor(0.5, 0.5, 0.5, 1)
            line.importOverrideWarning:Hide()
            line.textEntry:Disable()
          end
        end

        if updated and (loaded or canEnable) then
          line.checkBox:Show()
          line.checkBox:SetChecked(info.enabled)
          line.checkBox:SetSwitchFunction(
            function()
              info.enabled = not info.enabled
              local res = addon.db.selectedWagoDataResolution or addon.resolutions.defaultValue
              addon.db.introImportState[res][lap.moduleName].checked = info.enabled
              updateEnabledState()
              checkedCallback()
              contentScrollbox:Refresh()
            end
          )
        else
          line.checkBox:Hide()
        end

        line.notInstalledLabel:SetTextColor(0.5, 0.5, 0.5, 1)
        if loaded and updated then
          line.notInstalledLabel:SetText("")
        elseif (canEnable or loaded) and not updated then
          line.notInstalledLabel:SetText(L["Addon out of date - update required"])
        elseif canEnable and info.enabled then
          line.notInstalledLabel:SetText(L["AddOn will be enabled"])
          line.notInstalledLabel:SetTextColor(1, 1, 1, 1)
        elseif canEnable then
          line.notInstalledLabel:SetText(L["AddOn disabled"])
        else
          line.notInstalledLabel:SetText(L["AddOn not installed"])
        end

        -- need to test if the texture exists
        local texturePath = addon:TestTexture(lap.icon) and lap.icon or QUESTION_MARK_ICON
        local labelText = (loaded or canEnable) and "|T"..texturePath..":30|t" or ""
        labelText =
            labelText.." "..(info.entryName and info.moduleName..": "..info.entryName or info.moduleName)
        line.nameLabel:SetText(labelText)

        line.textEntry:SetText(info.profileKey)
        local res = addon.db.selectedWagoDataResolution or addon.resolutions.defaultValue
        addon.db.introImportState[res][lap.moduleName].checked = info.enabled
        if updated and (loaded or canEnable) then
          line.textEntry:Show()
          line.textEntry:Disable()
        else
          line.importOverrideWarning:Hide()
          line.textEntry:Hide()
        end

        updateEnabledState()
      end
    end
  end

  local totalHeaderWidth = 0
  for _, w in pairs(widths) do
    totalHeaderWidth = totalHeaderWidth + w
  end

  local headerTable = {
    { text = L["Install?"],                width = widths.install,                                     offset = 1 },
    { text = L["AddOn"],                   width = widths.addon },
    { text = L["Profile to be installed"], width = frameWidth - totalHeaderWidth + widths.profile - 35 }
  }
  local headerOptions = {
    text_size = 12
  }
  local lineHeight = 42
  contentScrollbox = DF:CreateScrollBox(parent, nil, contentScrollboxUpdate, {}, frameWidth - 30, frameHeight, 0,
    lineHeight, createScrollLine, true)
  ---@diagnostic disable-next-line: inject-field
  header = DF:CreateHeader(parent, headerTable, headerOptions, nil)
  contentScrollbox:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
  contentScrollbox.ScrollBar.scrollStep = 60
  DF:ReskinSlider(contentScrollbox)
  contentScrollbox.ScrollBar.ScrollUpButton.Highlight:ClearAllPoints(false)
  contentScrollbox.ScrollBar.ScrollDownButton.Highlight:ClearAllPoints(false)

  local function updateData(data)
    contentScrollbox:SetData(data or {})
    contentScrollbox:Refresh()
  end

  return { header = header, contentScrollbox = contentScrollbox, updateData = updateData }
end
