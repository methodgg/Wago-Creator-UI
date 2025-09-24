std = "luajit"
globals = {
    -- WoW API globals from .luarc.json
    "DetailsFrameworkPromptSimple", "ReloadUI", "SplashFrame", "UISpecialFrames", "SlashCmdList",
    "EditModeManagerFrame", "ChatEdit_ActivateChat", "ChatEdit_OnEnterPressed", "ChatEdit_ChooseBoxForSend",
    "DEFAULT_CHAT_FRAME", "StaticPopup1Button2", "StaticPopup1Button2Text", "SettingsPanel",
    "coroutine", "PixelUtil", "Mixin", "BackdropTemplateMixin", "QUESTION_MARK_ICON",
    "string", "math", "table", "UIParent", "C_VideoOptions", "C_AddOns", "UIFrameFadeOut",
    "GetLocale", "GetCurrentRegion", "C_Map", "CopyTable", "tIndexOf", "C_EditMode", "C_Timer",
    "date", "tinsert", "InCombatLockdown", "hooksecurefunc", "IsControlKeyDown", "GetTime",
    "UnitFullName", "format", "GetBuildInfo", "debugstack", "tostringall", "strupper", "strsplit",
    "GetServerTime", "wipe", "tremove", "RAID_CLASS_COLORS", "strsub", "strlen", "GameFontNormal",
    "strtrim", "GameFontNormalLarge", "UnitName", "GetRealmName", "bit", "PlaterOptionsPanelFrame",
    "DetailsWelcomeWindow", "StreamOverlayWelcomeWindow", "ViragDevToolFrame", "ElvUIInstallFrame",
    "DetailsNewsWindow", "LibStub", "Bartender4DB", "BigWigs3DB", "BigWigs", "Bartender4",
    "_detalhes_global", "Details", "EchoRaidToolsDB", "EchoCooldowns", "ElvDB", "ElvUI",
    "ElvPrivateDB", "Grid2DB", "Grid2", "NameplateSCTDB", "OmniCC", "PlaterDB", "Plater",
    "SexyMap2DB", "ShadowedUFDB", "ShadowUF", "WeakAurasSaved", "WeakAuras", "vdt",
    "DetailsFramework", "Grid2Options", "Grid2Layout", "OmniCCDB", "SexyMap", "TalentLoadoutsEx",
    "TalentLoadoutsExGUI", "TLX", "TipTac", "TipTacOptions", "WeakAurasOptions", "DetailsOptionsWindow",
    "EchoRaidToolsMainFrame", "OmniCD", "OmniCDDB", "CellChangelogsFrame", "Cell", "CellDB",
    "CellCharacterDB", "BugSackLDBIconDB", "KuiNameplatesCoreSaved", "KuiNameplatesCoreCharacterSaved",
    "KuiNameplatesCore", "WagoUI", "WarpDeplete", "Quartz3DB", "ExampleAddon", "CellAnchorFrame",
    "BigWigsLoader", "BlizzHUDTweaksDB", "OmniBarDB", "OmniBar", "HidingBarDB", "HidingBarDBChar",
    "HidingBarAddon", "HidingBarConfigAddon", "NAuras", "NameplateAurasAceDB", "UUFDB", "UUFG",
    "BigWigsAPI"
}

-- Ignore common WoW addon patterns
ignore = {
    "111", -- setting undefined variable (common in WoW addon initialization)
    "112", -- mutating undefined variable
    "113", -- accessing undefined variable (covered by globals above)
    "212", -- unused argument (common in callback functions)
}

-- File-specific overrides
files["WagoUI/main.lua"].ignore = {"212"} -- unused 'self' arguments
files["WagoUI_Creator/main.lua"].ignore = {"212"} -- unused 'self' arguments