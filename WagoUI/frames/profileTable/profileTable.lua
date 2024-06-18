local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L

local widths = {
  options = 60,
  name = 350,
  profile = 200,
  -- version = 100,
  lastUpdate = 150,
}

function addon:CreateProfileTable(f)
  local profileFrame = CreateFrame("Frame", addonName.."ProfileFrame", f)
  profileFrame:SetAllPoints(f)
  profileFrame:Hide()
  addon.frames.profileFrame = profileFrame
  db = addon.db
  local frameWidth = profileFrame:GetWidth() - 0
  local frameHeight = profileFrame:GetHeight() - 40
  local initialXOffset = 2
  local initialYOffset = -30


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
    line:AlignWithHeader(profileFrame.contentHeader, "LEFT");
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
          profileFrame.contentScrollbox:Refresh()
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
            profileFrame.contentScrollbox:Refresh()
          end)
        else
          line.initializationWarning:Hide()
        end

        -- action button
        line.actionButton:UpdateAction(info)
      end
    end
  end



  local totalHeight = -initialYOffset
  local function addLine(widgets, xOffset, yOffset, xGap, yGap)
    xOffset = xOffset or 0
    yOffset = yOffset or 0
    xGap = xGap or 10
    yGap = yGap or 10
    local maxHeight = 0
    for i, widget in ipairs(widgets) do
      if i == 1 then
        widget:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", xOffset + initialXOffset, 0 - totalHeight + yOffset)
      else
        widget:SetPoint("LEFT", widgets[i - 1], "RIGHT", xGap + xOffset, 0)
      end
      maxHeight = math.max(maxHeight, widget:GetHeight())
    end
    totalHeight = totalHeight + maxHeight + yGap - yOffset
  end


  local wagoDataDropdownFunc = function() return addon:GetWagoDataForDropdown() end
  local wagoDataDropdown = addon.DF:CreateDropdown(profileFrame, 180, 40, 16, wagoDataDropdownFunc)
  if not db.selectedWagoData then
    wagoDataDropdown:NoOptionSelected()
  else
    wagoDataDropdown:Select(db.selectedWagoData)
  end

  local resolutionDropdownFunc = function() return addon:GetResolutionsForDropdown() end
  local resolutionDropdown = addon.DF:CreateDropdown(profileFrame, 180, 40, 16, resolutionDropdownFunc)
  if not db.selectedWagoDataResolution then
    resolutionDropdown:NoOptionSelected()
  else
    resolutionDropdown:Select(db.selectedWagoDataResolution)
  end

  function addon:RefreshResolutionDropdown()
    resolutionDropdown:Refresh()                             --update the dropdown options
    resolutionDropdown:Close()
    resolutionDropdown:Select(db.selectedWagoDataResolution) --selected profile could have been renamed, need to refresh like this
    local values = {}
    for _, v in pairs(resolutionDropdown.func()) do          --if the selected profile got deleted
      if v.value then values[v.value] = true end
    end
    if not db.selectedWagoDataResolution or not values[db.selectedWagoDataResolution] then
      resolutionDropdown:NoOptionSelected()
      db.selectedWagoDataResolution = nil
    end
  end

  local introButton = addon.DF:CreateButton(profileFrame, 100, 40, "Intro", 16)
  introButton:SetClickFunction(function()
    addon.frames.introFrame:Show()
    addon.frames.profileFrame:Hide()
    addon.db.introEnabled = true
  end);

  -- TODO: An update all button is not really possible
  -- some modules require user input to continue importing/updating (WA / EchoRT)

  -- local updateAllButton = DF:CreateButton(f, nil, 250, 40, L["Update All"], nil, nil, nil, nil, nil, nil,
  --   options_dropdown_template);
  -- updateAllButton.text_overlay:SetFont(updateAllButton.text_overlay:GetFont(), 16);
  -- updateAllButton:SetClickFunction(function()
  --   --TODO: Implement
  --   print("Updating All")
  -- end);
  -- f.updateAllButton = updateAllButton

  addLine({ wagoDataDropdown, resolutionDropdown, introButton --[[, updateAllButton ]] }, 0, 0)

  db.selectedWagoDataTab = db.selectedWagoDataTab or 1
  local profileTabButton = addon.DF:CreateTabButton(profileFrame, (frameWidth / 2) - 2, 40, "Profiles", 16)
  local weakaurasTabButton = addon.DF:CreateTabButton(profileFrame, (frameWidth / 2) - 2, 40, "Weakauras", 16)
  addLine({ profileTabButton, weakaurasTabButton }, 0, 0, 0, 0)

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
  local contentScrollbox = DF:CreateScrollBox(profileFrame, nil, contentScrollboxUpdate, {}, frameWidth - 30,
    frameHeight - totalHeight + 4, 0, lineHeight, createScrollLine, true);
  ---@diagnostic disable-next-line: inject-field
  profileFrame.contentHeader = DF:CreateHeader(profileFrame, headerTable, nil, addonName.."ContentHeader");
  ---@diagnostic disable-next-line: inject-field
  profileFrame.contentScrollbox = contentScrollbox
  contentScrollbox:SetPoint("TOPLEFT", profileFrame.contentHeader, "BOTTOMLEFT");
  contentScrollbox.ScrollBar.scrollStep = 60;
  DF:ReskinSlider(contentScrollbox);


  --TODO: chose resolution with wizard
  function addon:UpdateProfileTable(data)
    contentScrollbox:SetData(data or {})
    contentScrollbox:Refresh()
  end

  local tabFunction = function(tabIndex)
    db.selectedWagoDataTab = tabIndex
    if db.selectedWagoDataResolution and addon.wagoData then
      addon:UpdateProfileTable(addon.wagoData[db.selectedWagoDataResolution][db.selectedWagoDataTab])
    end
  end
  addon.DF:CreateTabStructure({ profileTabButton, weakaurasTabButton }, tabFunction, db.selectedWagoDataTab)

  addLine({ profileFrame.contentHeader }, 0, 0)

  addon.contentScrollbox = contentScrollbox
end
