module Validation

using SearchLight

export ValidationResult, ValidationError, ValidationRule, ModelValidator

const valid = true
const invalid = false
export valid, invalid

export validator, validate, haserrors, haserrorsfor, errorsfor, errors_messages_for, errors_to_string

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


struct ValidationRule <: ValidationAbstractType
  field::Symbol
  validator_function::Function
  validator_arguments::Tuple

  ValidationRule(field, validator_function, validator_arguments = ()) = new(field, validator_function, validator_arguments)
end


"""
The object that defines the rules and stores the validation errors associated with the fields of a `model`.
"""
struct ModelValidator
  rules::Vector{ValidationRule}
  errors::Vector{ValidationError}
end
ModelValidator(rules::Vector{ValidationRule}) = ModelValidator(rules, ValidationError[])


# overwrite!
function validator(m::Type{T})::ModelValidator where {T<:SearchLight.AbstractModel}
  ModelValidator(ValidationRule[])
end


#
# validation API
#


"""
    validate(m::T)::Bool where {T<:AbstractModel}

Validates `m`'s data. A `bool` is return and existing errors are pushed to the validator's error stack.
"""
function validate(m::T)::ModelValidator where {T<:SearchLight.AbstractModel}
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