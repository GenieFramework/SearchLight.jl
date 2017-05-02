module Validation

using Genie, SearchLight, App, Database

export ValidationStatus

typealias ValidationStatus Tuple{Bool,Symbol,String}

#
# errors manipulation
#


"""
    push_error!{T<:AbstractModel}(m::T, field::Symbol, error::Symbol, error_message::AbstractString) :: Bool

Pushes the `error` and its corresponding `error_message` to the errors stack of the validator of the model `m` for the field `field`.
"""
function push_error!{T<:AbstractModel}(m::T, field::Symbol, error::Symbol, error_message::AbstractString) :: Bool
  push!(errors!!(m), (field, error, error_message))

  true # this must be bool cause it's used for chaining Bool values
end


"""
    clear_errors!{T<:AbstractModel}(m::T) :: Void

Clears all the errors associated with the validator of `m`.
"""
function clear_errors!{T<:AbstractModel}(m::T) :: Void
  errors!!(m) |> empty!

  nothing
end

#
# validation logic
#


"""
    validate!{T<:AbstractModel}(m::T) :: Bool

Validates `m`'s data. A `bool` is return and existing errors are pushed to the validator's error stack.
"""
function validate!{T<:AbstractModel}(m::T) :: Bool
  ! has_validator(m) && return true

  clear_errors!(m)

  for r in rules!!(m)
    field = r[1]
    rule = r[2]
    args = length(r) == 3 ? r[3] : ()

    status, error_type, error_message = rule(field, m, args...)

    if ! status
      push_error!(m, field, error_type, error_message)
    end
  end

  is_valid(m)
end


"""
    rules!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Function,Vararg{Any}}}

Returns the `vector` of validation rules. An error is thrown if no validator is defined.
"""
function rules!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Function,Vararg{Any}}}
  validator!!(m).rules # rules::Vector{Tuple{Symbol,Symbol,Vararg{Any}}} -- field,method,args
end


"""
    rules{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Function,Vararg{Any}}}}

Returns the `vector` of validation rules wrapped in a `Nullable`.
"""
function rules{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Function,Vararg{Any}}}}
  v = validator(m)
  isnull(v) ? Nullable{Vector{Tuple{Symbol,Symbol,Vararg{Any}}}}() : Nullable{Vector{Tuple{Symbol,Symbol,Vararg{Any}}}}(Base.get(v).errors)
end


"""
    errors!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Symbol,String}}

Returns the `vector` of validation errors. An error is thrown if no validator is defined.
"""
function errors!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Symbol,String}}
  validator!!(m).errors
end


"""
    errors{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Symbol,String}}}

Returns the `vector` of validation errors wrapped in a `Nullable`.
"""
function errors{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Symbol,String}}}
  v = validator(m)
  isnull(v) ? Nullable{Vector{Tuple{Symbol,Symbol,String}}}() : Nullable{Vector{Tuple{Symbol,Symbol,String}}}(Base.get(v).errors)
end


"""
    validator!!{T<:AbstractModel}(m::T) :: ModelValidator

Returns the `ModelValidator` instance associated with `m`. Errors if no validator is defined.
"""
function validator!!{T<:AbstractModel}(m::T) :: ModelValidator
  m.validator
end


"""
    validator{T<:AbstractModel}(m::T) :: Nullable{ModelValidator}

`m`'s validator, wrapped in a Nullable.
"""
function validator{T<:AbstractModel}(m::T) :: Nullable{ModelValidator}
  has_validator(m) ? Nullable{ModelValidator}(m.validator) : Nullable{ModelValidator}()
end


"""
    has_validator{T<:AbstractModel}(m::T) :: Bool

Whether or not `m` has a validator defined.
"""
function has_validator{T<:AbstractModel}(m::T) :: Bool
  has_field(m, :validator)
end


"""
    has_errors{T<:AbstractModel}(m::T) :: Bool

Whether or not `m` has validation errors.
"""
function has_errors{T<:AbstractModel}(m::T) :: Bool
  ! isempty( errors!!(m) )
end


"""
    has_errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Bool

True if `m.field` has validation errors.
"""
function has_errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Bool
  ! isempty(errors_for(m, field))
end


"""
    is_valid{T<:AbstractModel}(m::T) :: Bool

Returns true if `m` has no validation errors.
"""
function is_valid{T<:AbstractModel}(m::T) :: Bool
  ! has_errors(m)
end


"""
    errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{Tuple{Symbol,Symbol,AbstractString}}

The vector of validation errors corresponding to `m.field`.
"""
function errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{Tuple{Symbol,Symbol,AbstractString}}
  result = Tuple{Symbol,Symbol,AbstractString}[]
  for err in errors!!(m)
    err[1] == field && push!(result, err)
  end

  result
end


"""
    errors_messages_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{AbstractString}

Vector of error messages corresponding to the validation errors of `m.field`.
"""
function errors_messages_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{AbstractString}
  result = AbstractString[]
  for err in errors_for(m, field)
    push!(result, err[3])
  end

  result
end


"""
    errors_to_string{T<:AbstractModel}(m::T, field::Symbol, separator = "\n"; upper_case_first = false) :: String

Concatenates the validation errors of `m.field` into a single string -- meant to be displayed easily to end users.
"""
function errors_to_string{T<:AbstractModel}(m::T, field::Symbol, separator = "\n"; upper_case_first = false) :: String
  join( map(x -> upper_case_first ? ucfirst(x) : x, errors_messages_for(m, field)), separator)
end

end
