---
name: wagoui-libaddonprofiles-integration
description: Create or update WagoUI LibAddonProfiles integrations for locally installed World of Warcraft addons. Use when asked to add a new `WagoUI_Libraries/LibAddonProfiles/modules/*.lua` integration, wire it into `load.xml`, inspect a locally installed addon's `.toc` and source, verify the modern WagoUI API from `ImplementationGuide.lua`, or report missing required API functions instead of hallucinating them.
---

# WagoUI LibAddonProfiles Integration

Follow this workflow for modern LibAddonProfiles integrations in the `WagoUI` repository.

## Start Here

Read `AGENTS.md` and `AGENTS.local.md` if it exists before making changes. Apply those repo rules together with this skill.

## Approved Reference Set

Use only these implementation references when deciding how the integration should look:

1. `WagoUI_Libraries/LibAddonProfiles/ImplementationGuide.lua`
2. `WagoUI_Libraries/LibAddonProfiles/modules/BuffReminders.lua`
3. `WagoUI_Libraries/LibAddonProfiles/modules/Ayije_CDM.lua`
4. The installed source of the target addon
5. The installed source of `BuffReminders` and `Ayije_CDM` if you need to see how their addon-side APIs are implemented
6. `WagoUI_Libraries/LibAddonProfiles/load.xml`

Do not study older LibAddonProfiles modules as design references. Ignore pre-guide integrations.

## Discover The Local AddOns Folder

Find the WoW addon root before inspecting the target addon.

1. Check `E:\World of Warcraft\_retail_\Interface\AddOns` first.
2. Check `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns` next.
3. If neither exists, search filesystem drives for `_retail_\Interface\AddOns` and use the first real WoW install that contains the target addon.

Use short shell probes such as:

```powershell
Test-Path 'E:\World of Warcraft\_retail_\Interface\AddOns'
Test-Path 'C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns'
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
  $candidate = Join-Path $_.Root 'World of Warcraft\_retail_\Interface\AddOns'
  if (Test-Path $candidate) { $candidate }
}
```

## Inspect The Target Addon

Start from the target addon's `.toc` file. Treat the `.toc` as the authoritative map for folder names, metadata, and load order.

From the `.toc`, collect:

1. The main addon folder and `.toc` filename
2. `## Version`
3. `## IconTexture`
4. `## X-Wago-ID` if present
5. Saved variable names
6. Candidate config or import/export files from the listed load order

Then search the installed addon source for the exact WagoUI guide functions:

```powershell
rg -n "ExportProfile|ImportProfile|DecodeProfileString|SetProfile|GetProfileKeys|GetCurrentProfileKey|OpenConfig|CloseConfig" "<addon path>"
```

Locate the real addon API table or global and verify where each required function is implemented.

## Required API Contract

Verify the installed addon implements these guide functions from `ImplementationGuide.lua`:

1. `ExportProfile(profileKey)`
2. `ImportProfile(profileString, profileKey)`
3. `DecodeProfileString(profileString)`
4. `SetProfile(profileKey)`
5. `GetProfileKeys()`
6. `GetCurrentProfileKey()`
7. `OpenConfig()`
8. `CloseConfig()`

Do not invent missing globals, tables, or methods.

Do not copy older addon-specific logic from unrelated LibAddonProfiles modules.

## Build The Module

Create `WagoUI_Libraries/LibAddonProfiles/modules/<AddonName>.lua` in the same style and field order as `BuffReminders.lua` and `Ayije_CDM.lua`.

Use these rules:

