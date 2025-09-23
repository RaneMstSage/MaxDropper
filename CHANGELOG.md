# CHANGELOG.md

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
