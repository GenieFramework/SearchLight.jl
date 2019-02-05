const CONFIG_PATH     = "config"
const ENV_PATH        = joinpath(CONFIG_PATH, "env")
const LOG_PATH        = "log"
const APP_PATH        = "app"
const RESOURCES_PATH  = joinpath(APP_PATH, "resources")
const TEST_PATH       = "test"
const TEST_PATH_UNIT  = joinpath(TEST_PATH, "unit")

const SEARCHLIGHT_MODEL_FILE_NAME             = "model.jl"
const SEARCHLIGHT_VALIDATOR_FILE_NAME         = "validator.jl"
const SEARCHLIGHT_AUTHORIZATOR_FILE_NAME      = "authorization.yml"
const SEARCHLIGHT_DB_CONFIG_FILE_NAME         = "database.yml"
const SEARCHLIGHT_BOOTSTRAP_FILE_NAME         = ".slbootstrap.jl"
const SEARCHLIGHT_INFO_FILE_NAME              = ".slinfo.jl"

const TEST_FILE_IDENTIFIER = "_test.jl"

const SEARCHLIGHT_VALIDATOR_FILE_POSTFIX      = "Validator.jl"

# Used to store log info during app bootstrap, when the logger itself is not available.
# The queue is automatically emptied by the logger upon load.
const SEARCHLIGHT_LOG_QUEUE = Vector{Tuple{String,Symbol}}()
