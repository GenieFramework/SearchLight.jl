const MIGRATIONS_FOLDER_NAME = "migrations"

const CONFIG_PATH     = "config"
const ENV_PATH        = joinpath(CONFIG_PATH, "env")
const LOG_PATH        = "log"
const APP_PATH        = "app"
const RESOURCES_PATH  = joinpath(APP_PATH, "resources")
const TEST_PATH       = "test"
const TEST_PATH_UNIT  = joinpath(TEST_PATH, "unit")
const DB_PATH         = "db"
const MIGRATIONS_PATH = joinpath(DB_PATH, MIGRATIONS_FOLDER_NAME)


const SEARCHLIGHT_MODEL_FILE_NAME             = "model.jl"
const SEARCHLIGHT_VALIDATOR_FILE_NAME         = "validator.jl"
const SEARCHLIGHT_DB_CONFIG_FILE_NAME         = "connection.yml"
const SEARCHLIGHT_BOOTSTRAP_FILE_NAME         = ".slbootstrap.jl"
const SEARCHLIGHT_INFO_FILE_NAME              = ".slinfo.jl"
const SEARCHLIGHT_MIGRATIONS_TABLE_NAME       = "schema_migrations"

const TEST_FILE_IDENTIFIER = "_test.jl"

const SEARCHLIGHT_VALIDATOR_FILE_POSTFIX      = "Validator.jl"

const LAST_INSERT_ID_LABEL = :LAST_INSERT_ID