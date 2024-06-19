local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

local widths = {
  install = 43,
  addon = 300,
  profile = 150,
}

function addon.DF:CreateProfileSelectionList(parent, frameWidth, frameHeight)
  local header
  local contentScrollbox

  local function createScrollLine(self, index)
    ---@class Line
    ---@diagnostic disable-next-line: assign-type-mismatch
    local line = CreateFrame("Button", nil, self);
    PixelUtil.SetPoint(line, "TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight + 1)) - 1);
    line:SetSize(frameWidth - 30, self.LineHeight);
    ---@diagnostic disable-next-line: undefined-field
    if not line.SetBackdrop then
      Mixin(line, BackdropTemplateMixin)
    end
    ---@diagnostic disable-next-line: undefined-field
    line:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true });
    ---@diagnostic disable-next-line: undefined-field
    line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }));
    DF:Mixin(line, DF.HeaderFunctions);

    local checkBox = addon.DF:CreateCheckbox(line, 40, nil, true)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(checkBox);
    line.checkBox = checkBox;

    local nameLabel = DF:CreateLabel(line, "", 16, "white");
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(nameLabel);
    line.nameLabel = nameLabel;

    local importOverrideWarning = DF:CreateButton(line, nil, 30, 30, "", nil, nil,
      "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew", nil, nil, nil, nil);
    importOverrideWarning:SetPoint("LEFT", line.nameLabel, "RIGHT", 0, 0)
    importOverrideWarning:SetTooltip(L["Importing this profile will overwrite your current profile for this AddOn."]);
    line.importOverrideWarning = importOverrideWarning

    local profileKeyLabel = DF:CreateLabel(line, "", 12, "white");
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(profileKeyLabel);
    line.profileKeyLabel = profileKeyLabel;

    ---@diagnostic disable-next-line: undefined-field
    line:AlignWithHeader(header, "LEFT");
    return line;
  end

  local function contentScrollboxUpdate(self, data, offset, totalLines)
    for i = 1, totalLines do
      local index = i + offset;
      local info = data[index];
      if (info) then
        ---@class LibAddonProfilesModule
        local lap = info.lap
        local line = self:GetLine(i);
        local loaded = lap.isLoaded() or lap.needsInitialization()
        if loaded then
          line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }));
        else
          line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }));
        end

        line.checkBox:SetChecked(info.enabled)
        line.checkBox:SetSwitchFunction(function()
          info.enabled = not info.enabled
        end)

        -- need to test if the texture exists
        local texturePath = addon:TestTexture(lap.icon) and lap.icon or QUESTION_MARK_ICON
        local labelText = "|T"..texturePath..":30|t"
        labelText = labelText.." "..(info.entryName and info.moduleName..": "..info.entryName or info.moduleName)
        line.nameLabel:SetText(labelText);
        if not loaded then
          line.nameLabel:SetTextColor(0.5, 0.5, 0.5, 1);
        else
          line.nameLabel:SetTextColor(1, 1, 1, 1);
        end

        --TODO: we will need to check aswell if the profile is already installed via lap.isDuplicate
        --also offer to rename the new profile if it is a duplicate
        if lap.willOverrideProfile then
          line.importOverrideWarning:Show()
        else
          line.importOverrideWarning:Hide()
        end

        line.profileKeyLabel:SetText(info.profileKey)
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
    { text = L["Profile to be installed"], width = frameWidth - totalHeaderWidth + widths.profile - 35 },
  };
  local headerOptions = {
    text_size = 12
  }
  local lineHeight = 42
  contentScrollbox = DF:CreateScrollBox(parent, nil, contentScrollboxUpdate, {}, frameWidth - 30, frameHeight, 0,
    lineHeight, createScrollLine, true);
  ---@diagnostic disable-next-line: inject-field
  header = DF:CreateHeader(parent, headerTable, headerOptions, nil);
  contentScrollbox:SetPoint("TOPLEFT", header, "BOTTOMLEFT");
  contentScrollbox.ScrollBar.scrollStep = 60;
  DF:ReskinSlider(contentScrollbox);

  local function updateData(data)
    contentScrollbox:SetData(data or {})
    contentScrollbox:Refresh()
  end

  return { header = header, contentScrollbox = contentScrollbox, updateData = updateData }
end
