module CarsValidator

using SearchLight, SearchLight.Validation

function not_empty(field::Symbol, m::T, args::Vararg{Any})::ValidationResult where {T<:AbstractModel}
  isempty(getfield(m, field)) && return ValidationResult(invalid, :not_empty, "should not be empty")

  ValidationResult(valid)
end

end
