# WagoUI schema v2 handoff

The Wago App is maintained outside this repository. The changes below are required before publishing the unified addon.

## Creator input

Read WagoUIDB.creator.saved[packID] from WagoUI's account SavedVariables file after reload/logout. Each value is the last explicitly saved pack snapshot. Do not publish creator.packs, which contains editable drafts, or creator.cdmCache, which contains source layouts cached across characters. Do not read WagoUICreatorDB.

Deleting a local pack removes its draft and saved snapshot; it is not an instruction to delete a remotely published pack.

## Installer output

Deliver the same schema as WagoUI_Storage[pack.id]. Preserve stable pack/profile/variation IDs, both order arrays, membership sets, payload strings and profile timestamps. The storage key must equal pack.id. Website/project identifiers may be stored separately; renaming a pack or variation must not change its identity.

Required fields:

| Field | Shape |
| --- | --- |
| schemaVersion | 2 |
| id, name | Nonempty strings |
| variations | Map of ID to {name, resolutions?, description?} |
| variationOrder | Ordered IDs; includes default |
| profiles | Map of ID to profile record |
| profileOrder | Ordered profile IDs |
| additionalAddons | Wago addon ID to addon name |
| releaseNotes | Timestamp string to note text |

Profile records have id, moduleName, name, sourceKey, kind, variations, and, once captured, data and lastUpdatedAt. Membership is {[variationID] = true}. Do not expand shared records into copies per variation.

Kinds are profile, snapshot, group (WeakAuras/Echo), and cdm. CDM records additionally retain classAndSpecTag and creator-side sourceCharacter. Global snapshots retain their last capture until explicitly recaptured. Source keys identify the actual addon profile; names are editable display labels.

Resolutions is absent for Any resolution, otherwise an ordered list of 1–10 distinct {width = integer, height = integer} entries the variation was designed for. It is advisory metadata, not a storage bucket or eligibility restriction. The singular resolution field is rejected.

Capture also supplies gameVersion, gameFlavor, createdBy, updatedAt, includedAddons (addon name to Wago ID), and collectedWagoIds. Preserve the draft's revision, nextID, exportOptions and blockedAuras when retaining creator snapshots. No server-side migration from creator v1 is provided.

Unassigned profiles and uncaptured records may exist in saved drafts; the installer excludes unassigned records and displays uncaptured records as unavailable. The publishing UI should report uncaptured records before upload.

## Release validation

Round-trip one saved pack through the app, server and generated storage addon, then verify:

- A profile shared by two variations still has one ID and payload.
- Renames preserve memberships and installed update history.
- Metadata-only changes and removed memberships are transported.
- Several same-addon profiles require an installer choice.
- CDM class metadata and cached exports survive the round trip.
- Additional addons, WeakAura collected IDs and release notes remain intact.

Local tests do not establish that this external round trip works. The release workflow retains the installer-X.Y.Z tag prefix and WagoUI project identity; there is no second creator release.
