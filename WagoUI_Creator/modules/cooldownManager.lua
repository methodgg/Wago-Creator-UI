---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local moduleName = "Blizzard Cooldown Manager"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")


local m
local frameWidth = 750
local frameHeight = 600
local scrollBoxWidth = 250
local scrollBoxHeight = frameHeight - 380
local lineHeight = 30
local scrollBoxData = {
  [1] = {},
  [2] = {}
}


local isClassAndSpecTagSameClass = function(tagA, tagB)
  if not tagA or not tagB then
    return false
  end
  local classA = math.floor(tagA / 10)
  local classB = math.floor(tagB / 10)
  return classA == classB
end

local function getCurrentCharacterInfo()
  local characterName = UnitName("player")
  local realmName = GetRealmName()
  local characterKey = characterName.."-"..realmName
  return characterKey, characterName, realmName
end

local function ensureCooldownManagerLoaded()
  if CooldownViewerSettings and CooldownViewerUtil then
    return true
  end
  if C_AddOns and C_AddOns.LoadAddOn then
    pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
  end
  if UIParentLoadAddOn and not (CooldownViewerSettings and CooldownViewerUtil) then
    pcall(UIParentLoadAddOn, "Blizzard_CooldownViewer")
  end
  return CooldownViewerSettings and CooldownViewerUtil
end

local function getProfileCache()
  addon.db.cdmProfileCache = addon.db.cdmProfileCache or {}
  addon.db.cdmProfileCache.version = 1
  addon.db.cdmProfileCache.characters = addon.db.cdmProfileCache.characters or {}
  return addon.db.cdmProfileCache
end

local function getCdmBucket(parent, classAndSpecTag)
  if not parent then
    return
  end
  return parent[classAndSpecTag] or parent[tonumber(classAndSpecTag)] or parent[tostring(classAndSpecTag)]
end

local function getCdmClassKey(classAndSpecTag)
  return tonumber(classAndSpecTag) or classAndSpecTag
end

local function makeProfileMetaData(profileKey, timestamp)
  return {
    lastUpdatedAt = {
      [profileKey] = timestamp
    }
  }
end

local function getCachedProfileForInfo(info)
  local cache = addon.db and addon.db.cdmProfileCache
  if not cache or not cache.characters then
    return
  end

  local classAndSpecTag = tonumber(info.classAndSpecTag)
  if info.characterKey then
    local characterCache = cache.characters[info.characterKey]
    local profileCache = characterCache and characterCache.profiles and characterCache.profiles[info.profileKey]
    if profileCache and (not classAndSpecTag or tonumber(profileCache.classAndSpecTag) == classAndSpecTag) then
      return profileCache, characterCache
    end
  end

  local newestProfile, newestCharacter
  local newestTimestamp = 0
  for _, characterCache in pairs(cache.characters) do
    local profileCache = characterCache.profiles and characterCache.profiles[info.profileKey]
    if profileCache and (not classAndSpecTag or tonumber(profileCache.classAndSpecTag) == classAndSpecTag) then
      local updatedAt = profileCache.updatedAt or characterCache.updatedAt or 0
      if updatedAt > newestTimestamp then
        newestTimestamp = updatedAt
        newestProfile = profileCache
        newestCharacter = characterCache
      end
    end
  end
  return newestProfile, newestCharacter
end

local function removeSelectedProfile(pack, info)
  local classKey = getCdmClassKey(info.classAndSpecTag)
  local profileKey = info.profileKey
  local profileKeys = pack.cdmData and pack.cdmData.profileKeys
  local selectedProfiles = getCdmBucket(profileKeys, classKey)
  if selectedProfiles then
    selectedProfiles[profileKey] = nil
  end

  local profileStrings = getCdmBucket(pack.cdmData and pack.cdmData.profiles, classKey)
  if profileStrings then
    profileStrings[profileKey] = nil
  end
end

local function countCdmProfileStrings(pack)
  local numCdmProfiles = 0
  if pack.cdmData and pack.cdmData.profiles then
    for _, profileStrings in pairs(pack.cdmData.profiles) do
      for _, _ in pairs(profileStrings) do
        numCdmProfiles = numCdmProfiles + 1
      end
    end
  end
  return numCdmProfiles
