const ROOT_PATH       = pwd()
const CONFIG_PATH     = ROOT_PATH     * "/config"
const ENV_PATH        = CONFIG_PATH   * "/env"
const LOG_PATH        = ROOT_PATH     * "/log"
const RESOURCES_PATH  = ROOT_PATH     * "/resources"
const TEST_PATH       = ROOT_PATH     * "/test"
const TEST_PATH_UNIT  = TEST_PATH     * "/unit"

const SEARCHLIGHT_MODEL_FILE_NAME             = "model.jl"
const SEARCHLIGHT_VALIDATOR_FILE_NAME         = "validator.jl"
const SEARCHLIGHT_AUTHORIZATOR_FILE_NAME      = "authorization.yml"
const SEARCHLIGHT_DB_CONFIG_FILE_NAME         = "database.yml"

const TEST_FILE_IDENTIFIER = "_test.jl"

# Used to store log info during app bootstrap, when the logger itself is not available.
# The queue is automatically emptied by the logger upon load.
const SEARCHLIGHT_LOG_QUEUE = Vector{Tuple{String,Symbol}}()
