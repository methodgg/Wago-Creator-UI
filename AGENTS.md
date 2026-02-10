# Release Workflow

Use this workflow when doing a versioned release.

1. Determine next version from existing tags (`installer-X.Y.Z`, `creator-X.Y.Z`), usually patch bump.
2. Apply code changes.
3. Bump both addon versions:
   - `WagoUI/WagoUI.toc` -> `## Version: X.Y.Z`
   - `WagoUI_Creator/WagoUI_Creator.toc` -> `## Version: X.Y.Z`
4. Update both changelogs and keep only the current version entry (single section only):
   - `WagoUI/CHANGELOG.md`
   - `WagoUI_Creator/CHANGELOG.md`
5. Commit all release changes with commit message `X.Y.Z`.
6. Create tags in existing format:
   - `installer-X.Y.Z`
   - `creator-X.Y.Z`
7. Push `main` and both tags to `origin`.
8. Verify both GitHub Actions release workflows succeed and both releases are published with:
   - release name = tag name
   - format matching existing releases.
