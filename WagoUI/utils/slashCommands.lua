---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local L = addon.L
local DF = _G["DetailsFramework"]

local commands = {
  ["minimap"] = {
    description = L["Toggle Minimap Button"],
    func = function(args)
      if addon.db.minimap.hide then
        addon:ShowMinimapButton()
      else
        addon:HideMinimapButton()
      end
    end
  },
  ["reset"] = {
    description = L["Reset Options"],
    func = function(args)
      addon.ShowAddonResetPrompt()
    end
  },
  ["help"] = {
    description = L["Show available slash commands"],
    func = function(args)
      addon:PrintAvailableSlashCommands()
    end
  },
  ["debug"] = {
    description = L["Enable debug mode"],
    func = function(args)
      DF:ShowPromptPanel(
        "Toggle Debug and reload?",
        function()
          addon.db.debug = not addon.db.debug
          addon.db.autoStart = addon.db.debug
          ReloadUI()
        end,
        function()
        end
      )
    end
  }
}

local function slashCommandShow(args, editbox)
  local req, arg = strsplit(" ", args)
  if req and commands[req] then
    commands[req].func(arg)
  else
    addon:ToggleFrame()
  end
end

for i, command in pairs(addon.slashPrefixes) do
  _G["SLASH_" .. strupper(addonName) .. "SHOW" .. i] = command
end
SlashCmdList[strupper(addonName) .. "SHOW"] = slashCommandShow

function addon:PrintAvailableSlashCommands()
  addon:AddonPrint(L["Available slash commands"] .. ":")
  local res = ""
  for command, _ in pairs(commands) do
    res = res .. " " .. command
    addon:AddonPrint(addon.slashPrefixes[1] .. " " .. command)
  end
end
