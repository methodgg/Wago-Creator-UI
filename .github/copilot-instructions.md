# Wago Creator UI

Wago Creator UI is a World of Warcraft addon ecosystem consisting of two main components written in Lua:
- **WagoUI**: The pack installer addon that helps users install and manage UI addon packs
- **WagoUI_Creator**: The pack creator addon that helps users create and export their own UI addon packs

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Setup
- This is a World of Warcraft addon project - it cannot be "run" standalone but must be validated through syntax checking
- Install Lua validation tools:
  ```bash
  sudo apt update && sudo apt install -y lua5.1 luarocks
  luarocks install --local luacheck
  export PATH="$HOME/.luarocks/bin:$PATH"
  ```

### Validation and Testing
- **CRITICAL**: Always validate Lua syntax before making changes:
  ```bash
  export PATH="$HOME/.luarocks/bin:$PATH"
  luacheck . --no-color
  ```
  - **TIMING**: Full codebase validation takes 0.8 seconds (92 files). NEVER CANCEL.
  - **TIMING**: Single addon validation takes 0.4 seconds (49 files). NEVER CANCEL.
  - Set timeout to 30+ seconds for safety.
  - Expected output: "Total: 244 warnings / 0 errors in 92 files" (warnings OK, 0 errors required)
  - Most warnings about line length (>120 chars) and unused variables are acceptable
  - Focus on fixing syntax errors (return code 0 = success, warnings OK)

- **Validation Scenarios After Changes**:
  ```bash
  # Test individual addons
  luacheck WagoUI --no-color          # ~0.4 seconds
  luacheck WagoUI_Creator --no-color  # ~0.4 seconds
  
  # Test specific file (if WoW API globals are undefined, add --globals flag)
  luacheck path/to/changed/file.lua --no-color  # <0.1 seconds
  luacheck WagoUI/main.lua --globals UIParent DetailsFrameworkPromptSimple --no-color
  ```

### Build Process
- **NEVER try to build locally** - builds only work via GitHub Actions with BigWigsMods packager
- Builds are triggered automatically on git tags:
  - Tags starting with "installer*" build WagoUI (installer addon)  
  - Tags starting with "creator*" build WagoUI_Creator (creator addon)
- **CRITICAL BUILD TIMING**: GitHub Actions builds take 5-15 minutes. NEVER CANCEL.
- Build process:
  1. Clone repository with full git history
  2. Copy TOC files and changelogs to root
  3. Use BigWigsMods packager with pkgmeta.yaml to pull external dependencies
  4. Package and publish to CurseForge/Wago.io

