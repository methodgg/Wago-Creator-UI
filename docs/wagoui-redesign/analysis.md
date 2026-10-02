# WagoUI: integrated creator and variations

Design study, 2026-10-02. [Open the interactive concepts](concepts.html).

The target is **WagoUI**, upgraded with creator functionality. One installed addon, one window, multiple packs, and a common pack model for creating, previewing, installing and updating. Concept A has been selected. The browser prototype defines the direction. The integrated Lua implementation is now in this worktree; in-game validation and the external Wago App update remain.

## Selected direction

Use **A: Addons & tags** as the main creator interface. It makes the requested relationship visible: an addon has multiple profiles, and each profile has variation tags. Use MethodInternal's selector pattern for variation selection and management, and a checkbox popover/editor for profile memberships.

Keep copy functional: remove explanatory filler, repeated workspace/profile labels and generic subtitles. Keep actual names, resolution metadata, field labels, actionable errors and concise warnings; move secondary action descriptions into accessible tooltips.

Keep the user experience simpler: variation cards in the wizard, a variation selector in expert mode, and no creator controls mixed into either. Install/Create are workspaces inside WagoUI. Wizard/Expert remain installer views. A creator can preview the draft through the exact installer pipeline.

The lazier alternative is to keep the existing installer shell and add a creator tab. That would work, but the resolution-indexed data flow still needs replacing; copying the creator window into a tab would preserve most of the current duplication.

## Original UI and flow (before implementation)

This analysis uses repository source, including both addon entrypoints, layouts, persisted-state code, export and import paths, packaging, shared framework and integration library, and MethodInternal's layout controls. It is not a capture of the live WoW UI. Source counts excluding embedded libraries: **WagoUI: 28 Lua files / 3,735 lines; Creator: 23 Lua files / 6,834 lines**. These counts include inactive source and are not estimates of removable code.

| Surface | Current behavior | Implication for the redesign |
| --- | --- | --- |
| Installer window | An 800 Ã— 600 panel, dark DetailsFramework styling, Wago red branding; wizard, expert and alt views. | Retain familiar branding and installer capabilities; expose Create within this window. Allow a larger creator workspace and scrolling. |
| Wizard welcome | Pack dropdown when several packs exist; Full Installation and Expert Mode actions. A no-pack screen depends on whether the separate creator addon is loaded. | No-pack state offers Create a pack and instructions for getting packs through the Wago App. Creator functionality is always available. |
| Resolution step | Four fixed choices: Any, 1080p, 1440p, 4k. Screen mismatch opens a warning. One compatible choice can be auto-selected. Button placement only covers up to four choices. | Replace with a scrollable variation chooser containing name, suggested resolution and description. Do not impose a variation count limit or resolution lock. |
| Remaining wizard | Separate WeakAuras/CDM handling, ordinary profile selection, install, completion/reload. | Preserve special integration behavior, but build an explicit install plan from the selected variation and profile choices. |
| Expert view | Pack dropdown, resolution dropdown, Intro and Alt Character buttons; flat rows with import/update/re-import status. | Use variation names; group multiple profiles under their addon and keep individual actions/status. |
| Creator window | A separate 1000 Ã— 800 panel. Pack selector, permanent name/create/delete controls, fixed enabled/disabled resolution tabs, one profile dropdown per ordinary addon, group management for special integrations, Save All Profiles, and split-window Preview. | Move infrequent pack/variation actions into contextual management. Replace single-profile slots with profile records and visible membership. |
| Creator alternatives | An Add Alternative button is created but not integrated into the row layout or given a working action in `frameContent.lua`. | Multiple profiles require a real model and flow, not enabling that button. |
| Creator preview | Copies local packs into `WagoUI_Storage` with ` (Local Copy)` in their name, then opens the separate installer beside the creator. | Pass a local draft to the common installer model. Eliminate the cross-addon copy bridge and dependence on two windows. |
| Capture and upload | An export stash is compared with stored exports; changed profiles generate release notes. Save and Reload persists the result; upload continues through the Wago App. | Keep change detection, async processing, release notes and the external upload handoff. Do not label an in-game button Publish if it only saves locally. |
| Alt characters | Uses addon profile assignments or latest imported keys; can enable addons and continue after reload. | Retain this as a user flow and associate choices/history with stable profile IDs. |

