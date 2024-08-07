local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@param profileString string
---@return table | nil
local function decodeProfileString(profileString)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync");
  local version, dataString = string.match(profileString, "^!CELL:(%d+):ALL!(.+)$")
  version = tonumber(version)
  if version < Cell.MIN_VERSION or version > Cell.versionNum then return end
  local decoded = LibDeflate:DecodeForPrint(dataString)
  if not decoded then return end
  coroutine.yield()
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then return end
  coroutine.yield()
  local deserialized = private:LibSerializeDeserializeAsync(decompressed)
  if not deserialized then return end
  coroutine.yield()
  return deserialized
end

local function DoImport(imported)
  local F = Cell.funcs
  -- raid debuffs
  for instanceID in pairs(imported["raidDebuffs"]) do
    if not Cell.snippetVars.loadedDebuffs[instanceID] then
      imported["raidDebuffs"][instanceID] = nil
    end
  end

  -- deal with invalid
  if Cell.isRetail then
    imported["appearance"]["useLibHealComm"] = false
  elseif Cell.isVanilla or Cell.isWrath or Cell.isCata then
    imported["quickCast"] = nil
    imported["quickAssist"] = nil
    imported["appearance"]["healAbsorb"][1] = false
  end

  -- indicators
  local builtInFound = {}
  for _, layout in pairs(imported["layouts"]) do
    for i = #layout["indicators"], 1, -1 do
      if layout["indicators"][i]["type"] == "built-in" then -- remove unsupported built-in
        local indicatorName = layout["indicators"][i]["indicatorName"]
        builtInFound[indicatorName] = true
        if not Cell.defaults.indicatorIndices[indicatorName] then
          tremove(layout["indicators"], i)
        end
      else -- remove invalid spells from custom indicators
        F:FilterInvalidSpells(layout["indicators"][i]["auras"])
      end
    end
  end

  -- add missing indicators
  if F:Getn(builtInFound) ~= Cell.defaults.builtIns then
    for indicatorName, index in pairs(Cell.defaults.indicatorIndices) do
      if not builtInFound[indicatorName] then
        for _, layout in pairs(imported["layouts"]) do
          tinsert(layout["indicators"], index, Cell.defaults.layout.indicators[index])
        end
      end
    end
  end

  -- click-castings
  local clickCastings
  if imported["clickCastings"] then
    if Cell.isRetail then -- RETAIL -> RETAIL
      clickCastings = imported["clickCastings"]
    else                  -- RETAIL -> WRATH
      clickCastings = nil
    end
    imported["clickCastings"] = nil
  elseif imported["characterDB"] and imported["characterDB"]["clickCastings"] then
    if (Cell.isVanilla or Cell.isWrath or Cell.isCata) and imported["characterDB"]["clickCastings"]["class"] == Cell.vars.playerClass then -- WRATH -> WRATH, same class
      clickCastings = imported["characterDB"]["clickCastings"]
      if Cell.isVanilla then                                                                                                               -- no dual spec system
        clickCastings["useCommon"] = true
      end
    else -- WRATH -> RETAIL
      clickCastings = nil
    end
    imported["characterDB"]["clickCastings"] = nil
  end

  -- layout auto switch
  local layoutAutoSwitch
  if imported["layoutAutoSwitch"] then
    if Cell.isRetail then -- RETAIL -> RETAIL
      layoutAutoSwitch = imported["layoutAutoSwitch"]
    else                  -- RETAIL -> WRATH
      layoutAutoSwitch = nil
    end
    imported["layoutAutoSwitch"] = nil
  elseif imported["characterDB"] and imported["characterDB"]["layoutAutoSwitch"] then
    if Cell.isVanilla or Cell.isWrath or Cell.isCata then -- WRATH -> WRATH
      layoutAutoSwitch = imported["characterDB"]["layoutAutoSwitch"]
    else                                                  -- CLASSIC -> RETAIL
      layoutAutoSwitch = nil
    end
    imported["characterDB"]["layoutAutoSwitch"] = nil
  end

  -- remove characterDB
  imported["characterDB"] = nil

  -- remove invalid spells
  F:FilterInvalidSpells(imported["debuffBlacklist"])
  F:FilterInvalidSpells(imported["bigDebuffs"])
  F:FilterInvalidSpells(imported["actions"])
  F:FilterInvalidSpells(imported["customDefensives"])
  F:FilterInvalidSpells(imported["customExternals"])
  F:FilterInvalidSpells(imported["targetedSpellsList"])
  -- F:FilterInvalidSpells(imported["cleuAuras"])

  -- disable autorun
  for i = 1, #imported["snippets"] do
    imported["snippets"][i]["autorun"] = false
  end

  --! overwrite
  CellDB = imported

  if Cell.isRetail then
    CellDB["clickCastings"] = clickCastings
    CellDB["layoutAutoSwitch"] = layoutAutoSwitch
  else
    CellCharacterDB["clickCastings"] = clickCastings
    CellCharacterDB["layoutAutoSwitch"] = layoutAutoSwitch
    CellCharacterDB["revise"] = imported["revise"]
  end
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Cell",
  icon = [[Interface\AddOns\Cell\Media\icon]],
  slash = "/cell",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = true,

  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Cell")
    return loaded
  end,

  needsInitialization = function(self)
    return false
  end,

  openConfig = function(self)
    Cell.funcs:ShowOptionsFrame()
  end,

  closeConfig = function(self)
    -- it's a toggle
    Cell.funcs:ShowOptionsFrame()
  end,

  getProfileKeys = function(self)
    return {
      ["Global"] = true
    }
  end,

  getCurrentProfileKey = function(self)
    return "Global"
  end,

  isDuplicate = function(self, profileKey)
    return true
  end,

  setProfile = function(self, profileKey)

  end,

  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local decodedProfileData = decodeProfileString(profileString)
    if not decodedProfileData then return end
    return "global"
  end,

  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local profileData = decodeProfileString(profileString)
    if not profileData then return end
    DoImport(profileData)
  end,

  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    -- Cell\Modules\About_ImportExport.lua
    local LibDeflate = LibStub:GetLibrary("LibDeflateAsync");
    local prefix = "!CELL:"..Cell.versionNum..":ALL!"
    local db = Cell.funcs:Copy(CellDB)
    db["nicknames"] = nil
    -- possible on Classic only, ignore for now
    -- if includeCharacter then
    --     db["characterDB"] = F:Copy(CellCharacterDB)
    -- end
    local serialized = private:LibSerializeSerializeAsyncEx(nil, db)
    coroutine.yield()
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 5 })
    coroutine.yield()
    local encoded = LibDeflate:EncodeForPrint(compressed)
    coroutine.yield()
    return prefix..encoded
  end,

  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    local profileDataA = decodeProfileString(profileStringA)
    local profileDataB = decodeProfileString(profileStringB)
    if not profileDataA or not profileDataB then return false end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
}
private.modules[m.moduleName] = m
