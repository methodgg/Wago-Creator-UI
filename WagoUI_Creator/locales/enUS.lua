---@format disable
---@class WagoUICreator
local addon = select(2, ...)
addon.L = {}
local L = addon.L
L["Blocked"] = "Blocked"
L["Type to search for\nyour AddOns"]  = "Type to search for\nyour AddOns"
L["Mark Addons as\nIncluded"] = "Mark Addons as\nIncluded"
L["Mark as included"] = "Mark as included"
L["Remove"] = "Remove"
L["Additional Addons"] = "Additional Addons"
L["Your Addons"] = "Your Addons"
L["Included Addons"] = "Included Addons"
L["noBuiltInProfileTextImport"] =
  "%s has no built-in profile text import.\nCopy a string that can be imported with UIManager"
L["Open an issue on GitHub"] = "Open an issue on GitHub"
L["Provide feedback in Discord"] = "Provide feedback in Discord"
L["copiedToClipboard"] = "Copied!"
L["copyInstruction"] = "Press CTRL + C to copy!"
L["Addon Error"] = "WagoUI Creator Error"
L["Error Label 1"] = "WagoUI Creator has encountered errors."
L["Error Label 2"] = "Please update WagoUI Creator to the latest version."
L["Error Label 3"] = "Visit either GitHub or Discord and report the error message below."
L["Copy"] = "Copy"
L["Error Message"] = "Error Message"
L["Copy error"] = "Copy Error"
L["Open an issue on GitHub"] = "Open an issue on GitHub"
L["Provide feedback in Discord"] = "Provide feedback in Discord"
L["Click to open %s options"] = "Click to open %s options"
L["Last Save"] = "Last Save"
L["Action"] = "Action"
L["Name"] = "Name"
L["Options"] = "Options"
L["Reset Options"] = "Reset Options"
L["Show available slash commands"] = "Show available slash commands"
L["Available slash commands"] = "Available slash commands"
L["Import"] = "Import"
L["No profiles to export!"] = "No profiles to export!"
L["Saving all profiles..."] = "Saving all profiles..."
L["Reset?"] = "Reset?"
L["Export done!"] = "Export done!"
L["Preparing export string..."] = "Preparing export string..."
L["Manage"] = "Manage"
L[
    "Choose which resolutions you want the UI pack to support. You can provide a separate profile for each resolution and AddOn."
  ] =
  "Choose which resolutions you want the UI pack to support. You can provide a separate profile for each resolution and AddOn."
L["Enable this resolution"] = "Enable this resolution"
L["exportExplainerLabel"] =
  "All chosen profiles for all enabled resolutions will be exported and saved. After a reload a new update can be pushed via the WagoApp."
L["Save All Profiles"] = "Save All Profiles"
L["Profile to Save"] = "Profile to Save"
L["Drag and drop\nto add WeakAuras"] = "Drag and drop\nto add WeakAuras"
L["Search:"] = "Search:"
L["WeakAuras Export Settings"] = "WeakAuras Export Settings"
L["Export"] = "Export"
L["Drag and drop\nto add Group"] = "Drag and drop\nto add Group"
L["Echo Raid Tools Export Settings"] = "Echo Raid Tools Export Settings"
L["Cooldown Groups"] = "Cooldown Groups"
L["Toggle All"] = "Toggle All"
L["Close"] = "Close"
L["Done"] = "Done"
L["No Changes detected"] = "No Changes detected"
L["Updated / Added"] = "Updated / Added"
L["Removed"] = "Removed"
L["Save and Reload"] = "Save and Reload"
L["Okay"] = "Okay"
L["wagoSettingsExplainer"] =
  "These settings help provide users with information about your UI Pack.\nRemember that the settings are per resolution."
L["wagoSettingsSpecs"] = "Select the specs that your UI Pack is supporting"
L["Purge Wago IDs for exports"] = "Purge Wago IDs for exports"
L["Create Pack"] = "Create Pack"
L["Delete"] = "Delete"
L["Exporting..."] = "Exporting..."
L["Marked for Export"] = "Marked for Export"
L["exportButtonWarning"] =
  "Directly export the selected profile and make it available to copy to the clipboard.\nWARNING: This does not save the profile to disk or update the UI pack."
L["nonNativeExportLabel"] = "(*)"
L["nonNativeExportTooltip"] =
  "*This AddOn does not natively provide profile import / export. The profile string will only be compatible with WagoUI"
L["copied!"] = "copied!"
L["Cancel"] = "Cancel"
L["Pack name:"] = "Pack name:"
L["autoReleaseNotesExplanation"] =
  "These are auto generated release notes in Markdown format. Feel free to edit them.\nThe notes show up when users install or update your UI Pack."
L["Continue the upload through the Wago App after the reload!"] =
  "Continue the upload through the Wago App after the reload!"
L["Any Resolution"] = "Any Resolution"
L["Any"] = "Any"
L["Enable debug mode"] = "Enable debug mode"
L["Name too short"] = "Name too short"
L["Name already exists"] = "Name already exists"
L["AddOn disabled - click to enable"] = "AddOn disabled - click to enable"
L["Not Installed"] = "Not Installed"
L["Enabled after reload"] = "Enabled after reload"
L["RELOAD_HINT"] = "Click to reload the UI"
L["Create a new pack to start"] = "Create a new pack to start"
L["Search for your\nWeakAuras"] = "Search for your\nWeakAuras"
L["Exported WeakAuras"] = "Exported WeakAuras"
L["Your WeakAuras"] = "Your WeakAuras"
L["Remove from export list"] = "Remove from export list"
L["Add to export list"] = "Add to export list"
L["Copy export string directly to clipboard"] = "Copy export string directly to clipboard"
L["Type to search for\nyour WeakAuras"] = "Type to search for\nyour WeakAuras"
L["Add WeakAuras\nto Export"] = "Add WeakAuras\nto Export"
L["Toggle WA Options"] = "Toggle WA Options"
L["Preview"] = "Preview"
L["Use the same name as you did on the website"] = "Use the same name as you did on the website"
L["Reload needed"] = "Reload needed"
L["Enabled"] = "Enabled"
L["Disabled"] = "Disabled"
L["Addon out of date - update required"] = "Addon out of date - update required"
L["RESOLUTION_ENABLE__BUTTON_TOOLTIP"] =
  'The different resolutions for which you can export profiles for DO NOT change your profiles or WeakAuras in any way - no automatic conversion to different resolutions and / or sizes is happening. These are simply options for you to offer multiple different profiles tailored to different resolutions to your users. If you only want to offer your exports in one way then do not enable this and simply export your profiles for "Any Resolution"'
L["DISABLE_RESOLUTION_BUTTON_TOOLTIP"] =
  "Click to disable\nDisabling a resolution will also disable all exports for this resolution from your exported data"
L["WEAKAURA_WARNING_TOOLTIP"] =
  "Ensure that you have the author's permission to distribute any WeakAuras you wish to export.\nExported WeakAuras currently have their Wago IDs and URLs removed."
L["ADDITIONAL_ADDONS_EXPLAINER"] = "You can specify additional AddOns that you want to include in your UI Pack. This is meant for AddOns that do not need any configuration to be exported. A good example is an AddOn that only includes your own custom media. AddOns specified this way are available to automatically download during the UI Pack installation process.\n\nThis feature is only available for AddOns that are hosted and publicly available on the Wago AddOns platform and have the X-Wago-ID field properly set in the toc file."
