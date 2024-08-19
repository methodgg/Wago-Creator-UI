---@type string
local addonName = ...
---@class WagoUICreator
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local L = addon.L

local commands = {
  ["reset"] = {
    description = L["Reset Options"],
    func = function(args)
      addon:ResetOptions()
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

function addon:FireUnprotectedSlashCommand(command)
  local editbox = ChatEdit_ChooseBoxForSend(DEFAULT_CHAT_FRAME) -- Get an editbox
  ChatEdit_ActivateChat(editbox) -- Show the editbox
  editbox:SetText(command) -- Command goes here
  -- Process command and hide (runs ChatEdit_SendText() and ChatEdit_DeactivateChat() respectively)
  ChatEdit_OnEnterPressed(editbox)
end

function addon:PrintAvailableSlashCommands()
  addon:AddonPrint("Available slash commands:")

  --show the addon
  local slashPrefixes = ""
  for i, slashPrefix in ipairs(addon.slashPrefixes) do
    slashPrefixes = slashPrefixes .. slashPrefix
    if i < #addon.slashPrefixes then
      slashPrefixes = slashPrefixes .. ", "
    end
  end
  addon:AddonPrint("|cff0085ff" .. slashPrefixes .. "|r - show the addon")
end

function addon:ExampleSlashCommand(arg)
  addon:AddonPrint("Executing Example Command")
end
