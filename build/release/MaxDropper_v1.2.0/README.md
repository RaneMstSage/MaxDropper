# README.md

## MaxDropper

3ds Max exporter for JSON + OBJ with UI integration.
Supports Blender-compatible transforms or Max-native matrices.
Designed to integrate into custom pipelines (Vulkan, Gateware, entt ECS).

### Features

* Export scene entities to JSON (with bounds, transform matrix, custom props)
* Export OBJ models (unique names, reset transform)
* Optional matrix mode:

  * Blender-compatible (Y/Z swap, Z-flip)
  * Max-native (row-major, right-handed, Z-up)
* XML export (basic entity structure)
* UI dialog with:

  * Format selector (JSON / XML)
  * Path chooser (with overwrite confirmation)
  * Toggle OBJ export
  * Custom models folder option

### Installation

1. Download the latest release zip:
   [GitHub Releases](https://github.com/RaneMstSage/MaxDropper/releases)

2. Extract into your 3ds Max user scripts directory:

   ```
   %LOCALAPPDATA%\Autodesk\3dsMax\2026 - 64bit\ENU\scripts\
   ```

   Resulting structure:

   ```
   scripts\startup\MaxDropper_startup.ms
   scripts\MaxDropper\dropper.ms
   scripts\MaxDropper\dropper_ui.ms
   ```

3. Launch 3ds Max.
   The MaxDropper menu item should be available, or call `ShowMaxDropperUI()`.

### Project Links

* Original Redmine project: [https://code.mstsage.com/projects/maxdropper](https://code.mstsage.com/projects/maxdropper)
* GitHub Releases: [https://github.com/RaneMstSage/MaxDropper/releases](https://github.com/RaneMstSage/MaxDropper/releases)