### Why this is a model change

Ordinary profiles are stored as `profileKeys[resolution][module]`, exported to `profiles[resolution][module]`, and accompanied by a separate metadata table. The creator changes a single slot; the installer builds rows and selections by resolution and addon. Import history is nested by character, pack, resolution and module. Naming a second profile within the same resolution has no stable place in those structures.

Cooldown Manager is already an exception: its class-tagged profiles live in `cdmData` and are appended into every nonempty resolution list. WeakAuras and Echo Raid Tools store sets of groups rather than a single ordinary profile. Renaming `resolution` to `variation` without changing these structures would keep the single-profile limitation and make CDM membership incorrect.

## Three UI concepts

All three use the same underlying behavior and the same installer. The choice concerns creator organization, not separate feature sets. The prototype starts with Aster UI and Minimal UI; changes are shared when switching concepts.

| Concept | Creator structure | Variation management | Strength | Cost |
| --- | --- | --- | --- | --- |
| **A Â· Addons & tags** | Searchable addon groups, several profile rows per addon, membership chips on each row. | Dropdown with variation rows, edit/delete actions, and New variation at the bottom. A profile action opens multi-select membership. | Directly matches the requested profile/tag model; sharing stays visible. | Needs a preview/filter action to inspect a complete variation. The prototype's selector sets preview context while keeping all profiles visible. |
| **B Â· Variation workspace** | Persistent variation rail; main pane shows profiles belonging to that variation. Add a new profile or include an existing one. | New action in the rail; Edit/Delete beside the active variation's details. | Best when the creator thinks in complete layouts, such as Compact or Healer. | Profiles outside the selected variation are less visible; sharing needs explicit tags and reuse actions. |
| **C Â· Membership matrix** | Addon/profile rows and variation columns; each cell is a membership checkbox. | Edit/Delete in column headers, plus New variation. | Fastest way to audit memberships and notice shared or unassigned profiles. | Wider, denser and less comfortable in small WoW windows or with many variations. Horizontal scrolling is necessary. |

A later optional matrix view could supplement A if creators ask for it. Shipping all three creator interfaces would add maintenance without proving a need. Implement the selected one first.

### MethodInternal reference

`D:/Projects/MethodAddons/MethodInternal_UI/UnlockMode/Layouts.lua`, `GetLayoutDropdownItems()`, puts edit/delete callbacks on individual layout entries and appends a separated New Layout action. `CreateLayoutEditor()` anchors the editor beneath the selector. This is the interaction to reuse, not a dependency on MethodInternal's UI library.

For WagoUI, a dropdown is appropriate for **selecting and managing one variation**. Membership is many-to-many, so the per-profile control should use **checkboxes**, not a single-select dropdown. The variation editor has name, resolution defaulting to Any resolution, optional description, Save/Create and Cancel. It supports presets and positive integer custom dimensions.

## Proposed behavior contract

### Packs and profiles

- Creators can create and manage multiple independent UI packs. Pack names are labels, not primary keys.
- A new pack contains a Default variation with Any resolution and an empty description or short default help text.
- The first profile added for each addon/integration is automatically tagged Default. This is an initialization rule, not a permanent lock.
- When an additional profile for that addon is added, the creator must explicitly select at least one existing variation or create one inline. Multiple memberships can be chosen immediately.
- Every profile, including the first, can have its tags changed. Default can be removed from any profile. Several profiles of the same addon may share a variation.
- A profile reused across variations has one exported payload and one update identity. Editing its tags does not duplicate its export.
- Ordinary source profiles, global-setting snapshots and group-based integrations retain their actual capabilities. A global-settings addon cannot magically hold several active configurations just because WagoUI stores several exports.
- Adding the same ordinary source profile again should direct the creator to its existing tags; distinct global snapshots need an explicit label/capture flow instead of this ordinary-source deduplication rule.

### Variations

