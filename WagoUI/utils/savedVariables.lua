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

local function setUpDB(dbKey)
  _G[dbKey] = _G[dbKey] or {}
  addon.db = _G[dbKey]
end

function addon.ResetOptions()
  _G[addon.dbKey] = nil;
  handleDBLoad(addon.db, true, addon.dbDefaults);
  ReloadUI();
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
        setUpDB(addon.dbKey);
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
      if addon.db.autoStart then
        addon:ShowFrame()
      end
    end
  end);
end
