# WagoUI

WagoUI includes Install and Create workspaces. Packs contain independent profile records tagged into one or more variations; resolution is optional variation metadata.

Local drafts live in WagoUIDB.creator.packs. Explicitly saved captures live in WagoUIDB.creator.saved; reload writes them to disk for the companion app. WagoUI does not read or migrate the old creator database.

The companion app must adopt the [schema-v2 transport contract](docs/wagoui-redesign/transport.md) before this version can be distributed. Old resolution-shaped packs are rejected with an update message.

Development checks, from the repository root with Lua 5.1:

    lua tests/check.lua
    lua tests/ui.lua
    lua tests/capture_async.lua
    lua tests/cooldown.lua
    lua tests/import_wrappers.lua
    lua tests/addon_availability.lua

These are model, integration-contract and headless widget checks. Validate the actual layout and addon imports in WoW before release.

## Add-on authors

If you want your add-on to be supported in Wago and Wago UI packs, start by submitting it through the Wago add-on request form:

https://docs.google.com/forms/d/e/1FAIpQLSdYdCJuXGx29oAkmzvkgbEnGSlWzXFld_qpChJhfNq2VvBjPA/viewform

Your add-on also needs to expose the profile-management API expected by `LibAddonProfiles` so WagoUI can import, export, compare, select, and configure profiles during pack setup.

### Integration guide

Full guide:
https://github.com/methodgg/Wago-Creator-UI/blob/main/WagoUI_Libraries/LibAddonProfiles/ImplementationGuide.lua

In short, the guide asks add-on authors to:

- Expose the integration functions on a dedicated global API table.
- Implement profile export and import so profiles can round-trip through your own import/export format.
- Provide profile decoding so Wago creators can compare profile data and generate changelogs.
- Provide helpers to list profile keys, read the current profile, and switch profiles.
- Provide config open and close hooks when your add-on has a configuration UI.
- Avoid calling `ReloadUI()` inside these integration functions. WagoUI handles reload timing after setup finishes.

If your add-on only has global settings and no profile system, the guide expects you to treat `"Global"` as the profile key.
