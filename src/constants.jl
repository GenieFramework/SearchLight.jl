const ROOT_PATH       = pwd()
const CONFIG_PATH     = ROOT_PATH     * "/config"
const ENV_PATH        = CONFIG_PATH   * "/env"
const LOG_PATH        = ROOT_PATH     * "/log"

const SEARCHLIGHT_DB_CONFIG_FILE_NAME         = "database.yml"

# Used to store log info during app bootstrap, when the logger itself is not available.
# The queue is automatically emptied by the logger upon load.
const SEARCHLIGHT_LOG_QUEUE = Vector{Tuple{String,Symbol}}()