- Name is required and unique within the pack after trimming and case-insensitive comparison. Resolution is optional metadata, represented by nil for Any resolution or width/height for a concrete size. Description is optional.
- Resolution changes neither screen resolution nor UI scale. All variations remain selectable. A mismatch is advisory and can be acknowledged in the wizard, without repeated blocking prompts.
- New variations start empty. Offer an optional Include Default profiles checkbox; this adds explicit memberships to the same records, not inheritance or copied payloads.
- No implicit fallback to Default. A missing addon in a variation stays absent. The creator can deliberately tag its existing profile into that variation.
- Editing the variation preserves its stable ID. Renaming does not break profile tags or import history.
- Deleting a variation shows the affected profile count, removes those tags, and preserves every profile and its other memberships. Profiles left with no variation are shown as unassigned drafts and excluded from install lists.
- **Proposed default:** retain the Default variation as the first-profile destination, allow editing its metadata/name, and prevent deleting it. This is a design choice, not a user requirement. Its profile memberships are freely editable. If deletion is desired, the UI must explicitly choose a replacement first-profile destination.
- Ordering is deterministic, with Default first and other variations in creation order. Reordering can be added when requested.

### Installation and updates

- Wizard: select pack â†’ select variation â†’ choose/review profiles â†’ install â†’ finish/reload. If there is only one nonempty variation, it may be preselected; its name remains visible in review.
- Exactly one eligible ordinary profile per addon: preselect it. Multiple eligible ordinary profiles for an addon: require a choice before installation, including global-setting variants. Avoid a last-imported-wins race.
- WeakAuras/Echo groups are additive entries, and can be individually included/excluded. Preserve WeakAuras block/purge options and duplicate handling; do not treat group collections as competing ordinary profiles.
- CDM records have variation membership as well as class/spec eligibility and cached source provenance. Show eligible choices first, expose incompatible entries with an explanation, and retain caching across characters. Preserve the integration's actual class rules; do not casually tighten them to exact spec matching.
- Expert mode lists every profile tagged into the selected variation, with per-record import/update/re-import actions. Importing another profile is explicit. Changing the variation selector alone does not mutate addon settings.
- Track imported payload version, local imported profile key and import time by stable pack/profile IDs. Character state separately records the selected variation and active ordinary profile choices. A shared profile's update status survives switching variations.
- Missing, disabled, outdated and incompatible addons retain distinct actions/messages. Combat restrictions, addon conflicts, rename/overwrite checks, failed imports and reload continuation are handled in one common execution path.
- CDM capacity needs explicit replacement consent. The current integration can remove an active layout when capacity is full; the redesign must not silently retain that behavior.
- Alt setup reuses a character's chosen variation and selected installed profiles, verifies local keys still exist, and continues safely after any enable/reload step.
- Preview loads the creator draft into this same selection/install path. Previewing itself makes no changes; actually importing through preview does affect local addon profiles and must use the usual conflict checks.

The prototype exercises pack creation, first/additional profile assignment, multi-membership editing, variation create/edit/delete, custom resolution entry, draft preview, wizard selection and simulated individual expert imports. It represents group rows and class-tagged layouts. Deep group managers, real compatibility/overwrite dialogs, full alt setup, pack deletion, export diffing and real upload are described here rather than implemented in the sample browser.

## Proposed data model

Store profiles independently of variations. Use one ownership direction for membership; derive variation profile lists when needed. Example, with explanatory field names:

```lua
pack = {
  schemaVersion = 2,
  id = "pack-17",
  name = "Aster UI",
  gameVersion = "mainline",
  variations = {
    default = { name = "Default", description = "" }, -- no resolution = Any
    compact = {
      name = "Compact", resolution = { width = 1920, height = 1080 },
      description = "Tighter spacing for smaller screens.",
    },
  },
  variationOrder = { "default", "compact" },
  profiles = {
    ["profile-1"] = {
      moduleName = "ElvUI", name = "Raid", sourceKey = "Raid",
      kind = "profile", data = "<export string>",
      lastUpdatedAt = 1790899200,
      variations = { default = true, compact = true },
    },
    ["profile-2"] = {
      moduleName = "ElvUI", name = "Compact", sourceKey = "Compact",
      kind = "profile", data = "<different export string>",
      lastUpdatedAt = 1790899200,
      variations = { compact = true },
    },
  },
  profileOrder = { "profile-1", "profile-2" },
  additionalAddons = {},
  releaseNotes = {},
}
```

Group records additionally retain group export/options metadata; CDM records retain class/spec and character-source/cache metadata. Details of those fields should follow the existing integrations, not a speculative new adapter API. Collection presentation can group entries by `moduleName` and `kind` without a second nested collection/variation schema.

