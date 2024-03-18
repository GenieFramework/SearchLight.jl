"""
Generic, commonly used validators
"""
module Validators

using SearchLight, SearchLight.Validation

function is_not_empty(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  isempty(getfield(m, field)) && return ValidationResult(invalid, :not_empty, "should not be empty")

  ValidationResult(valid)
end

function is_unique(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  obj = findone(typeof(m); NamedTuple(field => getfield(m, field))... )
  if ( obj !== nothing && ! ispersisted(m) )
    return ValidationResult(invalid, :is_unique, "already exists")
  end

  ValidationResult(valid)
end

function matches_regex(field::Symbol, m::T, args...)::ValidationResult where {T<:AbstractModel}
  # Regular expression for a simple email validation
  regex = args[1]::Regex

  # Check if the field matches the regular expression
  if occursin(regex, field)
      return ValidationResult(valid)
  else
      return ValidationResult(invalid, :matches_regex, "does not match the regular expression")
  end
end

function is_valid_email(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  # Regular expression for a simple email validation
  regex = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
  email = getfield(m, field) |> String

  # Check if the email matches the regular expression
  if occursin(regex, email)
      return ValidationResult(valid)
  else
      return ValidationResult(invalid, :is_valid_email, "is not a valid email")
  end
end

function is_gt_zero(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  isa(getfield(m, field), Int) && getfield(m, field) > 0 && return ValidationResult(valid)

  ValidationResult(invalid, :is_gt_zero, "should be greater than zero")
end

function is_positive(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  isa(getfield(m, field), Int) && getfield(m, field) >= 0 && return ValidationResult(valid)

  ValidationResult(invalid, :is_positive, "should be positive")
end

function is_int(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  isa(getfield(m, field), Int) || return ValidationResult(invalid, :is_int, "should be an int")

  ValidationResult(valid)
end

end