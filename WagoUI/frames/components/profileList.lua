local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

local widths = {
  options = 60,
  name = 350,
  profile = 200,
  -- version = 100,
  lastUpdate = 150,
}

function addon.DF:CreateProfileList(parent, frameWidth, frameHeight)
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

    -- icon
    local icon = DF:CreateButton(line, nil, 42, 42, "", nil, nil, QUESTION_MARK_ICON, nil, nil, nil, nil);
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(icon);
    line.icon = icon;

    -- name
    local nameLabel = DF:CreateLabel(line, "", 16, "white");
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(nameLabel);
    nameLabel:SetWidth(widths.name)
    line.nameLabel = nameLabel;

    -- action button
    line.actionButton = addon:CreateActionButton(line)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(line.actionButton);

    local initializationWarning = DF:CreateButton(line, nil, 30, 30, "", nil, nil,
      "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew", nil, nil, nil, nil);
    initializationWarning:SetPoint("RIGHT", line.actionButton, "LEFT", -2, -2)
    initializationWarning:SetTooltip(L["This AddOn needs to be initialized. Click to initialize."]);
    line.initializationWarning = initializationWarning

    -- last update
    local lastUpdateLabel = DF:CreateLabel(line, "", 10, "white");
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(lastUpdateLabel);
    line.lastUpdateLabel = lastUpdateLabel;

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
        local loaded = lap.isLoaded()
        if loaded then
          line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }));
        else
          line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }));
        end

        -- icon
        -- need to test if the texture exists
        local tex = addon:TestTexture(lap.icon) and lap.icon or QUESTION_MARK_ICON
        line.icon:SetTexture(tex);
        line.icon:SetPushedTexture(tex);
        line.icon:SetDisabledTexture(tex);
        line.icon:SetHighlightAtlas(lap.openConfig and "bags-glow-white" or "");
        line.icon:SetTooltip(lap.openConfig and string.format(L["Click to open %s options"], info.moduleName) or nil);
        line.icon:SetScript("OnClick", function()
          lap.openConfig()
          contentScrollbox:Refresh()
        end)
        if loaded or lap.needsInitialization() then
          line.icon:SetEnabled(true);
        else
          line.icon:SetEnabled(false);
        end

        -- name
        line.nameLabel:SetText((info.entryName and info.moduleName..": "..info.entryName) or info.moduleName);
        if not loaded then
          line.nameLabel:SetTextColor(0.5, 0.5, 0.5, 1);
        else
          line.nameLabel:SetTextColor(1, 1, 1, 1);
        end
        if lap.needsInitialization() then
          line.initializationWarning:Show()
          line.initializationWarning:SetScript("OnClick", function()
            lap.openConfig()
            C_Timer.After(0, function()
              lap.closeConfig()
            end)
            contentScrollbox:Refresh()
          end)
        else
          line.initializationWarning:Hide()
        end

        -- action button
        line.actionButton:UpdateAction(info)
      end
    end
  end

  local totalHeaderWidth = 0
  for _, w in pairs(widths) do
    totalHeaderWidth = totalHeaderWidth + w
  end

  local headerTable = {
    { text = L["Options"],     width = widths.options,                                        offset = 1 },
    { text = L["Name"],        width = widths.name },
    { text = L["Action"],      width = widths.profile },
    -- { text = "Version",           width = widths.version },
    { text = L["Last Update"], width = frameWidth - totalHeaderWidth + widths.lastUpdate - 35 },
  };
  local lineHeight = 42
  contentScrollbox = DF:CreateScrollBox(parent, nil, contentScrollboxUpdate, {}, frameWidth - 30, frameHeight, 0,
    lineHeight, createScrollLine, true);
  ---@diagnostic disable-next-line: inject-field
  header = DF:CreateHeader(parent, headerTable, nil, nil);
  contentScrollbox:SetPoint("TOPLEFT", header, "BOTTOMLEFT");
  contentScrollbox.ScrollBar.scrollStep = 60;
  DF:ReskinSlider(contentScrollbox);

  --TODO: chose resolution with wizard
  local function updateData(data)
    contentScrollbox:SetData(data or {})
    contentScrollbox:Refresh()
  end

  return { header = header, contentScrollbox = contentScrollbox, updateData = updateData }
end
