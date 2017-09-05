import Base.tail

export @value
"""
```jdoctest
julia> using ValuedTuples

julia> @value a
Val{:a}()
```
"""
macro value(e)
    Val{e}()
end

export @values
"""
```jdoctest
julia> using ValuedTuples

julia> @values a b
(Val{:a}(), Val{:b}())
```
"""
macro values(es...)
    map(es) do e
        Val{e}()
    end
end

macro as_value(e)
    esc(:($Val{$e}()))
end

inner_value(::Type{Val{T}}) where T = T
inner_value(::Val{T}) where T = T

is_value(v::Val{T}) where T = Val{true}()
is_value(any) = Val{false}()

same_type(a, b) = Val{false}()
same_type(a::T, b::T) where T = Val{true}()

same_length(v1::Tuple{}, v2::Tuple{}) = Val{true}()
same_length(v1, v2::Tuple{}) = error("Tuple size mismatch: leftovers $v1")
same_length(v1::Tuple{}, v2) = error("Tuple size mismatch: leftovers $v2")
same_length(v1, v2) = same_length(tail(v1), tail(v2))

reduce_tuple(f, default, args) = f(first(args), reduce_tuple(f, default, tail(args)))
reduce_tuple(f, default, args::Tuple{}) = default

and(v1::Val{true}, v2::Val{true}) = Val{true}()
and(v1, v2) = Val{false}()

all_tuple(args) = reduce_tuple(and, (@value true), args)

not(::Val{false}) = Val{true}()
not(::Val{true}) = Val{false}()

if_else(switch::Val{false}, new, old) = old
if_else(switch::Val{true}, new, old) = new

get_index(into::Tuple{}, index::Tuple{}) = ()
@inline get_index(into, index) = begin
    same_length(into, index)
    next = get_index(tail(into), tail(index))
    if_else(first(index), (first(into), next...), next)
end

value_wrap(f) = (x, args...) -> @as_value f(inner_value(x), args...)

inner_types(any) = inner_types(@as_value any)
function inner_types(val_type::Val)
    Base.@pure inner_function(i) = value_wrap(fieldtype)(val_type, i)
    ntuple(inner_function, value_wrap(nfields)(val_type))
end
