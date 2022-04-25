module Validation

using SearchLight

export ValidationResult, ValidationError, ValidationRule, ModelValidator

const valid = true
const invalid = false
export valid, invalid

export validate, validator, haserrors, haserrorsfor, errorsfor, errors_messages_for, errors_to_string

abstract type ValidationAbstractType end

struct ValidationResult <: ValidationAbstractType
  validation_status::Bool
  error_type::Symbol
  error_message::String

  ValidationResult(validation_status, error_type, error_message) = new(validation_status, error_type, error_message)
end
ValidationResult(; validation_status = false, error_type = :validation_error, validation_message = "Model's data is invalid") = ValidationResult(validation_status, error_type, validation_message)
ValidationResult(validation_status::Bool) = validation_status ? ValidationResult(true, :no_error, "") : ValidationResult(validation_status = false)


struct ValidationError <: ValidationAbstractType
  field::Symbol
  error_type::Symbol
  error_message::String
end

"""
Creates Validation rule for a Model's field

# Examples
```julia
julia> function not_empty(field::Symbol, m::T, args::Vararg{Any})::ValidationResult where {T<:AbstractModel}
         isempty(getfield(m, field)) && return ValidationResult(invalid, :not_empty, "should not be empty")
         
         ValidationResult(valid)
       end

julia> function is_int(field::Symbol, m::T, args::Vararg{Any})::ValidationResult where {T<:AbstractModel}
         isa(getfield(m, field), Int) || return ValidationResult(invalid, :is_int, "should be an int")
         
         ValidationResult(valid)
       end

julia> function is_unique(field::Symbol, m::T, args::Vararg{Any})::ValidationResult where {T<:AbstractModel}
         obj = findone(typeof(m); NamedTuple(field => getfield(m, field))... )
         if ( obj !== nothing && ! ispersisted(m) )
           return ValidationResult(invalid, :is_unique, "already exists")
         end

         ValidationResult(valid)
       end

julia> ValidationRule(:username, not_empty)
julia> ValidationRule(:username, is_unique)
julia> ValidationRule(:age, is_int)
julia> ValidationRule(:email, not_empty)
```
"""
struct ValidationRule <: ValidationAbstractType
  field::Symbol
  validator_function::Function
  validator_arguments::Tuple

  ValidationRule(field, validator_function, validator_arguments = ()) = new(field, validator_function, validator_arguments)
end
ValidationRule(validator_function::Function, field::Symbol, validator_arguments::Tuple = ()) = ValidationRule(field, validator_function, validator_arguments)


"""
The object that defines the rules and stores the validation errors associated with the fields of a `model`.
"""
struct ModelValidator
  rules::Vector{ValidationRule}
  errors::Vector{ValidationError}
end
ModelValidator(rules::Vector{ValidationRule}) = ModelValidator(rules, ValidationError[])
ModelValidator() = ModelValidator(ValidationRule[])


# overwrite!
function validator(m) :: ModelValidator
  ModelValidator()
end


#
# validation API
#


"""
    validate(m::T)::Bool where {T<:AbstractModel}

Validates `m`'s data. A `bool` is return and existing errors are pushed to the validator's error stack.
"""
function validate(m::T)::ModelValidator where {T<:SearchLight.AbstractModel}
  hasmethod(validator, Tuple{typeof(m)}) || return ModelValidator()

  mv = validator(typeof(m))

  for r in mv.rules
    vr::ValidationResult = r.validator_function(r.field, m, r.validator_arguments...)
    vr.validation_status || push!(mv.errors, ValidationError(r.field, vr.error_type, vr.error_message))
  end

  mv
end


function haserrors(mv::ModelValidator) :: Bool
  ! isempty(mv.errors)
end


function haserrorsfor(mv::ModelValidator, field::Symbol) :: Bool
  ! isempty(errorsfor(mv, field))
end

const has_errors_for = haserrorsfor # for Genie compatibility


function errorsfor(mv::ModelValidator, field::Union{Symbol,Nothing} = nothing) :: Vector{ValidationError}
  result = ValidationError[]

  for err in mv.errors
    (field === nothing || err.field == field) && push!(result, err)
  end

  result
end


function errorsmessagesfor(mv::ModelValidator, field::Union{Symbol,Nothing} = nothing) :: Vector{String}
  result = String[]

  for err in errorsfor(mv, field)
    push!(result, err.error_message)
  end

  result
end


function errors_to_string(mv::ModelValidator, field::Union{Symbol,Nothing} = nothing;
                          separator::String = "\n", prepend_field::Bool = true,
                          uppercase_first::Bool = prepend_field) :: String
  errors = String[]

  for err in mv.errors
    (field === nothing || err.field == field) && push!(errors, (prepend_field ? "$(err.field) " : "") * err.error_message)
  end

  join( map(x ->  (uppercase_first ? uppercasefirst(x) : x), errors), separator)
end

end