`WagoUIDB.creator.packs` owns local drafts and the last successful captured snapshot. `WagoUIDB.importedProfiles[character][packID][profileID]` records successful imports. `WagoUICDB` stores per-character selection, chosen profile IDs, completed setup and resumable actions. External companion-delivered packs remain separate inputs from locally owned drafts.

Keep compatible existing WagoUI user preferences such as minimap visibility and window placement. The user explicitly ruled out **creator-addon migration**; that does not authorize wiping every existing installer preference. Do not read/copy `WagoUICreatorDB`. Old resolution-based import state should not be mistaken for new profile-ID history; a fresh namespace can coexist without a destructive reset.

Validate format/version, IDs, references, sizes/types and integration compatibility when accepting external pack data. Reject unsupported formats with an actionable message, rather than guessing or silently dropping profiles.

## Structure and cleanup

Keep the existing integration library and framework as the foundation. Replace the pack-facing parts around them with a few concrete modules:

```text
WagoUI/
  main.lua                   # one lifecycle and namespace
  core/
    Packs.lua                # pack/profile/variation operations and validation
    Install.lua              # selection plan, import/update state and execution
    Capture.lua              # async export, comparisons, release notes
  ui/
    Main.lua                 # shared window and Install/Create workspaces
    Creator.lua              # selected creator concept
    Wizard.lua               # guided variation and profile selection
    Expert.lua               # individual imports and updates
    Variations.lua           # selector and editor
    Profiles.lua             # common profile rows/membership controls
  creator/                   # retained special integration managers/cache
  utils/                     # one set of async/errors/copy/slash/minimap helpers
  locales/, media/, libs/
WagoUI_Libraries/
  LibAddonProfiles/          # existing addon integrations and encoding
  LibWagoFramework/          # current styling/widgets
```

These are responsibility boundaries, not a requirement to split every function into a new file. Keep small related UI pieces together when that makes the implementation simpler. No new UI library, service registry, dependency injection or generic repository layer is needed.

| Action | Existing source | Replacement / reason |
| --- | --- | --- |
| Keep | `WagoUI_Libraries/LibAddonProfiles/*`, `ImplementationGuide.lua`, framework styling and widgets. | Already provides profile listing, export, import, switching, comparison, config hooks and compatibility. Extend only capabilities actually required by multiple records. |
| Consolidate | Both `main.lua` files, constants, localization, error reporting, copy helpers, slash plumbing and async handlers. | One WagoUI lifecycle, DB owner and helper implementation. `async.lua` is identical apart from namespace. Other similar files have differences that need preserving. |
| Replace | Both resolution constants, creator resolution tabs and enable/disable controls, `introFrame/resolutionPage.lua`, expert resolution selector. | Dynamic variation metadata and a shared selector/editor; no fixed maximum of four. |
| Replace | Creator `ModuleFunctions:SetProfileExport/ClearProfileExport` and resolution-indexed export loops. | Operate on stable profile records. Capture a shared record once, regardless of memberships. Metadata-only variation changes count as pack changes. |
| Replace | `modules/wagoData.lua`, module-keyed wizard state and resolution-keyed import history. | One resolved profile list and record-keyed history, consumed by wizard, expert and preview. |
| Remove | `AddDataToStorageAddon`, local-copy name suffix identities and split-view creatorâ†’installer bridge. | Preview the same owned draft directly, without writing fake external storage entries. |
| Preserve then adapt | WeakAuras, Echo Raid Tools, Additional Addons and Cooldown Manager creator managers. | Keep useful selection and cache behavior; remove resolution assumptions and unify their exported record identities. Additional Addons remain requirements, not fake profiles. |
| Preserve | Disabled/outdated addon states, async export/import, comparisons, per-entry updates, conflict checks, reload handling, diagnostics, alt setup. | Real supported behavior, not legacy solely because the UI is changing. |
| Remove if still unused | Inactive `talentLoadoutEx.lua` (commented out in load XML), unfinished alternative controls, dead commented UI code, obsolete creator-only translations/assets. | Do not carry inactive scaffolding into the new package. Check references before deleting shared assets. |
| Audit, do not blindly remove | Libraries listed in both `libs/loadLibs.xml` and package manifests. | They are duplicated across the two packages, but integrations and framework code depend on some indirectly. Consolidate first, then remove only proven unused dependencies. |
| Consolidate at release preparation | Creator TOC, pkgmeta, separate creator release workflow, paired tags/changelogs and release skill assumptions. | One WagoUI package/release. Retain WagoUI's project/distribution identity and update the release workflow/skill together. No release is requested here. |

