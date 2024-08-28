---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local db
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

local widths = {
  options = 60,
  name = 260,
  action = 180,
  profile = 120,
  lastUpdate = 120
}

function addon:CreateProfileList(parent, frameWidth, frameHeight)
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
    line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
    ---@diagnostic disable-next-line: undefined-field
    line:SetBackdropColor(unpack({.8, .8, .8, 0.3}))
    DF:Mixin(line, DF.HeaderFunctions)

    -- icon
    local icon = DF:CreateButton(line, nil, 42, 42, "", nil, nil, QUESTION_MARK_ICON, nil, nil, nil, nil)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(icon)
    line.icon = icon

    -- name
    local nameLabel = DF:CreateLabel(line, "", 16, "white")
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(nameLabel)
    nameLabel:SetWidth(widths.name)
    line.nameLabel = nameLabel

    -- action button
    line.actionButton = addon:CreateActionButton(line, widths.action - 10, 30, 16)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(line.actionButton)

    -- profile key
    local profileKeyLabel = DF:CreateLabel(line, "Test", 12, "white")
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(profileKeyLabel)
    profileKeyLabel:SetWidth(widths.profile)
    line.profileKeyLabel = profileKeyLabel

    -- last update
    local lastUpdateLabel = DF:CreateLabel(line, "", 14, "white")
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(lastUpdateLabel)
    line.lastUpdateLabel = lastUpdateLabel

    ---@diagnostic disable-next-line: undefined-field
    line:AlignWithHeader(header, "LEFT")
    return line
  end

  local function contentScrollboxUpdate(self, data, offset, totalLines)
    for i = 1, totalLines do
      local index = i + offset
      local info = data[index]
      if (info) then
        ---@type LibAddonProfilesModule
        local lap = info.lap
        local line = self:GetLine(i)
        local loaded = lap:isLoaded() and lap:isUpdated()
        if loaded then
          line:SetBackdropColor(unpack({.8, .8, .8, 0.3}))
        else
          line:SetBackdropColor(unpack({.8, .8, .8, 0.1}))
        end

        -- icon
        -- need to test if the texture exists
        local tex = addon:TestTexture(lap.icon) and lap.icon or QUESTION_MARK_ICON
        line.icon:SetTexture(tex)
        line.icon:SetPushedTexture(tex)
        line.icon:SetDisabledTexture(tex)
        line.icon:SetHighlightAtlas(lap.openConfig and "bags-glow-white" or "")
        line.icon:SetTooltip(lap.openConfig and string.format(L["Click to open %s options"], info.moduleName) or nil)
        line.icon:SetScript(
          "OnClick",
          function()
            lap:openConfig()
            contentScrollbox:Refresh()
          end
        )
        if loaded then
          line.icon:SetEnabled(true)
        else
          line.icon:SetEnabled(false)
        end

        -- name
        line.nameLabel:SetText(info.entryName or info.moduleName)
        if not loaded then
          line.nameLabel:SetTextColor(0.5, 0.5, 0.5, 1)
          line.profileKeyLabel:SetTextColor(0.5, 0.5, 0.5, 1)
          line.lastUpdateLabel:SetTextColor(0.5, 0.5, 0.5, 1)
        else
          line.nameLabel:SetTextColor(1, 1, 1, 1)
          line.profileKeyLabel:SetTextColor(1, 1, 1, 1)
          line.lastUpdateLabel:SetTextColor(1, 1, 1, 1)
        end

        local importedLastUpdatedAt, importedProfileKey = addon:GetImportedProfileData(info.moduleName, info.entryName)
        local profileKey = importedProfileKey or info.profileKey
        -- profile key
        line.profileKeyLabel:SetText(info.entryName and "" or profileKey)

        -- last update
        local latestVersion
        if info.entryName then
          latestVersion = info.profileMetadata.lastUpdatedAt[info.entryName]
        else
          latestVersion = info.profileMetadata.lastUpdatedAt
        end
        line.lastUpdateLabel:SetText(date("%b %d %H:%M", latestVersion))

        -- action button
        local updateAvailable = latestVersion > (importedLastUpdatedAt or 0)
        line.actionButton:UpdateAction(info, updateAvailable, importedLastUpdatedAt, profileKey, latestVersion)
      end
    end
  end

  local totalHeaderWidth = 0
  for _, w in pairs(widths) do
    totalHeaderWidth = totalHeaderWidth + w
  end

  local headerTable = {
    {text = L["Options"], width = widths.options, offset = 1},
    {text = L["Name"], width = widths.name},
    {text = L["Action"], width = widths.action},
    {text = L["Profile"], width = widths.profile},
    {text = L["Latest Version"], width = frameWidth - totalHeaderWidth + widths.lastUpdate - 35}
  }
  local headerOptions = {
    text_size = 12
  }
  local lineHeight = 42
  contentScrollbox =
    DF:CreateScrollBox(
    parent,
    nil,
    contentScrollboxUpdate,
    {},
    frameWidth - 30,
    frameHeight,
    0,
    lineHeight,
    createScrollLine,
    true
  )
  ---@diagnostic disable-next-line: inject-field
  header = DF:CreateHeader(parent, headerTable, headerOptions, nil)
  contentScrollbox:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
  contentScrollbox.ScrollBar.scrollStep = 60
  DF:ReskinSlider(contentScrollbox)
  contentScrollbox.ScrollBar.ScrollUpButton.Highlight:ClearAllPoints(false)
  contentScrollbox.ScrollBar.ScrollDownButton.Highlight:ClearAllPoints(false)

  --TODO: chose resolution with wizard
  local function updateData(data)
    contentScrollbox:SetData(data or {})
    contentScrollbox:Refresh()
  end

  return {header = header, contentScrollbox = contentScrollbox, updateData = updateData}
end
