module Validation

import Revise
using SearchLight

import Base.show

export ValidationResult, valid, invalid
export ValidationError, ValidationRule, ModelValidator

const valid = true
const invalid = false

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


show(io::IO, t::T) where {T<:ValidationAbstractType} = print(io, validationabstracttype_to_print(t))

"""
    validatortype_to_print{T<:ValidationAbstractType}(m::T) :: String

Pretty printing of SearchLight types.
"""
function validationabstracttype_to_print(m::T) :: String where {T<:ValidationAbstractType}
  output = "\n" # "\n" * "$(typeof(m))" * "\n"

  try
    if (SearchLight.hasfield(m, :error_message))
      output *= "$(m.field) $(m.error_message)"
    else
      output *= "$(m.field) $(m.validator_function)"
    end
  catch ex
    output *= string(ex) * "\n"
  end

  output
end


"""
The object that defines the rules and stores the validation errors associated with the fields of a `model`.
"""
struct ModelValidator
  rules::Vector{ValidationRule} # [(:title, :not_empty), (:title, :min_length, (20)), (:content, :not_empty_if_published), (:email, :matches, (r"(.*)@(.*)"))]
  errors::Vector{ValidationError} # [(:title, :not_empty, "title not empty"), (:title, :min_length, "min length 20"), (:content, :min_length, "min length 200")]

  ModelValidator(rules) = new(rules, Vector{ValidationError}())
end


#
# errors manipulation
#


"""
    push_error!(m::T, validation_error::ValidationError)::Bool where {T<:AbstractModel}

Pushes the `error` and its corresponding `error_message` to the errors stack of the validator of the model `m` for the field `field`.
"""
function push_error!(m::T, validation_error::ValidationError)::Bool where {T<:SearchLight.AbstractModel}
  push!(errors(m), validation_error)

  true # this must be bool cause it's used for chaining Bool values
end


"""
    clear_errors!(m::T)::Nothing where {T<:AbstractModel}

Clears all the errors associated with the validator of `m`.
"""
function clear_errors!(m::T)::Nothing where {T<:SearchLight.AbstractModel}
  empty!(errors(m))

  nothing
end

#
# validation logic
#


"""
    validate!(m::T)::Bool where {T<:AbstractModel}

Validates `m`'s data. A `bool` is return and existing errors are pushed to the validator's error stack.
"""
function validate!(m::T)::Bool where {T<:SearchLight.AbstractModel}
  hasvalidator(m) || return true

  clear_errors!(m)

  for r in rules(m)
    vr::ValidationResult = r.validator_function(r.field, m, r.validator_arguments...)
    vr.validation_status || push_error!(m, ValidationError(r.field, vr.error_type, vr.error_message))
  end

  isvalid(m)
end


"""
    rules(m::T)::Union{Nothing,Vector{ValidationRule}} where {T<:AbstractModel}

Returns the `vector` of validation rules wrapped in a `Union{Nothing,Vector{ValidationRule}}`.
"""
function rules(m::T)::Vector{ValidationRule} where {T<:SearchLight.AbstractModel}
  v = validator(m)
  v === nothing ? ValidationRule[] : v.errors
end


"""
    errors(m::T)::Union{Nothing,Vector{ValidationError}} where {T<:AbstractModel}

Returns the `vector` of validation errors wrapped in a `Union{Nothing,Vector{ValidationError}}`.
"""
function errors(m::T)::Vector{ValidationError} where {T<:SearchLight.AbstractModel}
  v = validator(m)
  v === nothing ? ValidationError[] : v.errors
end


"""
    validator(m::T)::Union{Nothing,ModelValidator} where {T<:AbstractModel}

`m`'s validator, wrapped in a Union{Nothing,ModelValidator}.
"""
function validator(m::T)::Union{Nothing,ModelValidator} where {T<:SearchLight.AbstractModel}
  hasvalidator(m) ? m.validator : nothing
end


"""
    hasvalidator(m::T)::Bool where {T<:AbstractModel}

Whether or not `m` has a validator defined.
"""
function hasvalidator(m::T)::Bool where {T<:SearchLight.AbstractModel}
  SearchLight.hasfield(m, :validator)
end


"""
    haserrors(m::T)::Bool where {T<:AbstractModel}

Whether or not `m` has validation errors.
"""
function haserrors(m::T)::Bool where {T<:SearchLight.AbstractModel}
  ! isempty(errors(m))
end


"""
    has_errors_for(m::T, field::Symbol)::Bool where {T<:AbstractModel}

True if `m.field` has validation errors.
"""
function has_errors_for(m::T, field::Symbol)::Bool where {T<:SearchLight.AbstractModel}
  ! isempty(errors_for(m, field))
end


"""
    isvalid(m::T)::Bool where {T<:AbstractModel}

Returns true if `m` has no validation errors.
"""
function isvalid(m::T)::Bool where {T<:SearchLight.AbstractModel}
  ! haserrors(m)
end


"""
    errors_for(m::T, field::Symbol)::Vector{ValidationError} where {T<:AbstractModel}

The vector of validation errors corresponding to `m.field`.
"""
function errors_for(m::T, field::Symbol)::Vector{ValidationError} where {T<:SearchLight.AbstractModel}
  result = ValidationError[]
  for err in errors(m)
    err.field == field && push!(result, err)
  end

  result
end


"""
    errors_messages_for(m::T, field::Symbol)::Vector{String} where {T<:AbstractModel}

Vector of error messages corresponding to the validation errors of `m.field`.
"""
function errors_messages_for(m::T, field::Symbol)::Vector{String} where {T<:SearchLight.AbstractModel}
  result = String[]
  for err in errors_for(m, field)
    push!(result, err.error_message)
  end

  result
end


"""
    errors_to_string(m::T, field::Symbol, separator = "\n"; upper_case_first = false)::String where {T<:AbstractModel}

Concatenates the validation errors of `m.field` into a single string -- meant to be displayed easily to end users.
"""
function errors_to_string(m::T, field::Symbol, separator = "\n"; upper_case_first = false)::String where {T<:SearchLight.AbstractModel}
  join( map(x -> upper_case_first ? uppercasefirst(x) : x, errors_messages_for(m, field)), separator)
end

end
