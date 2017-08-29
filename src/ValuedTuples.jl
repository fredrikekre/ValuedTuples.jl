module ValuedTuples

import MacroTools

include("tuple_algebra.jl")

export ValuedTuple
"""
```jldoctest
julia> using ValuedTuples

julia> ValuedTuple((1, 2, 3), @values a b c)
(@VT a = 1 b = 2 c = 3)

julia> ValuedTuple((1, 2, 3), @values a)
ERROR: Tuple size mismatch: leftovers (2, 3)
[...]

julia> ValuedTuple((1,), @values a b c)
ERROR: Tuple size mismatch: leftovers (Val{:b}(), Val{:c}())
[...]

julia> ValuedTuple((1, 2), (3, 4))
ERROR: All names must be Vals
[...]
```
"""
struct ValuedTuple{T <: Tuple, N <: Tuple}
    tuple::T
    names::N
    ValuedTuple{T, N}(t, n) where {T, N} = begin
        same_length(t, n)
        if inner_value(all_tuple(is_value.(n)))
            new(t, n)
        else
            error("All names must be Vals")
        end
    end
end

ValuedTuple(t::T, n::N) where {T <: Tuple, N <: Tuple} = ValuedTuple{T, N}(t, n)

Base.show(io::IO, v::ValuedTuple) =
    print(io, string("(@VT ", join([map(v.names, v.tuple) do name, item
        "$(inner_value(name)) = $(repr(item))"
    end...], " "), ")"))

decompose_assignment(e) =
    MacroTools.@match e begin
        ( key_ = value_ ) => (key, value)
        s_Symbol => (s, s)
        any_ => error("Unable to decompose assignment $any")
    end

export @VT
"""
    @VT args...

Make a `ValuedTuple`. A valued tuple can be indexed only with `Val`s (create
with [`@value`](@ref)). Valued tuples can be manipulated in a type-stable way
because the names are directly encoded into the type. You can use repeated
values. getindex will error when trying to index at a repeated value; use
[`match_index`](@ref) instead.

```jldoctest
julia> using ValuedTuples

julia> b = 2;

julia> v = @VT a = 1 b a = 3
(@VT a = 1 b = 2 a = 3)

julia> v[@value b]
2

julia> v[@value d]
ERROR: No matches found for Val{:d}()
[...]

julia> v[@value a]
ERROR: Multiple matches found for Val{:a}()
[...]

julia> @VT x * y
ERROR: Unable to decompose assignment x * y
[...]
```
"""
macro VT(args...)
    decomposed = decompose_assignment.(args)
    Expr(:call, ValuedTuple,
        Expr(:tuple, map(decomposed) do pair
            pair[2]
        end...),
        map(decomposed) do pair
            Val{pair[1]}()
        end
    ) |> esc
end

export match_index
"""
    match_index(v::ValuedTuple, value)

```jldoctest
julia> using ValuedTuples

julia> v = @VT a = 1 b = 2 a = 3
(@VT a = 1 b = 2 a = 3)

julia> match_index(v, @value a)
(1, 3)
```
"""
match_index(v::ValuedTuple, value) =
    get_index(
        v.tuple,
        map(v.names) do name
            same_type(name, value)
        end)

Base.getindex(v::ValuedTuple, value) =
    drop_tuple(match_index(v, value), value)

"""
    Base.merge(v1::ValuedTuple, v2::ValuedTuple)

```jldoctest
julia> using ValuedTuples

julia> merge((@VT a = 1 b = "b"), (@VT c = 3 d = "d"))
(@VT a = 1 b = "b" c = 3 d = "d")
```
"""
Base.merge(v1::ValuedTuple, v2::ValuedTuple) =
    ValuedTuple((v1.tuple..., v2.tuple...), (v1.names..., v2.names...))

export delete
"""
    delete(v::ValuedTuple, value)

```jldoctest
julia> using ValuedTuples

julia> delete((@VT a = 1 b = 2), @value a)
(@VT b = 2)
```
"""
delete(v::ValuedTuple, value) = begin
    names = v.names
    keeps = map(names) do name
        not(same_type(name, value))
    end
    ValuedTuple(get_index(v.tuple, keeps), get_index(names, keeps))
end

end