end


-- CDM uses a custom export path because selected profiles can come from the
-- current character or the account-wide logout cache instead of normal profile dropdowns.
function addon:UpdateCooldownManagerData(timestamp, silent)
  if not ensureCooldownManagerLoaded() then
    if not silent then addon.copyHelper:SmartFadeOut(4, L["CDM_CACHE_UNAVAILABLE"]) end
    return false
  end

  local pack = addon:GetCurrentPackStashed()
  local oldPack = addon.db.creatorUI[addon.db.chosenPack] or {}
  local currentClassAndSpecTag = CooldownViewerUtil.GetCurrentClassAndSpecTag()
  local currentCharacterKey, currentCharacterName, currentRealmName = getCurrentCharacterInfo()
  local added = {}
  local removed = {}
  if not pack.cdmData then
    if not silent then addon.copyHelper:SmartFadeOut(2, L["No profiles to export!"]) end
    return false
  end
  pack.cdmData.profileKeys = pack.cdmData.profileKeys or {}
  ---@type LibAddonProfilesModule
  local lapModule = LAP:GetModule("Blizzard Cooldown Manager")

  --need to hide the config window to save any unsaved changes
  lapModule:closeConfig()
  addon:CacheCooldownManagerProfilesOnLogout()

  local profilesToExport = {}
  local actualProfilesOfCurrentCharacter = lapModule.getProfileKeys and lapModule:getProfileKeys() or {}

  for _, profiles in pairs(pack.cdmData.profileKeys) do
    for _, profile in pairs(profiles) do
      tinsert(profilesToExport, profile)
    end
  end

  --check for removed profiles that are no longer marked for export
  if pack.cdmData.profiles then
    for classAndSpecTag, profiles in pairs(pack.cdmData.profiles) do
      for profileKey, _ in pairs(profiles) do
        local selectedProfiles = getCdmBucket(pack.cdmData.profileKeys, classAndSpecTag)
        if not selectedProfiles or not selectedProfiles[profileKey] then
          profiles[profileKey] = nil
          tinsert(removed, profileKey)
        end
      end
    end
  end

  if not next(profilesToExport) and #removed == 0 then
    if not silent then addon.copyHelper:SmartFadeOut(2, L["No profiles to export!"]) end
    return false
  end

  timestamp = timestamp or GetServerTime()
  for _, profileInfo in pairs(profilesToExport) do
    local classAndSpecTag = tonumber(profileInfo.classAndSpecTag)
    local actualProfile = actualProfilesOfCurrentCharacter[profileInfo.profileKey]
    local actualProfileClassAndSpecTag = actualProfile and tonumber(actualProfile.classAndSpecTag)
    local canExportCurrentCharacterProfile = actualProfileClassAndSpecTag and
        isClassAndSpecTagSameClass(classAndSpecTag, currentClassAndSpecTag) and
        isClassAndSpecTagSameClass(classAndSpecTag, actualProfileClassAndSpecTag) and
        (not profileInfo.characterKey or profileInfo.characterKey == currentCharacterKey)

    local newExport, updatedAt, sourceCharacterKey, sourceCharacterName, sourceRealmName
    if canExportCurrentCharacterProfile then
      newExport = lapModule:exportProfile(profileInfo.profileKey)
      updatedAt = timestamp
      sourceCharacterKey = currentCharacterKey
      sourceCharacterName = currentCharacterName
      sourceRealmName = currentRealmName
    else
      local cachedProfile, characterCache = getCachedProfileForInfo(profileInfo)
      if cachedProfile then
        newExport = cachedProfile.exportString
        updatedAt = cachedProfile.updatedAt or characterCache.updatedAt or timestamp
        sourceCharacterKey = characterCache.characterKey
        sourceCharacterName = characterCache.characterName
        sourceRealmName = characterCache.realmName
      end
    end

    if not newExport then
      removeSelectedProfile(pack, profileInfo)
      tinsert(removed, profileInfo.profileKey)
    else
      local classKey = getCdmClassKey(profileInfo.classAndSpecTag)
      local oldProfileStrings = getCdmBucket(oldPack.cdmData and oldPack.cdmData.profiles, classKey)
      ---@type any
      local oldExport = oldProfileStrings and oldProfileStrings[profileInfo.profileKey]
      if not lapModule:areProfileStringsEqual(newExport, oldExport) then
        pack.cdmData.profiles = pack.cdmData.profiles or {}
        pack.cdmData.profiles[classKey] = pack.cdmData.profiles[classKey] or {}
        pack.cdmData.profiles[classKey][profileInfo.profileKey] = newExport

        pack.cdmData.profileKeys[classKey] = pack.cdmData.profileKeys[classKey] or {}
        pack.cdmData.profileKeys[classKey][profileInfo.profileKey] = {
          profileKey = profileInfo.profileKey,
          icon = profileInfo.icon,
          coloredName = profileInfo.coloredName,
          classAndSpecTag = classKey,
          characterKey = sourceCharacterKey or profileInfo.characterKey,
          characterName = sourceCharacterName or profileInfo.characterName,
          realmName = sourceRealmName or profileInfo.realmName,
          metaData = makeProfileMetaData(profileInfo.profileKey, updatedAt)
        }
        tinsert(added, profileInfo.profileKey)
      end
    end
  end

  if #added == 0 and #removed == 0 then
    if not silent then addon.copyHelper:SmartFadeOut(2, L["No Changes detected"]) end
    return false, added, removed
  end

  if #added > 0 or #removed > 0 then
    pack.includedAddons = pack.includedAddons or {}
    pack.includedAddons[lapModule.moduleName] = lapModule.wagoId
    pack.updatedAt = timestamp
    if not silent then addon:OpenReleaseNoteInput(timestamp, {}, {}, {}, {}, added, removed) end
  else
    if not silent then addon.copyHelper:SmartFadeOut(2, L["No Changes detected"]) end
  end

  -- have to remove CDM from included addons if there are no profiles
  local numCdmProfiles = countCdmProfileStrings(pack)
  if numCdmProfiles == 0 then
    if pack.includedAddons then pack.includedAddons[lapModule.moduleName] = nil end
  end
  if not silent and (#added > 0 or #removed > 0) then
    addon:AddDataToStorageAddon(true)
  end
  local gameVersion = select(4, GetBuildInfo())
  pack.gameVersion = gameVersion
  pack.gameFlavor = addon:GetGameFlavorString()
  pack.createdBy = UnitName("player").."-"..GetRealmName()
  addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
  return #added > 0 or #removed > 0, added, removed
end

function addon:HasCooldownManagerDataToExport(pack)
  if not pack or not pack.cdmData then
    return false
  end
  for _, profiles in pairs(pack.cdmData.profileKeys or {}) do
    if next(profiles) then
      return true
    end
  end
  for _, profileStrings in pairs(pack.cdmData.profiles or {}) do
    if next(profileStrings) then
      return true
    end
  end
  return false
end

---@param classAndSpecTag number class and spec tag like "121" for Havoc DH (12 = DH, 1 = Havoc)
local getSpecIconFromClassAndSpecTag = function(classAndSpecTag)
  local classID = math.floor(classAndSpecTag / 10);
  local specIndex = classAndSpecTag % 10;
  local isInspect, isPet, inspectTarget, gender, groupIndex = false, false, nil, nil, nil;
  local icon = select(4,
    ---@diagnostic disable-next-line: redundant-parameter
    C_SpecializationInfo.GetSpecializationInfo(specIndex, isInspect, isPet, inspectTarget, gender, groupIndex, classID));
  return icon or 134400 --questionmark icon fallback
end

---@param s string the string to wrap
---@param classAndSpecTag number class and spec tag like 121 for Havoc DH (12 = DH, 1 = Havoc)
local function wrapStringInClassColor(s, classAndSpecTag)
  local classID = math.floor(classAndSpecTag / 10);
  local classInfo = C_CreatureInfo.GetClassInfo(classID) or "Adventurer"
  if classInfo.className ~= "Adventurer" then
    local _, _, _, classHexString = GetClassColor(classInfo.classFile)
    return "|c"..classHexString..s.."|r"
  end
  return s
end

local function getCharacterDisplayName(characterName, realmName)
  if not characterName then
    return
  end
  if realmName and realmName ~= "" then
    return characterName.."-"..realmName
  end
  return characterName
end

local function createProfileInfo(profileKey, classAndSpecTag, characterKey, characterName, realmName, updatedAt,
                                 showCharacter)
  classAndSpecTag = tonumber(classAndSpecTag)
  if not profileKey or not classAndSpecTag then
    return
  end

  local coloredName = wrapStringInClassColor(profileKey, classAndSpecTag)
  local characterDisplayName = getCharacterDisplayName(characterName, realmName)
  if showCharacter and characterDisplayName then
    coloredName = coloredName.." |cff808080("..characterDisplayName..")|r"
  end

  return {
    profileKey = profileKey,
    icon = getSpecIconFromClassAndSpecTag(classAndSpecTag),
    coloredName = coloredName,
    classAndSpecTag = classAndSpecTag,
    characterKey = characterKey,
    characterName = characterName,
    realmName = realmName,
    searchText = string.lower(profileKey.." "..(characterDisplayName or "")),
    metaData = makeProfileMetaData(profileKey, updatedAt)
  }
end

local function getProfileInfoUpdatedAt(info)
  local lastUpdatedAt = info.metaData and info.metaData.lastUpdatedAt
  if type(lastUpdatedAt) == "table" then
    return lastUpdatedAt[info.profileKey] or 0
  end
  if type(lastUpdatedAt) == "number" then
    return lastUpdatedAt
  end
  return 0
end

local function createProfileInfoForStorage(info)
  if not info or not info.profileKey or not info.classAndSpecTag then
    return
  end
  return {
    profileKey = info.profileKey,
    icon = info.icon,
    coloredName = info.coloredName,
    classAndSpecTag = getCdmClassKey(info.classAndSpecTag),
    characterKey = info.characterKey,
    characterName = info.characterName,
    realmName = info.realmName,
    metaData = info.metaData and CopyTable(info.metaData) or nil
  }
end

local function addAvailableProfileInfo(profileInfoByKey, info, force)
  if not info then
    return
  end
  local key = info.classAndSpecTag.."|"..info.profileKey
  local currentInfo = profileInfoByKey[key]
  if force or not currentInfo or getProfileInfoUpdatedAt(info) > getProfileInfoUpdatedAt(currentInfo) then
    profileInfoByKey[key] = info
  end
end

local function buildAvailableProfileInfos()
  local profileInfoByKey = {}
  local currentCharacterKey, currentCharacterName, currentRealmName = getCurrentCharacterInfo()
  local cache = addon.db and addon.db.cdmProfileCache

  if cache and cache.characters then
    for characterKey, characterCache in pairs(cache.characters) do
      for profileKey, profileCache in pairs(characterCache.profiles or {}) do
        addAvailableProfileInfo(
          profileInfoByKey,
          createProfileInfo(
            profileKey,
            profileCache.classAndSpecTag,
            characterKey,
            characterCache.characterName,
            characterCache.realmName,
            profileCache.updatedAt or characterCache.updatedAt or 0,
            characterKey ~= currentCharacterKey
          )
        )
      end
    end
  end

  if ensureCooldownManagerLoaded() then
    local timestamp = GetServerTime()
    for profileKey, profileData in pairs(lapModule:getProfileKeys() or {}) do
      addAvailableProfileInfo(
        profileInfoByKey,
        createProfileInfo(
          profileKey,
          profileData.classAndSpecTag,
          currentCharacterKey,
          currentCharacterName,
          currentRealmName,
          timestamp,
          false
        ),
        true
      )
    end
  end

  local profileInfos = {}
  for _, info in pairs(profileInfoByKey) do
    tinsert(profileInfos, info)
  end
  table.sort(
    profileInfos,
    function(a, b)
      if a.classAndSpecTag == b.classAndSpecTag then
        return a.profileKey < b.profileKey
      end
      return a.classAndSpecTag < b.classAndSpecTag
    end
  )
  return profileInfos
end

function addon:CacheCooldownManagerProfilesOnLogout()
  if not addon.db or not lapModule or not lapModule.getProfileKeys or not lapModule.exportProfile then
    return
  end
  if not ensureCooldownManagerLoaded() then
    return
  end

  lapModule:closeConfig()

  local characterKey, characterName, realmName = getCurrentCharacterInfo()
  local timestamp = GetServerTime()
  local profiles = {}
  for profileKey, profileData in pairs(lapModule:getProfileKeys() or {}) do
    local classAndSpecTag = tonumber(profileData.classAndSpecTag)
    local exportString = lapModule:exportProfile(profileKey)
    if classAndSpecTag and exportString then
      profiles[profileKey] = {
        profileKey = profileKey,
        classAndSpecTag = classAndSpecTag,
        exportString = exportString,
        updatedAt = timestamp
      }
    end
  end

  local cache = getProfileCache()
  cache.characters[characterKey] = {
    characterKey = characterKey,
    characterName = characterName,
    realmName = realmName,
    updatedAt = timestamp,
    profiles = profiles
  }
end

local setProfileIncludedState = function(info, shouldInclude)
  local pack = addon:GetCurrentPackStashed()
  pack.cdmData = pack.cdmData or {}
  pack.cdmData.profileKeys = pack.cdmData.profileKeys or {}
  local classKey = getCdmClassKey(info.classAndSpecTag)
  pack.cdmData.profileKeys[classKey] = pack.cdmData.profileKeys[classKey] or {}
  pack.cdmData.profileKeys[classKey][info.profileKey] = shouldInclude and createProfileInfoForStorage(info) or nil
end

local function addToData(i, info)
  local alreadyIncluded = false
  for k, v in pairs(scrollBoxData[i]) do
    if tonumber(v.classAndSpecTag) == tonumber(info.classAndSpecTag) and v.profileKey == info.profileKey then
      alreadyIncluded = true
    end
  end
  if not alreadyIncluded then
    tinsert(scrollBoxData[i], info)
  end
  setProfileIncludedState(info, true)
  m.scrollBoxes[i].onSearchBoxTextChanged()
  addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
end

local function removeFromData(i, info)
  for idx, existingInfo in ipairs(scrollBoxData[i]) do
    if existingInfo.profileKey == info.profileKey and tonumber(existingInfo.classAndSpecTag) == tonumber(info.classAndSpecTag) then
      tremove(scrollBoxData[i], idx)
      setProfileIncludedState(info, false)
      m.scrollBoxes[i].onSearchBoxTextChanged()
      addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
      return
    end
  end
end

local function createGroupScrollBox(frame, buttonConfig, scrollBoxIndex)
  local filteredData = {}

  local function updateFilteredData(searchString, data)
    wipe(filteredData)
    local initialData = scrollBoxData[scrollBoxIndex]
    if searchString then
      if searchString ~= "" then
        for _, display in pairs(initialData) do
          local searchText = display.searchText or display.profileKey:lower()
          if searchText:find(searchString, 1, true) then
            table.insert(filteredData, display)
          end
        end
      else
        --add all
        for _, display in pairs(initialData) do
          table.insert(filteredData, display)
        end
      end
    else
      if scrollBoxIndex == 2 then
        for _, display in pairs(initialData) do
          table.insert(filteredData, display)
        end
      end
    end
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
        line.nameLabel:SetText(info.coloredName or info.profileKey)

        local iconSource = info.icon or 135724
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
              removeFromData(scrollBoxIndex, info)
            end
          else
            removeFromData(scrollBoxIndex, line.info)
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
  local instruction = (scrollBoxIndex == 1) and L["Type to search for\nyour Profiles"] or L["Add Profiles\nto Export"]
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
  DF:ApplyStandardBackdrop(m)
  DF:CreateBorder(m)
  m:ClearAllPoints()
  m:SetFrameStrata("FULLSCREEN")
  m:SetFrameLevel(100)
  m.__background:SetAlpha(1)
  m:SetMouseClickEnabled(true)
  m:SetTitle(L["Blizzard Cooldown Manager"])
  m:Hide()
  m.buttons = {}
  m.StartMoving = function()
  end

  local explainerLabel = DF:CreateLabel(m, L["CDM_PROFILES_EXPLAINER"], 18, "white")
  explainerLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 5, -40)
  explainerLabel:SetPoint("TOPRIGHT", m, "TOPRIGHT", -5, -40)

  local exportWarningLabel = DF:CreateLabel(m, L["CDM_EXPORT_WARNING"], 18, "red")
  exportWarningLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 5, -110)
  exportWarningLabel:SetPoint("TOPRIGHT", m, "TOPRIGHT", -5, -110)

  m:HookScript(
    "OnShow",
    function()
      LWF:ToggleLockoutFrame(true, addon.frames, addon.frames.mainFrame)
    end
  )

  m:HookScript(
    "OnHide",
    function()
      LWF:ToggleLockoutFrame(false, addon.frames, addon.frames.mainFrame)
    end
  )

  local buttonConfigs = {
    [1] = {
      [1] = {
        icon = [[Interface\AddOns\WagoUI_Creator\media\misc_arrowright]],
        onClick = function(info)
          addToData(2, info)
        end,
        tooltip = L["Mark as included"]
      }
    },
    [2] = {
      [1] = {
        icon = [[Interface\AddOns\WagoUI_Creator\media\misc_rnrredxbutton]],
        onClick = function(info)
          removeFromData(2, info)
        end,
        tooltip = L["Remove"]
      },
    }
  }
  m.scrollBoxes = {}
  for idx, buttonConfig in ipairs(buttonConfigs) do
    local scrollBox = createGroupScrollBox(m, buttonConfig, idx)
    scrollBox:SetPoint("TOPLEFT", m, "TOPLEFT", 60 + ((idx - 1) * (scrollBoxWidth + 110)), -290)
    m.scrollBoxes[idx] = scrollBox
    local labelText = idx == 1 and L["Your Profiles"] or idx == 2 and L["Exported Profiles"]
    local label = DF:CreateLabel(scrollBox, labelText, 20, "white")
    label:SetPoint("BOTTOM", scrollBox, "TOP", 0, 55)
  end

  local okayButton = LWF:CreateButton(m, 200, 40, L["Okay"], 16)
  okayButton:SetClickFunction(
    function()
      m:Hide()
    end
  )
  okayButton:SetPoint("BOTTOM", m, "BOTTOM", 0, 20)

  local updateCdmExportsCheckbox =
      LWF:CreateCheckbox(
        m,
        25,
        function(_, _, value)
          local pack = addon:GetCurrentPackStashed()
          pack.cdmExportsFrozen = not value
        end,
        true
      )
  updateCdmExportsCheckbox:SetPoint("LEFT", okayButton, "RIGHT", 20, 0)
  m.updateCdmExportsCheckbox = updateCdmExportsCheckbox

  local updateCdmExportsLabel = DF:CreateLabel(m, L["Update CDM exports on Save"], 12, "white")
  updateCdmExportsLabel:SetPoint("LEFT", updateCdmExportsCheckbox, "RIGHT", 10, 0)

  return m
end

local function showManageFrame(anchor)
  if not m then
    m = createManageFrame(frameWidth, frameHeight)
  end
  wipe(scrollBoxData[1])
  wipe(scrollBoxData[2])

  -- fill with cached account profiles plus current character's live profiles
  for _, info in ipairs(buildAvailableProfileInfos()) do
    tinsert(scrollBoxData[1], info)
  end

  -- fill profiles to export from pack data
  local pack = addon:GetCurrentPackStashed()
  m.updateCdmExportsCheckbox:SetValue(not pack.cdmExportsFrozen)
  if pack.cdmData and pack.cdmData.profileKeys then
    for _, profiles in pairs(pack.cdmData.profileKeys) do
      for _, info in pairs(profiles) do
        tinsert(scrollBoxData[2], info)
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

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  hasGroups = true,
  manageFunc = showManageFrame,
}

addon.ModuleFunctions.specialModules[moduleName] = moduleConfig
