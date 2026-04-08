# WagoUI

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
