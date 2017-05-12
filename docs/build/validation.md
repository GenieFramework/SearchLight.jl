

- [Genie / SearchLight](index.md#Genie-/-SearchLight-1)

<a id='Validation.push_error!' href='#Validation.push_error!'>#</a>
**`Validation.push_error!`** &mdash; *Function*.



```
push_error!{T<:AbstractModel}(m::T, field::Symbol, error::Symbol, error_message::AbstractString) :: Bool
```

Pushes the `error` and its corresponding `error_message` to the errors stack of the validator of the model `m` for the field `field`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L14-L18' class='documenter-source'>source</a><br>

<a id='Validation.clear_errors!' href='#Validation.clear_errors!'>#</a>
**`Validation.clear_errors!`** &mdash; *Function*.



```
clear_errors!{T<:AbstractModel}(m::T) :: Void
```

Clears all the errors associated with the validator of `m`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L26-L30' class='documenter-source'>source</a><br>

<a id='Validation.validate!' href='#Validation.validate!'>#</a>
**`Validation.validate!`** &mdash; *Function*.



```
validate!{T<:AbstractModel}(m::T) :: Bool
```

Validates `m`'s data. A `bool` is return and existing errors are pushed to the validator's error stack.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L42-L46' class='documenter-source'>source</a><br>

<a id='Validation.rules!!' href='#Validation.rules!!'>#</a>
**`Validation.rules!!`** &mdash; *Function*.



```
rules!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Function,Vararg{Any}}}
```

Returns the `vector` of validation rules. An error is thrown if no validator is defined.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L68-L72' class='documenter-source'>source</a><br>

<a id='Validation.rules' href='#Validation.rules'>#</a>
**`Validation.rules`** &mdash; *Function*.



```
rules{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Function,Vararg{Any}}}}
```

Returns the `vector` of validation rules wrapped in a `Nullable`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L78-L82' class='documenter-source'>source</a><br>

<a id='Validation.errors!!' href='#Validation.errors!!'>#</a>
**`Validation.errors!!`** &mdash; *Function*.



```
errors!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Symbol,String}}
```

Returns the `vector` of validation errors. An error is thrown if no validator is defined.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L89-L93' class='documenter-source'>source</a><br>

<a id='Validation.errors' href='#Validation.errors'>#</a>
**`Validation.errors`** &mdash; *Function*.



```
errors{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Symbol,String}}}
```

Returns the `vector` of validation errors wrapped in a `Nullable`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L99-L103' class='documenter-source'>source</a><br>

<a id='Validation.validator!!' href='#Validation.validator!!'>#</a>
**`Validation.validator!!`** &mdash; *Function*.



```
validator!!{T<:AbstractModel}(m::T) :: ModelValidator
```

Returns the `ModelValidator` instance associated with `m`. Errors if no validator is defined.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L110-L114' class='documenter-source'>source</a><br>

<a id='Validation.validator' href='#Validation.validator'>#</a>
**`Validation.validator`** &mdash; *Function*.



```
validator{T<:AbstractModel}(m::T) :: Nullable{ModelValidator}
```

`m`'s validator, wrapped in a Nullable.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L120-L124' class='documenter-source'>source</a><br>

<a id='Validation.has_validator' href='#Validation.has_validator'>#</a>
**`Validation.has_validator`** &mdash; *Function*.



```
has_validator{T<:AbstractModel}(m::T) :: Bool
```

Whether or not `m` has a validator defined.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L130-L134' class='documenter-source'>source</a><br>

<a id='Validation.has_errors' href='#Validation.has_errors'>#</a>
**`Validation.has_errors`** &mdash; *Function*.



```
has_errors{T<:AbstractModel}(m::T) :: Bool
```

Whether or not `m` has validation errors.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L140-L144' class='documenter-source'>source</a><br>

<a id='Validation.has_errors_for' href='#Validation.has_errors_for'>#</a>
**`Validation.has_errors_for`** &mdash; *Function*.



```
has_errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Bool
```

True if `m.field` has validation errors.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L150-L154' class='documenter-source'>source</a><br>

<a id='Validation.is_valid' href='#Validation.is_valid'>#</a>
**`Validation.is_valid`** &mdash; *Function*.



```
is_valid{T<:AbstractModel}(m::T) :: Bool
```

Returns true if `m` has no validation errors.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L160-L164' class='documenter-source'>source</a><br>

<a id='Validation.errors_for' href='#Validation.errors_for'>#</a>
**`Validation.errors_for`** &mdash; *Function*.



```
errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{Tuple{Symbol,Symbol,AbstractString}}
```

The vector of validation errors corresponding to `m.field`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L170-L174' class='documenter-source'>source</a><br>

<a id='Validation.errors_messages_for' href='#Validation.errors_messages_for'>#</a>
**`Validation.errors_messages_for`** &mdash; *Function*.



```
errors_messages_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{AbstractString}
```

Vector of error messages corresponding to the validation errors of `m.field`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L185-L189' class='documenter-source'>source</a><br>

<a id='Validation.errors_to_string' href='#Validation.errors_to_string'>#</a>
**`Validation.errors_to_string`** &mdash; *Function*.



```
errors_to_string{T<:AbstractModel}(m::T, field::Symbol, separator = "
```

"; upper_case_first = false) :: String

Concatenates the validation errors of `m.field` into a single string – meant to be displayed easily to end users.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/Validation.jl#L200-L205' class='documenter-source'>source</a><br>