### Repository Structure Navigation
- **WagoUI/**: Main installer addon
  - `WagoUI.toc`: Addon metadata and interface version
  - `main.lua`: Core initialization
  - `modules/`: Feature modules (addonSpam, wagoData, availableUpdates)
  - `wagoFrames/`: UI frames (introFrame, expertFrame, altFrame)
  - `utils/`: Utilities (slashCommands, constants, errorHandling)
  - `pkgmeta.yaml`: Build configuration and external dependencies
- **WagoUI_Creator/**: Pack creator addon (similar structure)
- **WagoUI_Libraries/**: Shared libraries including LibAddonProfiles modules
- **definitions.lua**: Type definitions for Lua language server
- **.luarc.json**: Lua language server configuration with WoW API globals

### Validation Scenarios
- **ALWAYS validate syntax after making changes**: Run `luacheck . --no-color` (0.8 seconds total)
- **Test addon functionality understanding**: Verify `/wago`, `/wui`, `/wagoui` work by checking constants in `WagoUI/utils/constants.lua`:
  ```lua
  addon.slashPrefixes = {
    "/wago",
    "/wui", 
    "/wagoui"
  }
  ```
- **Verify addon loading**: Ensure `load.xml` includes all necessary files in correct order
- **Check TOC compatibility**: Verify interface versions in `.toc` files match current WoW versions (110200, 110107, 50500, 40402, 11507)
- **Library integration test**: Confirm 35+ addon profile modules exist in `WagoUI_Libraries/LibAddonProfiles/modules/`

### Manual Testing Scenarios  
Since this is a WoW addon, manual testing requires World of Warcraft client. However, you can validate:
1. **Slash command functionality**: Check command definitions in `utils/slashCommands.lua` files
2. **UI frame structure**: Verify frame definitions in `wagoFrames/` directories  
3. **Error handling**: Ensure error handlers exist in `utils/errorHandling.lua` files
4. **Database structure**: Validate saved variable schemas in `utils/constants.lua` files

### Common Tasks

#### Essential File Locations
- Slash commands: `WagoUI/utils/slashCommands.lua`, `WagoUI_Creator/utils/slashCommands.lua`
- Configuration constants: `WagoUI/utils/constants.lua`, `WagoUI_Creator/utils/constants.lua`
- Main addon entry points: `WagoUI/main.lua`, `WagoUI_Creator/main.lua`
- UI error handling: `WagoUI/utils/errorHandling.lua`, `WagoUI_Creator/utils/errorHandling.lua`
- Addon profiles: `WagoUI_Libraries/LibAddonProfiles/modules/` (contains 20+ addon integrations)

#### Quick Repository Overview
```
ls -la [repo-root]
.editorconfig
.git/
.github/workflows/  # GitHub Actions for releases
.gitignore
.luarc.json         # Lua language server config
LICENSE
README.md
WagoUI/             # Main installer addon
WagoUI_Creator/     # Pack creator addon  
WagoUI_Libraries/   # Shared libraries
cspell.json         # Spell checking config
definitions.lua     # Type definitions
```

#### Key TOC File Contents
```
cat WagoUI/WagoUI.toc
## Interface: 110200, 110107, 50500, 40402, 11507
## Title: Wago UI Pack Installer
## Author: The Wago Team
## Version: 1.5.2
## X-Wago-ID: O67jdaN3
```

#### Essential pkgmeta.yaml Structure
- Defines external library dependencies from CurseForge/GitHub
- Specifies folder movements and packaging rules
- Critical for automated builds via BigWigsMods packager

### Development Workflow
1. **ALWAYS run validation first**: `luacheck . --no-color` (takes 0.8 seconds, NEVER CANCEL)
2. Make minimal changes to Lua files
3. **Re-validate immediately**: `luacheck . --no-color`
4. Test that TOC files load correctly if modified
5. Check that XML load files include any new Lua files
6. **Final validation**: `luacheck . --no-color` before committing

### Timeout Values and "NEVER CANCEL" Guidelines
- **Syntax validation**: Always completes in <1 second. Set timeout: 30+ seconds. NEVER CANCEL.
- **File system operations**: Complete instantly. Set timeout: 10+ seconds. NEVER CANCEL.
- **GitHub Actions builds**: Take 5-15 minutes. Set timeout: 30+ minutes. NEVER CANCEL.
- **External dependency pulls**: Can take 2-5 minutes. Set timeout: 10+ minutes. NEVER CANCEL.

### Critical Reminders
- **NEVER CANCEL** syntax validation - it completes in under 1 second
- **NEVER try to build locally** - only GitHub Actions can build due to external dependencies
- **NEVER modify external libraries** in `libs/` folders - they're auto-managed by packager
- Always validate that XML load files include new Lua files in correct order
- Use existing WoW API patterns found in current codebase
- Check `.luarc.json` for available WoW API globals when adding new API calls

### Troubleshooting
- **Syntax errors**: Most issues are undefined WoW API globals - check `.luarc.json` for available globals
- **Load order issues**: Ensure XML files include Lua files in dependency order
- **Missing files**: Check that `load.xml` or module-specific load files include new Lua files
- **Build failures**: Only occur in GitHub Actions and usually indicate missing external dependencies