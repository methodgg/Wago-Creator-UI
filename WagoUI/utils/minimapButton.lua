---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local L = addon.L

local minimapIcon = LibStub("LibDBIcon-1.0")
local addonNameForLDB = "Wago UI Packs"

function addon:HideMinimapButton()
  addon.db.minimap.hide = true
  minimapIcon:Hide(addonNameForLDB)
  print(L["WagoUI: Use /wago minimap to show the minimap icon again"])
  -- update the checkbox in settings
end

function addon:ShowMinimapButton()
  addon.db.minimap.hide = false
  minimapIcon:Show(addonNameForLDB)
  -- update the checkbox in settings
end

function addon:ShowCompartmentButton()
  addon.db.minimap.compartmentHide = false
  minimapIcon:AddButtonToCompartment(addonNameForLDB)
  -- update the checkbox in settings
end

function addon:HideCompartmentButton()
  addon.db.minimap.compartmentHide = true
  minimapIcon:RemoveButtonFromCompartment(addonNameForLDB)
  -- update the checkbox in settings
end

local LDB =
    LibStub("LibDataBroker-1.1"):NewDataObject(
      addonNameForLDB,
      {
        type = "data source",
        text = addonNameForLDB,
        icon = "Interface\\AddOns\\"..addonName.."\\media\\wagoLogo512",
        OnClick = function(button, buttonPressed)
          if buttonPressed == "RightButton" then
            if addon.db.minimap.lock then
              minimapIcon:Unlock(addonNameForLDB)
            else
              minimapIcon:Lock(addonNameForLDB)
            end
          elseif (buttonPressed == "MiddleButton") then
            if addon.db.minimap.hide then
              addon:ShowMinimapButton()
            else
              addon:HideMinimapButton()
            end
          else
            addon:ToggleFrame()
          end
        end,
        OnTooltipShow = function(tooltip)
          if not tooltip or not tooltip.AddLine then
            return
          end
          tooltip:AddLine("|c"..addon.color.."Wago".."|r UI Packs")
          tooltip:AddLine(L["Click to toggle AddOn Window"])
          tooltip:AddLine(L["Right-click to lock Minimap Button"])
          tooltip:AddLine(L["Middle-click to disable Minimap Button"])
        end
      }
    )

function addon:RegisterMinimapButton()
  minimapIcon:Register(addonNameForLDB, LDB, addon.db.minimap)
end