### Wago App / distribution boundary

The Wago App code is not in this checkout. Current addon source says publishing continues through it after reload, and it currently consumes creator SavedVariables while producing resolution-shaped `WagoUI_Storage` inputs. Integrating the game addon does not automatically update that external contract.

Before shipping, the app and pack generator must read the new WagoUI creator namespace, accept/transport the new pack schema and stable IDs, present variation metadata on the website where relevant, and deliver the new storage format. The exact app-side implementation is unverified here. No creator migration is needed; current draft capture and uploaded-pack transport still need to work.

Recommended rollout: schema v2 end-to-end, with clear unsupported-pack messaging when an old payload is supplied. Whether existing published legacy packs should remain installable is a separate product decision; the no-creator-migration instruction alone does not settle it. Avoid retaining the entire old runtime merely as an unrequested fallback.

## Implementation status

WagoUI now owns the selected Concept A creator workspace and a 1000 × 700 window. Installation is the landing view; a small Creator tools control opens the secondary workspace. Both share the same pack records. Fixed-resolution screens and the separate creator addon/package have been removed.

Implemented:

- Independent profiles with stable IDs, Default initialization, explicit additional-profile membership, editable tags, and inline variation creation.
- One Profile Variations editor, opened from an alternate-profile action or a variation chip; name, optional resolution, description and membership controls.
- Capture, per-record recapture, global snapshots, saved snapshots, release notes, copy export strings, additional addons, WeakAura export options and exclusions, Echo groups, and CDM source caching by character. Standalone raw-string import is removed.
- Wizard profile choice, per-record expert actions, shared preview, update history, combat checks, addon enabling and reload continuation, and alt profile setup.
- CDM capacity refusal and failed-replacement recovery; synchronous integration wrappers propagate errors and explicit rejection.
- One package/release workflow using the existing WagoUI identity and installer tag prefix. No versions, tags or releases were created.

Executable checks live in tests/check.lua, tests/ui.lua, tests/capture_async.lua, tests/cooldown.lua, tests/import_wrappers.lua and tests/addon_availability.lua. Lua 5.1 parsing, the owned XML load graph, model/capture/import tests, headless widget flows, 33 simple import-wrapper contracts and complex import failure paths passed. The widget harness checks interactions and reuse, not rendered WoW geometry or real integration APIs.

Remaining before release: verify the UI and representative imports in WoW, and implement/validate the external [Wago App transport contract](transport.md). The addon rejects old resolution-shaped storage rather than migrating it. No live WoW process or window was inspected.

Key acceptance scenarios: first profiles join Default; additional profiles cannot be added without membership; first profiles can lose Default; shared profiles export once; multiple same-addon profiles can share a variation; wizard requires a choice; group entries remain additive; variation rename preserves IDs; deletion preserves profiles; more than four variations work; custom resolution is advisory; metadata-only changes reach export/release notes; import history does not collide between records; failures do not mark profiles imported; CDM class/cache/capacity cases stay safe; alt continuation survives reload; local preview uses the published schema.

## Verification of these deliverables

The prototype includes one runnable check, `runChecks()` in the browser console. Its model check covers first-profile defaults, explicit additional-profile membership, multiple profiles in one variation, multiple memberships, editing first-profile tags, stable rename identity, duplicate names, resolution validation, duplicate ordinary sources, non-destructive variation deletion, Default protection, stale IDs and pack independence.

JavaScript parsing and all 13 model checks passed. Browser checks also passed for first-profile assignment in a new pack, mandatory additional-profile tags, inline custom-resolution creation and cancel/return, retaining tags, rename/delete without dropping profiles, multi-profile wizard choice enforcement, simulated expert import state, all three creator layouts, and a 390-pixel viewport without page overflow; no in-game runtime, package build or Wago App validation is claimed. The prototype intentionally uses no external dependencies and can be opened directly as a local HTML file.
