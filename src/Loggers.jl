"""
Provides logging functionality for SearchLight apps.
"""
module Loggers

using Memento, Millboard, Dates
using SearchLight

import Base.log
export log


"""
    log(message, level = "info"; showst::Bool = true) :: Nothing
    log(message::Any, level::Any = "info"; showst::Bool = false) :: Nothing
    log(message::String, level::Symbol) :: Nothing

Logs `message` to all configured logs (STDOUT, FILE, etc) by delegating to `Lumberjack`.
Supported values for `level` are "info", "warn", "debug", "err" / "error", "critical".
If `level` is `error` or `critical` it will also dump the stacktrace onto STDOUT.

# Examples
```julia
```
"""
function log(message, level::Union{String,Symbol} = "info"; showst = false) :: Nothing
  message = string(message)
  level = string(level)

  if level == "err"
    level = "error"
  elseif level == "debug"
    level = "info"
  end

  file_logger = getlogger(@__MODULE__)
  setlevel!(file_logger, SearchLight.config.log_level |> string)
  push!(file_logger, DefaultHandler(log_path(), DefaultFormatter("[{date}|{level}]: {msg}")))

  # for (logger_name, logger) in LOGGERS
  Base.invoke(Core.eval(@__MODULE__, Meta.parse("Memento.$level")), Tuple{typeof(file_logger),typeof(message)}, file_logger, message)
  # end

  if (level == "error") && showst
    println()
    stacktrace()
  end

  nothing
end


"""
    truncate_logged_output(output::String) :: String

Truncates (shortens) output based on `output_length` settings and appends "..." -- to be used for limiting the output length when logging.

# Examples
```julia
julia> SearchLight.config.output_length
100

julia> SearchLight.config.output_length = 10
10

julia> Loggers.truncate_logged_output("abc " ^ 10)
"abc abc ab..."
```
"""
function truncate_logged_output(output::String) :: String
  length(output) > SearchLight.config.output_length && output[1:SearchLight.config.output_length] * "..."
end


"""
    setup_loggers() :: Bool

Sets up default app loggers (STDOUT and per env file loggers) defferring to the `Lumberjack` module.
Automatically invoked.
"""
function setup_loggers() :: Bool
  Memento.config!(SearchLight.config.log_level |> string, fmt="[{date}|{level}]: {msg}")

  try
    isdir(SearchLight.LOG_PATH) || mkpath(SearchLight.LOG_PATH)
    isfile(log_path()) || touch(log_path())
  catch ex
    @warn ex
  end

  true
end


function log_path()
  "$(joinpath(SearchLight.LOG_PATH, SearchLight.config.app_env)).log"
end


"""
    empty_log_queue() :: Vector{Tuple{String,Symbol}}

The SearchLight log queue is used to push log messages in the early phases of framework bootstrap,
when the logger itself is not available. Once the logger is ready, the queue is emptied and the
messages are logged.
Automatically invoked.
"""
function empty_log_queue() :: Nothing
  for log_message in SearchLight.SEARCHLIGHT_LOG_QUEUE
    log(log_message...)
  end

  empty!(SearchLight.SEARCHLIGHT_LOG_QUEUE)

  nothing
end


"""
    macro location()

Provides a macro that injects the FILE and the LINE where the logger was invoked.
"""
macro location()
  :(log(" in $(@__FILE__):$(@__LINE__)", :err))
end

setup_loggers()
empty_log_queue()

end
