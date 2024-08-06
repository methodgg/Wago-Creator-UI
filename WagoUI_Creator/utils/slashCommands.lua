---@type string
local addonName = ...
---@class WagoUICreator
local addon = select(2, ...)

local function slashCommandShow(args, editbox)
  local req, arg = strsplit(' ', args)
  if req then
    addon:SlashCommandHandler(req, arg)
  else
    addon:ToggleFrame()
  end
end

for i, command in pairs(addon.slashPrefixes) do
  _G["SLASH_"..strupper(addonName).."SHOW"..i] = command
end
SlashCmdList[strupper(addonName).."SHOW"] = slashCommandShow

function addon:SlashCommandHandler(req, arg)
  if req == "example" then
    if not InCombatLockdown() then
      addon:ExampleSlashCommand(arg)
    else
      addon:AddonPrint("Example command cannot be invoked in combat!")
    end
  elseif req == "reset" then
    addon:ResetOptions()
  elseif req == "help" or req == "h" or req == "commands" then
    addon:PrintAvailableSlashCommands()
  else
    addon:ToggleFrame()
  end
end

function addon:FireUnprotectedSlashCommand(command)
  local editbox = ChatEdit_ChooseBoxForSend(DEFAULT_CHAT_FRAME) -- Get an editbox
  ChatEdit_ActivateChat(editbox)                                -- Show the editbox
  editbox:SetText(command)                                      -- Command goes here
  -- Process command and hide (runs ChatEdit_SendText() and ChatEdit_DeactivateChat() respectively)
  ChatEdit_OnEnterPressed(editbox)
end

function addon:PrintAvailableSlashCommands()
  addon:AddonPrint("Available slash commands:")

  --show the addon
  local slashPrefixes = ""
  for i, slashPrefix in ipairs(addon.slashPrefixes) do
    slashPrefixes = slashPrefixes..slashPrefix
    if i < #addon.slashPrefixes then
      slashPrefixes = slashPrefixes..", "
    end
  end
  addon:AddonPrint("|cff0085ff"..slashPrefixes.."|r - show the addon")
end

function addon:ExampleSlashCommand(arg)
  addon:AddonPrint("Executing Example Command")
end
