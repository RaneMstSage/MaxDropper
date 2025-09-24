# CHANGELOG.md

## v1.2.0

* OBJ Export Enhancements:
  * Added automatic mesh triangulation (converts to Editable Mesh before export)
  * Matches Blender's `export_triangulated_mesh=True` behavior
  * Added configurable export scale (default 10.0 for game compatibility)
  * Fixed coordinate system handling - applies identity matrix matching Blender workflow
  * Added export verification to check triangulation and file creation

* UI Improvements:
  * Added Export Scale control with spinner (range: 0.001 to 1000.0)
  * Added scale presets dropdown for common unit conversions
  * Scale value persists between sessions
  * Enhanced progress feedback and status reporting

* Debugging & Reliability:
  * Comprehensive debug output showing export settings and process
  * Improved error handling with detailed error messages
  * Export verification shows first 10 lines of OBJ and triangulation status
  * Added bounding box dimensions reporting

* Code Quality:
  * Better separation of concerns between UI and export logic
  * Cleaner temporary object handling (snapshot → convert → export → delete)
  * Improved documentation and inline comments

## v1.1.0

* Packaged release folder (`startup/`, `MaxDropper/`) for easy install
* OBJ export fixes and logging (target folder, per-file, summary)
* Unified OBJ export triggered for both JSON and XML
* Save dialog improvements:
  * Only prompts when no path set
  * Confirms extension mismatch
  * Confirms overwrite
* Added `.gitignore` (ignoring .svn, exports/\*.obj, etc.)
* Added `.git` to svn\:ignore for dual-repo hygiene

## v1.0.0

* Initial release
* Included startup script and exporter
* Known issues:
  * OBJ export paths inconsistent
  * XML export incomplete
  * Missing `.gitignore` and svn\:ignore rules

---

[Original Redmine project](https://code.mstsage.com/projects/maxdropper)