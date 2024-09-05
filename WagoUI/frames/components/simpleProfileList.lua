---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local L = addon.L

function addon:SimpleProfileList(parent, frameWidth, frameHeight)
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

    local nameLabel = DF:CreateLabel(line, "", 16, "white")
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(nameLabel)
    line.nameLabel = nameLabel

    local textEntry = LWF:CreateTextEntry(parent, 150, 20, function() end)
    textEntry:SetFrameLevel(150)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(textEntry)
    line.textEntry = textEntry

    ---@diagnostic disable-next-line: undefined-field
    line:AlignWithHeader(header, "LEFT")
    return line
  end

  local function contentScrollboxUpdate(self, data, offset, totalLines)
    for i = 1, totalLines do
      local index = i + offset
      local info = data[index]
      local line = self:GetLine(i)
      line.nameLabel:SetText("")
      line.textEntry:Hide()
      line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }))
      if (info) then
        local lap = LAP:GetModule(info.moduleName)

        local texturePath = addon:TestTexture(lap.icon) and lap.icon or QUESTION_MARK_ICON
        local labelText = "|T"..texturePath..":30|t"
        labelText = labelText.." "..info.moduleName
        line.nameLabel:SetText(labelText)

        line.textEntry:SetText(info.profileKey)
        line.textEntry:Show()
        line.textEntry:Disable()
        line.textEntry.editbox:SetTextColor(1, 1, 1, 1)
      end
    end
  end

  local headerTable = {
    { text = L["AddOn"],                   width = frameWidth / 2 },
    { text = L["Profile to be installed"], width = (frameWidth / 2) - 16 }
  }
  local headerOptions = {
    text_size = 12
  }
  local lineHeight = 42
  contentScrollbox = DF:CreateScrollBox(parent, nil, contentScrollboxUpdate, {}, frameWidth - 30, frameHeight, 0,
    lineHeight, createScrollLine, true
  )
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
