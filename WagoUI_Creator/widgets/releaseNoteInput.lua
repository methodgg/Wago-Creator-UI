---@type string
local addonName = ...
---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

local releaseNotesFrame
local frameWidth = 600
local frameHeight = 520
local scrollFrameHeight = 225

function addon:CreateReleaseNoteInput()
  releaseNotesFrame = addon:CreateGenericTextFrame(frameWidth, frameHeight, "Release Notes", true)
  releaseNotesFrame:SetFrameLevel(105)
  releaseNotesFrame.Close:SetScript(
    "OnClick",
    function()
      releaseNotesFrame:Hide()
    end
  )
  local editbox = releaseNotesFrame.editbox
  editbox:SetAutoFocus(false)
  editbox:SetScript(
    "OnKeyUp",
    function(_, key)
      if key == "ESCAPE" then
        releaseNotesFrame:Hide()
      end
    end
  )
  addon.exportFrame = releaseNotesFrame
  editbox:SetFontObject(GameFontNormalLarge)
  releaseNotesFrame.scrollframe:SetPoint(
    "BOTTOMRIGHT",
    releaseNotesFrame,
    "BOTTOMRIGHT",
    -23,
    frameHeight - scrollFrameHeight
  )

  local explainerLabel = DF:CreateLabel(releaseNotesFrame, L["autoReleaseNotesExplanation"], 12, "#d0d2d6")
  explainerLabel:SetPoint("TOPLEFT", releaseNotesFrame.scrollframe, "BOTTOMLEFT", 4, -10)

  local logo = DF:CreateImage(releaseNotesFrame, [[Interface\AddOns\]] .. addonName .. [[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", releaseNotesFrame.scrollframe, "BOTTOM", 0, 10)
  releaseNotesFrame.logo = logo

  local nextStepLabel =
    DF:CreateLabel(releaseNotesFrame, L["Continue the upload through the Wago App after the reload!"], 14, "white")
  nextStepLabel:SetPoint("BOTTOM", logo, "BOTTOM", 0, 30)
  local warningIconLeft = LWF:CreateIconButton(releaseNotesFrame, 30, "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  local warningIconRight =
    LWF:CreateIconButton(releaseNotesFrame, 30, "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  warningIconLeft:SetPoint("RIGHT", nextStepLabel, "LEFT", -5, 0)
  warningIconRight:SetPoint("LEFT", nextStepLabel, "RIGHT", 5, 0)
  releaseNotesFrame.nextStepLabel = nextStepLabel

  local reloadButton = LWF:CreateButton(releaseNotesFrame, 200, 40, L["Save and Reload"], 16)
  reloadButton:SetClickFunction(
    function()
      local input = editbox:GetText()
      addon:SaveReleaseNotes(input)
      ReloadUI()
    end
  )
  reloadButton:SetBackdropColor(0, 0.8, 0, 1)
  reloadButton:SetScript(
    "OnEnter",
    function(self)
      reloadButton.button:SetBackdropBorderColor(1, 1, 1, 1)
    end
  )
  reloadButton:SetScript(
    "OnLeave",
    function(self)
      reloadButton.button:SetBackdropBorderColor(1, 1, 1, 0)
    end
  )
  reloadButton:SetPoint("TOP", nextStepLabel, "BOTTOM", 0, -15)
  releaseNotesFrame.reloadButton = reloadButton

  releaseNotesFrame:HookScript(
    "OnHide",
    function()
      LWF:ToggleLockoutFrame(false, addon.frames, addon.frames.mainFrame)
    end
  )
end

---@param resolution string
---@param type  "displayNameLong" | "displayNameShort"
---@return string
function addon:GetResolutionString(resolution, type)
  for _, entry in ipairs(addon.resolutions.entries) do
    if entry.value == resolution then
      --- @as string
      return entry[type]
    end
  end
  return ""
end

function addon:AddProfileRemoval(packName, resolution, moduleName)
  local data = {
    packName = packName,
    resolution = resolution,
    moduleName = moduleName
  }
  tinsert(addon.db.profileRemovals, data)
end

local function getAndClearCurrentProfileRemovals(resolution)
  local removeString
  for i = #addon.db.profileRemovals, 1, -1 do
    local data = addon.db.profileRemovals[i]
    if data.packName == addon.db.chosenPack and data.resolution == resolution then
      removeString = removeString or ""
      removeString = removeString .. "- " .. data.moduleName .. "\n"
      table.remove(addon.db.profileRemovals, i)
    end
  end
  return removeString
end

function addon:CountRemovedProfiles(packName)
  local count = 0
  for i = #addon.db.profileRemovals, 1, -1 do
    if addon.db.profileRemovals[i].packName == packName then
      count = count + 1
    end
  end
  return count
end

local function getUpdateString(updates)
  local res
  for resolution, data in pairs(updates) do
    local str
    for key, entry in pairs(data) do
      if type(entry) == "boolean" then
        str = str or ("### " .. addon:GetResolutionString(resolution, "displayNameShort") .. "\n")
        str = str .. "- " .. key .. "\n"
      elseif type(entry) == "table" then
        for k in pairs(entry) do
          str = str or ("### " .. addon:GetResolutionString(resolution, "displayNameShort") .. "\n")
          str = str .. "- " .. key .. ": " .. k .. "\n"
        end
      end
    end
    if str then
      res = res or ""
      res = res .. str
    end
  end
  return res
end

local function getRemovalString(removals)
  local res
  for resolution, data in pairs(removals) do
    local str
    for module, v in pairs(data) do
      for entry in pairs(v) do
        str = str or ("### " .. addon:GetResolutionString(resolution, "displayNameShort") .. "\n")
        str = str .. "- " .. module .. ": " .. entry .. "\n"
      end
    end
    local removedProfiles = getAndClearCurrentProfileRemovals(resolution)
    if removedProfiles then
      str = str or ("### " .. addon:GetResolutionString(resolution, "displayNameShort") .. "\n")
      str = str .. removedProfiles
    end
    if str then
      res = res or ""
      res = res .. str
    end
  end
  return res
end

function addon:OpenReleaseNoteInput(timestamp, updates, removals)
  if not releaseNotesFrame then
    addon:CreateReleaseNoteInput()
  end
  releaseNotesFrame.timestamp = timestamp
  addon.copyHelper:Hide()
  local str

  local updateString = getUpdateString(updates)
  if updateString then
    str = "## " .. L["Updated / Added"] .. ":\n" .. updateString
  end

  local removalString = getRemovalString(removals)
  if removalString then
    str = str or ""
    str = str .. "## " .. L["Removed"] .. ":\n" .. removalString
  end

  local dateString = "# " .. date("%y/%m/%d", timestamp) .. "\n"
  str = dateString .. str
  if addon.importFrame then
    addon.importFrame.Close:Click()
  end
  releaseNotesFrame:SetPoint("CENTER", addon.frames.mainFrame, "CENTER")
  releaseNotesFrame:Show()
  releaseNotesFrame.editbox:SetText(str)
  addon:SaveReleaseNotes(str)
end

function addon:SaveReleaseNotes(input)
  addon:GetCurrentPack().releaseNotes[releaseNotesFrame.timestamp] = input
end
