---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)

local function handleDBLoad(database, force, defaults)
  for k, v in pairs(defaults) do
    -- migrate from faulty values
    if (force or (type(database[k]) ~= "boolean" and not database[k])) then
      database[k] = v
    end
    if type(v) == "table" then
      handleDBLoad(database[k], force, v)
    end
  end
end

local function setUpDB(dbKey, dbCKey)
  _G[dbKey] = _G[dbKey] or {}
  addon.db = _G[dbKey]
  _G[dbCKey] = _G[dbCKey] or {}
  addon.dbC = _G[dbCKey] or {}
end

function addon.ResetOptions()
  _G[addon.dbKey] = nil
  _G[addon.dbCKey] = nil
  handleDBLoad(addon.db, true, addon.dbDefaults)
  ReloadUI()
end

local function shouldAutoStart()
  -- developer autostart
  if addon.db.autoStart then
    return true
  end
  if addon.dbC.needLoad then
    return true
  end
  -- do not auto start for creators, they can open up the addon via a button in WagoUI_Creator
  if C_AddOns.IsAddOnLoaded("WagoUI_Creator") then
    addon.db.introEnabled = false
  end
  -- intro enabled
  if addon.db.introEnabled then
    return true
  end
  -- first login on this character and user has installed on another character
  if not addon.dbC.hasLoggedIn and addon.db.anyInstalled then
    return true
  end
  return false
end

do
  local eventListener = CreateFrame("Frame")
  eventListener:RegisterEvent("PLAYER_ENTERING_WORLD")
  eventListener:RegisterEvent("ADDON_LOADED")

  local postDBLoads = {}
  function addon:RegisterPostDBLoad(func)
    table.insert(postDBLoads, func)
  end

  eventListener:SetScript(
    "OnEvent",
    function(self, event, ...)
      if (event == "ADDON_LOADED") then
        local loadedAddonName = ...
        if (loadedAddonName == addonName) then
          eventListener:UnregisterEvent("ADDON_LOADED")
          setUpDB(addon.dbKey, addon.dbCKey)
          handleDBLoad(addon.db, nil, addon.dbDefaults)
          addon:RegisterMinimapButton()
          if not addon.db.minimap.hide then
            addon:ShowMinimapButton()
          end
          if not addon.db.minimap.compartmentHide then
            addon:ShowCompartmentButton()
          end
          --have to do this on next frame
          C_Timer.After(
            0,
            function()
              for _, func in pairs(postDBLoads) do
                func()
              end
            end
          )
        end
      elseif (event == "PLAYER_ENTERING_WORLD") then
        eventListener:UnregisterEvent("PLAYER_ENTERING_WORLD")
        addon:CheckAvailableUpdates()
        if shouldAutoStart() then
          -- need to wait initialization of other addons to finish
          -- could not really find a more elegant way to do this
          C_Timer.After(
            2,
            function()
              addon:ShowFrame()
            end
          )
        end
      end
    end
  )
end
