---
name: wagoui-release
description: Perform the WagoUI versioned release workflow when asked to cut a release, publish a new WagoUI version, bump addon versions and changelogs, create installer and creator tags, push release artifacts, or verify the GitHub releases after publishing.
---

# WagoUI Release

Follow this workflow for releases in the `WagoUI` repository.

## Workflow

1. Read `./AGENTS.md` and `./AGENTS.local.md` if it exists before taking action. Apply both sets of instructions.
2. Inspect the git worktree before changing anything. If there are unrelated local changes that would affect a release, pause and confirm before continuing.
3. Determine the next version from the existing tags that match `installer-X.Y.Z` and `creator-X.Y.Z`. Default to a patch bump unless the user explicitly asks for a different version.
4. Apply any requested code changes for the release before version bumping.
5. Update both addon version headers to the exact release version:
   `WagoUI/WagoUI.toc` -> `## Version: X.Y.Z`
   `WagoUI_Creator/WagoUI_Creator.toc` -> `## Version: X.Y.Z`
6. Update both changelogs and keep only the current release entry as a single section:
   `WagoUI/CHANGELOG.md`
   `WagoUI_Creator/CHANGELOG.md`
7. Review the final diff to confirm the release contents, version strings, and changelog text all match.
8. Commit all release changes with the commit message `X.Y.Z`.
9. Create both release tags for the same version:
   `installer-X.Y.Z`
   `creator-X.Y.Z`
10. Push `main` and both tags to `origin`.
11. Verify that both GitHub Actions release workflows succeed and that both GitHub releases are published with release names equal to their tag names and formatting consistent with prior releases.

## Validation

1. Confirm both `.toc` files contain the same version.
2. Confirm both changelogs contain only one section for the current version.
3. Confirm the commit message equals the release version exactly.
4. Confirm both tags exist locally and on `origin`.
5. Confirm the published release names are `installer-X.Y.Z` and `creator-X.Y.Z`.

## Invocation Notes

- Prefer explicit invocation with `$wagoui-release` when the user wants the release workflow.
- Treat requests such as "do a release", "publish the next WagoUI version", or "cut the next installer/creator release" as triggers for this skill.
- If the user asks for only part of the workflow, complete only that subset and say what remains.