1. Prefer the addon folder name for `moduleName` unless the `.toc` or existing repo naming makes a different exact name clearly better.
2. Set `wagoId` from `## X-Wago-ID` when present. Find the id online on wago addons if not present.
3. Set `oldestSupported` to the currently installed addon version unless the user or repo gives hard evidence for an older supported minimum.
4. Set `addonNames` to the real required addon folders, usually only the main addon.
5. Set `icon` with `C_AddOns.GetAddOnMetadata("<MainAddon>", "IconTexture")`.
6. Set `slash` from a proven slash command if you can find one quickly in the addon source. If not, use `"?"`.
7. Set profile and reload flags from actual addon behavior. Do not guess.
8. Keep `testImport` empty unless the target addon genuinely needs custom import validation.

For addon API calls:

1. Always call external addon functions inside `xpcall(function() ... end, geterrorhandler())`.
2. Do not add separate global existence checks or function existence checks around the addon API table or its methods.
3. For getters, declare a local variable before `xpcall`, assign inside `xpcall`, and return it afterward.
4. For `getProfileKeys`, default to `{}` if the addon API returns `nil`.
5. For `isLoaded`, usually only check `C_AddOns.IsAddOnLoaded("<MainAddon>")`, but save the result in a local `loaded` variable and return that variable to match the current house style.
6. For `setProfile`, reject missing keys and unknown keys before calling the addon API.
7. For `exportProfile`, reject missing or non-string keys and ensure the key exists before exporting.
8. For `areProfileStringsEqual`, decode both strings through the addon API and compare them with `private:DeepCompareAsync`.

Use this wrapper pattern:

```lua
openConfig = function(self)
  xpcall(function()
    TargetAddonAPI:OpenConfig()
  end, geterrorhandler())
end,
getProfileKeys = function(self)
  local profileKeys = {}
  xpcall(function()
    profileKeys = TargetAddonAPI:GetProfileKeys() or {}
  end, geterrorhandler())
  return profileKeys
end,
isLoaded = function(self)
  local loaded = C_AddOns.IsAddOnLoaded("TargetAddon")
  return loaded
end,
```

## Handle Missing API Functions

If the installed addon does not implement one or more required guide functions:

1. Tell the user exactly which functions are missing.
2. Annotate the generated module with comments at the affected wrappers.
3. Do not hallucinate calls to missing addon APIs.
4. Keep the module loadable by using safe no-op behavior or safe default returns for the missing wrapper.

Use comment text like:

```lua
  getProfileKeys = function(self)
    -- Missing in installed addon source: TargetAddonAPI:GetProfileKeys()
    return {}
  end,
```

Use empty no-op wrappers for missing mutating or config functions:

```lua
  openConfig = function(self)
    -- Missing in installed addon source: TargetAddonAPI:OpenConfig()
  end,
```

Only use the comment fallback when you have already verified from the installed addon source that the function is missing.

## Wire The Module In

Add the new script entry to `WagoUI_Libraries/LibAddonProfiles/load.xml` so the module loads before `finalize.lua`.

Keep the new entry near the other recent module entries unless the surrounding ordering gives a better obvious fit.

Also add the module name to the `defaultSortOrder` list in `WagoUI_Creator/modules/generic.lua` so the creator UI can place the addon correctly in the generic module list.

## Validate Before Finishing

Confirm all of the following:

1. The new module only uses the modern guide functions or clearly annotated missing-function fallbacks.
2. Every real addon API call is wrapped in `xpcall`.
3. No invented addon globals or methods appear in the module.
4. `load.xml` includes the new module.
5. `WagoUI_Creator/modules/generic.lua` includes the module name in `defaultSortOrder`.
6. The module fields come from real addon metadata or real source findings.

## Concrete Good Examples

Use these files as the primary examples for future runs:

1. Repo module: `WagoUI_Libraries/LibAddonProfiles/modules/BuffReminders.lua`
2. Repo module: `WagoUI_Libraries/LibAddonProfiles/modules/Ayije_CDM.lua`
3. Installed addon API: `BuffReminders\Display\ImportExport.lua`
4. Installed addon API: `Ayije_CDM\Config\WagoUI.lua`
5. Installed addon API example with full guide coverage: `NaowhQOL\Data\SettingsIO.lua`
