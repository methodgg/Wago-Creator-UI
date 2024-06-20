local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

local widths = {
  install = 43,
  addon = 400,
  profile = 150,
}

function addon.DF:CreateProfileSelectionList(parent, frameWidth, frameHeight, enabledStateCallback)
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

    local textEntry = addon.DF:CreateTextEntry(parent, 150, 20, function() end)
    textEntry:SetFrameLevel(150)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(textEntry);
    line.textEntry = textEntry;

    local importOverrideWarning = DF:CreateButton(line, nil, 30, 30, "", nil, nil,
      "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew", nil, nil, nil, nil);
    importOverrideWarning:SetPoint("LEFT", textEntry, "RIGHT", 4, 0)
    line.importOverrideWarning = importOverrideWarning

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
        local updateEnabledState = function()
          if loaded and info.enabled then
            line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }));
            line.nameLabel:SetTextColor(1, 1, 1, 1);
            line.importOverrideWarning:Enable()
            if not info.lap.willOverrideProfile then
              line.textEntry:Enable()
            end
          else
            line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }));
            line.nameLabel:SetTextColor(0.5, 0.5, 0.5, 1);
            line.importOverrideWarning:Disable()
            line.textEntry:Disable()
          end
        end
        updateEnabledState()

        line.checkBox:SetChecked(info.enabled)
        line.checkBox:SetSwitchFunction(function()
          info.enabled = not info.enabled
          enabledStateCallback()
          updateEnabledState()
        end)

        -- need to test if the texture exists
        local texturePath = addon:TestTexture(lap.icon) and lap.icon or QUESTION_MARK_ICON
        local labelText = "|T"..texturePath..":30|t"
        labelText = labelText.." "..(info.entryName and info.moduleName..": "..info.entryName or info.moduleName)
        line.nameLabel:SetText(labelText);

        if lap.willOverrideProfile then
          line.importOverrideWarning:SetTooltip(L["PROFILE_OVERWRITE_WARNING1"]);
          line.importOverrideWarning:SetClickFunction(function() end)
          line.importOverrideWarning:Show()
        else
          line.importOverrideWarning:Hide()
        end

        line.textEntry:SetText(info.profileKey)
        if info.lap.willOverrideProfile then
          line.textEntry:Disable()
        else
          if info.enabled then
            line.textEntry:Enable()
          end
        end
        line.textEntry.func = function()
          local newText = line.textEntry:GetText()
          if info.lap.isDuplicate(newText) and not info.lap.willOverrideProfile then
            if info.enabled then
              line.textEntry.editbox:SetTextColor(1, 0, 0, 1)
            end
            line.importOverrideWarning:Show()
            line.importOverrideWarning:SetTooltip(L["PROFILE_OVERWRITE_WARNING2"]);
            line.importOverrideWarning:SetClickFunction(function()
              line.textEntry.editbox:SetFocus()
              line.textEntry.editbox:HighlightText()
            end)
            info.invalidProfileKey = true
            enabledStateCallback()
          else
            if info.enabled then
              line.textEntry.editbox:SetTextColor(1, 1, 1, 1)
            end
            if not lap.willOverrideProfile then
              line.importOverrideWarning:Hide()
            end
            info.invalidProfileKey = nil
            enabledStateCallback()
          end
          info.profileKey = newText
        end
        line.textEntry.editbox:SetScript("OnTextChanged", function(...)
          local newText = line.textEntry:GetText()
          if not newText or newText == "" then
            return
          end
          line.textEntry.func()
        end)
        line.textEntry.editbox:SetScript("OnEditFocusLost", function(...)
          local newText = line.textEntry:GetText()
          if not newText or newText == "" then
            line.textEntry:SetText(info.profileKey)
          end
        end)

        line.textEntry.func()
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
