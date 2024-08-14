---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"];
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local widths = {
  install = 50,
  addon = 400,
  profile = 150,
}

---@param profileKey string
---@param lap LibAddonProfilesModule
---@return string newProfileKey
local findApproriateProfileKey = function(profileKey, lap)
  if profileKey == "Global" then return profileKey end
  local newProfileKey = profileKey
  local i = 1
  while lap:isDuplicate(newProfileKey) do
    newProfileKey = profileKey.."_"..i
    i = i + 1
  end
  return newProfileKey
end

function addon:CreateProfileSelectionList(parent, frameWidth, frameHeight, enabledStateCallback)
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

    local checkBox = LWF:CreateCheckbox(line, 40, nil, true)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(checkBox);
    line.checkBox = checkBox;

    local nameLabel = DF:CreateLabel(line, "", 16, "white");
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(nameLabel);
    line.nameLabel = nameLabel;

    local textEntry = LWF:CreateTextEntry(parent, 150, 20, function() end)
    textEntry:SetFrameLevel(150)
    ---@diagnostic disable-next-line: undefined-field
    line:AddFrameToHeaderAlignment(textEntry);
    line.textEntry = textEntry;

    local fallbackLabel = DF:CreateLabel(line, L["Addon not loaded"], 13, { .8, .8, .8, 0.3 });
    fallbackLabel:SetWidth(widths.install)
    fallbackLabel:SetPoint("LEFT", textEntry, "LEFT", 0, 0)
    fallbackLabel:SetPoint("RIGHT", textEntry, "RIGHT", 0, 0)
    line.fallbackLabel = fallbackLabel;

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
      local line = self:GetLine(i);
      line.checkBox:Hide()
      line.nameLabel:SetText("");
      line.textEntry:Hide()
      line.fallbackLabel:Hide()
      line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }));
      if (info) then
        ---@type LibAddonProfilesModule
        local lap = info.lap
        if lap:needsInitialization() then
          lap:openConfig()
          C_Timer.After(0, function()
            lap:closeConfig()
            addon:UpdateRegisteredDataConsumers()
          end)
        end
        local loaded = lap:isLoaded()
        info.loaded = loaded
        local updateEnabledState = function()
          if loaded and info.enabled then
            line:SetBackdropColor(unpack({ .8, .8, .8, 0.3 }));
            line.nameLabel:SetTextColor(1, 1, 1, 1);
            if lap.willOverrideProfile then
              line.importOverrideWarning:Show()
              line.importOverrideWarning:SetTooltip(L["PROFILE_OVERWRITE_WARNING1"]);
              line.importOverrideWarning:SetClickFunction(function() end)
            else
              line.importOverrideWarning:Hide()
            end
            line.textEntry.editbox:SetTextColor(1, 1, 1, 1)
          else
            line.textEntry.editbox:SetTextColor(0.4, 0.4, 0.4, 1)
            line:SetBackdropColor(unpack({ .8, .8, .8, 0.1 }));
            line.nameLabel:SetTextColor(0.5, 0.5, 0.5, 1);
            line.importOverrideWarning:Hide()
            line.textEntry:Disable()
          end
        end

        if loaded then
          line.checkBox:Show()
          line.checkBox:SetChecked(info.enabled)
          line.checkBox:SetSwitchFunction(function()
            info.enabled = not info.enabled
            enabledStateCallback()
            updateEnabledState()
          end)
        else
          line.checkBox:Hide()
        end

        -- need to test if the texture exists
        local texturePath = addon:TestTexture(lap.icon) and lap.icon or QUESTION_MARK_ICON
        local labelText = loaded and "|T"..texturePath..":30|t" or ""
        labelText = labelText.." "..(info.entryName and info.moduleName..": "..info.entryName or info.moduleName)
        line.nameLabel:SetText(labelText);

        if lap:isLoaded() and not lap.willOverrideProfile then
          info.profileKey = findApproriateProfileKey(info.profileKey, lap)
        end
        line.textEntry:SetText(info.profileKey)
        if loaded then
          line.textEntry:Show()
          line.textEntry:Disable()
          line.fallbackLabel:Hide()
        else
          line.importOverrideWarning:Hide()
          line.textEntry:Hide()
          line.fallbackLabel:Show()
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
