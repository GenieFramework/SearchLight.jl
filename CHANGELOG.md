# Changelog

## v0.12.0 - 2019-08-29

* refactored to use Julia native logging
* cleaned up new model file template
* pretty printing of `DbId` types
* removed shortcut types for the query API (**breaking**)
* improved API for `all` selector, to support `limit` and `offset`
* new configuration option `log_to_file::Bool`
* cleaned up internal API
* generator no longer creates standalone SearchLight apps files
* API consolidation: renamed various methods from `_` to no `_`: `updatewith`, `createorupdateby`, `createorupdate`, `deleteall` (**breaking**)

## v0.11.0 - 2019-08-22

* Renamed `SearchLight.db_init()` to `SearchLight.init()` (**breaking**)
* Internal API cleanup
* `Settings` cleanup: removal of unused `log_highlight` and `log_rotate` fields (**breaking**)
* dependencies update
* fix an issue which caused `SearchLight.delete_all` to silently fail.
