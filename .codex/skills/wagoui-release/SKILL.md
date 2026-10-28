---
name: wagoui-release
description: Perform the single-package WagoUI versioned release workflow when asked to publish or release WagoUI.
---

# WagoUI Release

1. Read AGENTS.md and AGENTS.local.md if present. Inspect the worktree and scope the release.
2. Determine the next version from installer-X.Y.Z tags and WagoUI/WagoUI.toc. Default to a patch bump unless requested otherwise.
3. Complete requested changes and run the repository checks before changing the version.
4. Update WagoUI/WagoUI.toc and WagoUI/CHANGELOG.md to the same version. Keep the changelog's current release entry as one section.
5. Review the release diff. Commit authorized release changes with the exact version as the commit message.
6. Create the installer-X.Y.Z tag, then push the authorized main branch and tag to origin.
7. Verify the Release WagoUI workflow and the installer-X.Y.Z GitHub release and packaged artifact.

The installer tag prefix and WagoUI project ID are retained for distribution continuity. Creator functionality ships inside WagoUI; do not create creator tags or a second package.

Before the first schema-v2 release, verify that the Wago App consumes WagoUIDB.creator.saved and delivers schema-v2 packs to WagoUI_Storage. The app is maintained outside this repository. Do not claim this integration is verified from addon checks alone.

Invoking this skill authorizes the requested release scope. If only part of the workflow was requested, perform that subset. Do not publish during ordinary implementation work.
