# Changelog

## v0.15.2 - 2019-12-04

* added support for `options` in the db connection data - this is passed to the database adapter
* deps update

## v0.15.1 - 2019-11-30

* extended `all` to support the `columns` keyword argument.
* deps update

## v0.15.0 - 2019-11-15

* fixed issue with incorrect `to_join_part` declaration
* refactored type and default value of joins SQLJoin[]
* refactored internal API to rename functions according to Julia guidelines (no `_`) (**breaking**)

## v0.14.0 - 2019-11-10

* internal API cleanup (**breaking**)
* removal of Nullables and refactoring to Union{Nothing,T}
* deps update

## v0.13.1 - 2019-09-25

* deps update

## v0.13.0 - 2019-09-20

* deps update

## v0.12.1 - 2019-08-29

* bug fixes
* deps update

## v0.12.1 - 2019-08-29

* SearchLight environment inherits Genie environment, if available
* Improved handling of 2006 and 2013 MySQL errors (connection lost)
* fixed an issue where reading the configuration file left the file open
* fixed an issue where MySQL non-SELECT queries would not properly return the last insert id
* API cleanup in `SearchLight.Database`

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
