local addonName, addon = ...;

local function handleDBLoad(database, force, defaults)
  for k, v in pairs(defaults) do
    -- migrate from faulty values
    if (force or (type(database[k]) ~= "boolean" and not database[k])) then
      database[k] = v;
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
  _G[addon.dbKey] = nil;
  _G[addon.dbCKey] = nil;
  handleDBLoad(addon.db, true, addon.dbDefaults);
  ReloadUI();
end

local function shouldAutoStart()
  -- developer autostart
  if addon.db.autoStart then
    return true, false
  end
  -- first login on this character
  if not addon.dbC.firstLogin then
    return true, true
  end
  return false, false
end

do
  local eventListener = CreateFrame("Frame");
  eventListener:RegisterEvent("PLAYER_ENTERING_WORLD");
  eventListener:RegisterEvent("ADDON_LOADED");

  local postDBLoads = {}
  function addon:RegisterPostDBLoad(func)
    table.insert(postDBLoads, func)
  end

  eventListener:SetScript("OnEvent", function(self, event, ...)
    if (event == "ADDON_LOADED") then
      local loadedAddonName = ...;
      if (loadedAddonName == addonName) then
        eventListener:UnregisterEvent("ADDON_LOADED");
        setUpDB(addon.dbKey, addon.dbCKey);
        handleDBLoad(addon.db, nil, addon.dbDefaults);
        --have to do this on next frame
        C_Timer.After(0, function()
          for _, func in pairs(postDBLoads) do
            func()
          end
        end)
      end
    elseif (event == "PLAYER_ENTERING_WORLD") then
      eventListener:UnregisterEvent("PLAYER_ENTERING_WORLD");
      local shouldStart, firstLogin = shouldAutoStart()
      if firstLogin then
        addon:SuppressAddOnSpam()
      end
      if shouldStart then
        addon:ShowFrame()
      end
    end
  end);
end
